from decimal import Decimal, InvalidOperation
import json
import logging
import re

from cloudinary.exceptions import Error as CloudinaryError
from django.db import transaction
from django.core.exceptions import ImproperlyConfigured
from django.db.models import Q, Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response
from PIL import Image, UnidentifiedImageError

from hrms.models import AppNotification, User
from hrms.push_notifications import send_mobile_push
from hrms.views import _passport_photo_for_email
from .models import ClientVisit, VisitAttachment, VisitExpense
from .storage import upload_client_visit_file


SUPERVISOR_ROLES = {'manager', 'tl', 'hr', 'admin', 'superadmin'}
DAILY_VISIT_LIMIT = 5   # maximum visits any employee may schedule on a single date
logger = logging.getLogger(__name__)
EDITABLE_FIELDS = (
    'client_name', 'contact_person', 'contact_phone', 'address', 'latitude',
    'longitude', 'scheduled_date', 'scheduled_time', 'duration_minutes',
    'travel_mode', 'purpose', 'notes', 'manager_user_id',
)


def _actor(request):
    user_id = str(request.data.get('user_id') or request.query_params.get('user_id') or '').strip()
    user = User.objects.filter(user_id=user_id, is_active=True).first()
    return user_id, user


def _error(message, status=400):
    return Response({'success': False, 'message': message}, status=status)


def _is_camera_image(upload):
    """Accept declared images and verify Android cache files with no MIME type."""
    content_type = str(getattr(upload, 'content_type', '') or '').lower()
    if content_type.startswith('image/'):
        return True
    original_position = upload.tell()
    try:
        Image.open(upload).verify()
        return True
    except (UnidentifiedImageError, OSError, ValueError):
        return False
    finally:
        upload.seek(original_position)


def _notify(*, user_id='', role='', title, message, notification_type='info', visit):
    notification = AppNotification.objects.create(
        recipient_user_id=user_id,
        recipient_role=role,
        title=title,
        message=message,
        notification_type=notification_type,
        module='client_visit',
        reference_id=str(visit.id),
    )
    try:
        notification.push_sent = send_mobile_push(notification)
        if notification.push_sent:
            notification.save(update_fields=['push_sent'])
    except Exception:
        # The in-app notification is authoritative. A provider/network failure
        # must not discard it or interrupt the approval response.
        logger.exception(
            'Unable to send Client Visit push notification %s',
            notification.pk,
        )
    return notification


def _notify_visit_submitted(visit):
    message = (
        f'{visit.employee_name} submitted {visit.visit_id} for '
        f'{visit.client_name} on {visit.scheduled_date}.'
    )
    if visit.manager_user_id:
        _notify(
            user_id=visit.manager_user_id,
            title='Client Visit Approval Required',
            message=message,
            notification_type='warning',
            visit=visit,
        )
    else:
        _notify(
            role='tl',
            title='Client Visit Approval Required',
            message=message,
            notification_type='warning',
            visit=visit,
        )
    assigned_role = ''
    if visit.manager_user_id:
        assigned_role = (
            User.objects.filter(user_id=visit.manager_user_id, is_active=True)
            .values_list('role', flat=True)
            .first()
            or ''
        )

    # Keep the requester informed in the Employee/TL/HR dashboard while the
    # selected reporting approver receives the actionable alert above.
    _notify(
        user_id=visit.employee_user_id,
        title='Client Visit Request Submitted',
        message=f'{visit.visit_id} was submitted and is waiting for approval.',
        notification_type='info',
        visit=visit,
    )

    # Leadership dashboards monitor every raised request. The assigned CEO is
    # excluded from the CEO broadcast to avoid showing the same request twice.
    for dashboard_role in ('ceo', 'md', 'director', 'admin'):
        if dashboard_role == assigned_role:
            continue
        _notify(
            role=dashboard_role,
            title='New Client Visit Request',
            message=message,
            notification_type='info',
            visit=visit,
        )


def _safe_notify_visit_submitted(visit):
    try:
        _notify_visit_submitted(visit)
    except Exception:
        # A notification provider/schema issue must never turn a successfully
        # saved visit into an HTML 500 response or encourage duplicate retries.
        logger.exception('Unable to send submitted Client Visit notifications for %s', visit.pk)


def _resolve_reporting_manager(value, *, requester=None):
    raw = str(value or '').strip()
    if not raw:
        return None, ''
    if requester and requester.role == 'tl':
        approver_roles = {'hr'}
    elif requester and requester.role == 'hr':
        approver_roles = {'ceo'}
    else:
        approver_roles = {'manager', 'tl', 'hr'}
    supervisors = User.objects.filter(
        role__in=approver_roles,
        is_active=True,
    )
    direct = supervisors.filter(
        Q(user_id__iexact=raw) | Q(email__iexact=raw)
    ).first()
    if direct:
        return direct, ''

    normalized = ' '.join(raw.casefold().split())
    name_matches = [
        user for user in supervisors.only('user_id', 'first_name', 'last_name')
        if ' '.join(f'{user.first_name} {user.last_name}'.casefold().split()) == normalized
        or user.first_name.strip().casefold() == normalized
    ]
    if len(name_matches) == 1:
        return name_matches[0], ''
    if len(name_matches) > 1:
        return None, 'More than one approver has this name. Select the approver user ID.'
    if requester and requester.role == 'tl':
        return None, 'HR approver was not found. Select a valid HR approver.'
    if requester and requester.role == 'hr':
        return None, 'CEO approver was not found. Select a valid CEO approver.'
    return None, 'TL/HR approver was not found. Select a valid approver.'


def _normalize_contact_phone(value):
    raw = str(value or '').strip()
    digits = re.sub(r'\D', '', raw)
    if len(digits) == 12 and digits.startswith('91'):
        digits = digits[2:]
    if not re.fullmatch(r'[6-9]\d{9}', digits):
        return '', 'Enter a valid 10-digit mobile number starting with 6, 7, 8, or 9.'
    return digits, ''


@api_view(['GET'])
def visit_approvers(request):
    _, user = _actor(request)
    if not user:
        return _error('An active user_id is required.', 401)
    approvers = []
    role_order = {'tl': 0, 'hr': 1, 'ceo': 2}
    if user.role == 'tl':
        approver_roles = {'hr'}
    elif user.role == 'hr':
        approver_roles = {'ceo'}
    else:
        approver_roles = {'tl', 'hr'}
    queryset = User.objects.filter(
        role__in=approver_roles,
        is_active=True,
    ).order_by('role', 'first_name', 'last_name', 'user_id')
    for approver in queryset:
        name = f'{approver.first_name} {approver.last_name}'.strip()
        approvers.append({
            'employee_id': approver.user_id,
            'label': name or approver.email,
            'role': approver.role,
            'role_label': {
                'tl': 'Team Lead',
                'hr': 'HR',
                'ceo': 'CEO',
            }[approver.role],
        })
    approvers.sort(key=lambda item: (role_order[item['role']], item['label'].casefold()))
    return Response({'success': True, 'approvers': approvers})


def _notify_visit_progress(visit, *, title, message, notification_type='info', include_employee=False):
    # Notify the requester first. Approval observers must never delay or block
    # the employee/TL/HR who raised the visit from receiving the outcome.
    if include_employee:
        _notify(
            user_id=visit.employee_user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            visit=visit,
        )
    assigned_role = ''
    if visit.manager_user_id:
        assigned_role = (
            User.objects.filter(user_id=visit.manager_user_id, is_active=True)
            .values_list('role', flat=True)
            .first()
            or ''
        )
        _notify(
            user_id=visit.manager_user_id,
            title=title,
            message=message,
            notification_type=notification_type,
            visit=visit,
        )
    else:
        _notify(
            role='tl',
            title=title,
            message=message,
            notification_type=notification_type,
            visit=visit,
        )
    for dashboard_role in ('ceo', 'md', 'director', 'admin'):
        if dashboard_role == assigned_role:
            continue
        _notify(
            role=dashboard_role,
            title=title,
            message=message,
            notification_type=notification_type,
            visit=visit,
        )


def _can_view(visit, user_id, user):
    if visit.employee_user_id == user_id or visit.manager_user_id == user_id:
        return True
    return bool(user and user.role in {'hr', 'admin', 'superadmin', 'ceo', 'md', 'director'})


def _attachment_payload(item):
    return {
        'id': item.id, 'category': item.category, 'url': item.cloudinary_url,
        'public_id': item.cloudinary_public_id, 'resource_type': item.resource_type,
        'cloud_name': item.cloudinary_cloud_name, 'storage_provider': item.storage_provider,
        'original_name': item.original_name, 'created_at': item.created_at.isoformat(),
    }


def _visit_payload(item, detailed=True, approver_lookup=None):
    approver = None
    if item.approved_by and approver_lookup is not None:
        approver = approver_lookup.get(item.approved_by)
    elif detailed and item.approved_by:
        approver = User.objects.filter(
            user_id=item.approved_by,
            is_active=True,
        ).only('role', 'first_name', 'last_name', 'email').first()
    approver_name = ''
    approver_role = ''
    if approver:
        approver_name = f'{approver.first_name} {approver.last_name}'.strip() or approver.email
        approver_role = approver.role
    # Resolve employee profile photo (best-effort, fails silently)
    try:
        emp_user = User.objects.filter(user_id=item.employee_user_id, is_active=True).only('email').first()
        employee_photo_url = _passport_photo_for_email(emp_user.email) if emp_user else ''
    except Exception:
        employee_photo_url = ''
    payload = {
        'id': item.id, 'visit_id': item.visit_id, 'employee_user_id': item.employee_user_id,
        'employee_name': item.employee_name, 'employee_photo_url': employee_photo_url,
        'manager_user_id': item.manager_user_id,
        'client_name': item.client_name, 'contact_person': item.contact_person,
        'contact_phone': item.contact_phone, 'address': item.address,
        'latitude': float(item.latitude) if item.latitude is not None else None,
        'longitude': float(item.longitude) if item.longitude is not None else None,
        'scheduled_date': item.scheduled_date.isoformat() if hasattr(item.scheduled_date, 'isoformat') else str(item.scheduled_date),
        'scheduled_time': item.scheduled_time.strftime('%H:%M') if hasattr(item.scheduled_time, 'strftime') else str(item.scheduled_time)[:5],
        'duration_minutes': item.duration_minutes, 'travel_mode': item.travel_mode,
        'purpose': item.purpose, 'notes': item.notes, 'status': item.status,
        'approval_comment': item.approval_comment, 'approved_by': item.approved_by,
        'approved_by_name': approver_name, 'approved_by_role': approver_role,
        'approved_at': item.approved_at.isoformat() if item.approved_at else None,
        'office_check_out_at': item.office_check_out_at.isoformat() if item.office_check_out_at else None,
        'office_check_out_latitude': float(item.office_check_out_latitude) if item.office_check_out_latitude is not None else None,
        'office_check_out_longitude': float(item.office_check_out_longitude) if item.office_check_out_longitude is not None else None,
        'reached_client_at': item.reached_client_at.isoformat() if item.reached_client_at else None,
        'reached_client_latitude': float(item.reached_client_latitude) if item.reached_client_latitude is not None else None,
        'reached_client_longitude': float(item.reached_client_longitude) if item.reached_client_longitude is not None else None,
        'travel_route': item.travel_route,
        'start_odometer': float(item.start_odometer) if item.start_odometer is not None else None,
        'check_in_at': item.check_in_at.isoformat() if item.check_in_at else None,
        'check_out_at': item.check_out_at.isoformat() if item.check_out_at else None,
        'outcome': item.outcome, 'follow_up': item.follow_up,
        'attendees': item.attendees, 'checklist': item.checklist,
        'return_mode': item.return_mode,
        'manager_verified_by': item.manager_verified_by,
        'manager_verified_at': item.manager_verified_at.isoformat() if item.manager_verified_at else None,
        'expense_total': float(item.expenses.aggregate(total=Sum('amount'))['total'] or 0),
        'created_at': item.created_at.isoformat(), 'updated_at': item.updated_at.isoformat(),
    }
    if detailed:
        payload['attachments'] = [_attachment_payload(value) for value in item.attachments.all()]
        payload['expenses'] = [
            {'id': value.id, 'category': value.category, 'amount': float(value.amount), 'note': value.note}
            for value in item.expenses.all()
        ]
    return payload


def _assign_fields(visit, data):
    for field in EDITABLE_FIELDS:
        if field in data and data.get(field) not in (None, ''):
            value = data.get(field)
            # Reject 0,0 coordinates — sentinel from unresolved short URLs
            if field in ('latitude', 'longitude'):
                try:
                    fval = float(value)
                    if fval == 0.0:
                        continue
                except (TypeError, ValueError):
                    continue
            setattr(visit, field, value)


@api_view(['GET', 'POST'])
@parser_classes([JSONParser, FormParser, MultiPartParser])
def visit_list_create(request):
    user_id, user = _actor(request)
    if not user:
        return _error('An active user_id is required.', 401)
    if request.method == 'GET':
        queryset = ClientVisit.objects.prefetch_related('attachments', 'expenses')
        if user.role in {'hr', 'admin', 'superadmin', 'ceo', 'md', 'director'}:
            employee = request.query_params.get('employee_user_id')
            if employee:
                queryset = queryset.filter(employee_user_id=employee)
        elif user.role in {'manager', 'tl'}:
            queryset = queryset.filter(
                Q(manager_user_id=user_id) | Q(employee_user_id=user_id)
            )
        else:
            queryset = queryset.filter(employee_user_id=user_id)
        status_filter = str(request.query_params.get('status') or '').strip()
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        items = list(queryset[:100])
        approver_ids = {item.approved_by for item in items if item.approved_by}
        approver_lookup = {
            value.user_id: value
            for value in User.objects.filter(
                user_id__in=approver_ids,
                is_active=True,
            ).only('user_id', 'role', 'first_name', 'last_name', 'email')
        }
        counts = {key: 0 for key, _ in ClientVisit.STATUS_CHOICES}
        for value in queryset.values_list('status', flat=True):
            counts[value] = counts.get(value, 0) + 1
        return Response({
            'success': True,
            'summary': counts,
            'visits': [
                _visit_payload(item, False, approver_lookup)
                for item in items
            ],
        })

    required = ('client_name', 'contact_person', 'contact_phone', 'address', 'scheduled_date', 'scheduled_time', 'purpose')
    missing = [field for field in required if not str(request.data.get(field) or '').strip()]
    if missing:
        return _error(f"Required fields: {', '.join(missing)}.")
    contact_phone, phone_error = _normalize_contact_phone(
        request.data.get('contact_phone')
    )
    if phone_error:
        return _error(phone_error)
    reporting_manager, manager_error = _resolve_reporting_manager(
        request.data.get('manager_user_id'),
        requester=user,
    )
    if manager_error:
        return _error(manager_error)
    visit = ClientVisit(
        employee_user_id=user_id,
        employee_name=f'{user.first_name} {user.last_name}'.strip() or user.email,
    )
    _assign_fields(visit, request.data)
    visit.contact_phone = contact_phone
    if reporting_manager:
        visit.manager_user_id = reporting_manager.user_id
    visit.status = 'pending' if str(request.data.get('submit') or '').lower() in {'1', 'true', 'yes'} else 'draft'

    # Enforce the daily visit limit — count all non-rejected visits for this
    # employee on the requested date.
    scheduled_date = visit.scheduled_date
    if scheduled_date:
        existing_count = ClientVisit.objects.filter(
            employee_user_id=user_id,
            scheduled_date=scheduled_date,
        ).exclude(status='rejected').count()
        if existing_count >= DAILY_VISIT_LIMIT:
            return _error(
                f'Daily visit limit reached. You can schedule a maximum of '
                f'{DAILY_VISIT_LIMIT} visits per day. '
                f'You already have {existing_count} visit(s) on {scheduled_date}.',
                400,
            )

    try:
        visit.save()
    except (ValueError, TypeError) as exc:
        return _error(f'Invalid visit data: {exc}')
    if visit.status == 'pending':
        _safe_notify_visit_submitted(visit)
    return Response({'success': True, 'message': 'Visit request created.', 'visit': _visit_payload(visit)}, status=201)


@api_view(['GET', 'PATCH'])
@parser_classes([JSONParser, FormParser, MultiPartParser])
def visit_detail(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit.objects.prefetch_related('attachments', 'expenses'), pk=pk)
    if not user or not _can_view(visit, user_id, user):
        return _error('You cannot access this visit.', 403)
    if request.method == 'GET':
        return Response({'success': True, 'visit': _visit_payload(visit)})
    if visit.employee_user_id != user_id or visit.status not in {'draft', 'rejected'}:
        return _error('Only the employee can edit a draft or rejected visit.', 409)
    contact_phone = None
    if 'contact_phone' in request.data:
        contact_phone, phone_error = _normalize_contact_phone(
            request.data.get('contact_phone')
        )
        if phone_error:
            return _error(phone_error)
    reporting_manager = None
    if 'manager_user_id' in request.data:
        reporting_manager, manager_error = _resolve_reporting_manager(
            request.data.get('manager_user_id'),
            requester=user,
        )
        if manager_error:
            return _error(manager_error)
    _assign_fields(visit, request.data)
    if contact_phone:
        visit.contact_phone = contact_phone
    if reporting_manager:
        visit.manager_user_id = reporting_manager.user_id
    submitted = str(request.data.get('submit') or '').lower() in {'1', 'true', 'yes'}
    if submitted:
        visit.status = 'pending'
        visit.approval_comment = ''
    try:
        visit.save()
    except (ValueError, TypeError) as exc:
        return _error(f'Invalid visit data: {exc}')
    if submitted:
        _safe_notify_visit_submitted(visit)
    return Response({'success': True, 'message': 'Visit updated.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_approval(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    approval_roles = SUPERVISOR_ROLES | {'ceo'}
    if not user or user.role not in approval_roles:
        return _error('Manager, TL, HR, CEO or Admin access is required.', 403)
    requester = User.objects.filter(user_id=visit.employee_user_id).only('role').first()
    requester_role = requester.role if requester else ''
    required_approver_role = {'tl': 'hr', 'hr': 'ceo'}.get(requester_role)
    if required_approver_role and (
        user.role != required_approver_role or visit.manager_user_id != user_id
    ):
        return _error(
            f'{required_approver_role.upper()} approval is required for this visit.',
            403,
        )
    if not required_approver_role and user.role == 'ceo':
        return _error('CEO approval applies only to HR client visits.', 403)
    if not required_approver_role and user.role in {'manager', 'tl'} and visit.manager_user_id != user_id:
        return _error('This visit is not assigned to you.', 403)
    if visit.status != 'pending':
        return _error('Only pending visits can be reviewed.', 409)
    action = str(request.data.get('action') or '').lower()
    if action not in {'approve', 'reject', 'changes'}:
        return _error('Action must be approve, reject, or changes.')
    visit.status = 'approved' if action == 'approve' else 'rejected'
    visit.approval_comment = str(request.data.get('comment') or '').strip()
    visit.approved_by = user_id
    visit.approved_at = timezone.now()
    visit.save()
    actor_label = {
        'hr': 'HR', 'ceo': 'CEO', 'tl': 'TL', 'manager': 'Manager',
        'admin': 'Admin', 'superadmin': 'Super Admin',
    }.get(user.role, user.role.upper())
    message = 'Visit approved.' if action == 'approve' else 'Visit returned for changes.'
    notification_message = (
        f'Visit approved by {actor_label}.'
        if action == 'approve'
        else f'Visit returned for changes by {actor_label}.'
    )
    _notify_visit_progress(
        visit,
        title=(
            f'{actor_label} Approved Client Visit'
            if action == 'approve'
            else f'{actor_label} Requested Client Visit Changes'
        ),
        message=f'{visit.visit_id} for {visit.client_name}: {notification_message} {visit.approval_comment}'.strip(),
        notification_type='success' if action == 'approve' else 'warning',
        include_employee=True,
    )
    return Response({'success': True, 'message': message, 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_check_in(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can check in.', 403)
    if visit.status not in {'approved', 'travelling'}:
        return _error('The visit must be approved and active before check-in.', 409)
    visit.status = 'in_progress'
    visit.check_in_at = timezone.now()
    visit.check_in_latitude = request.data.get('latitude') or None
    visit.check_in_longitude = request.data.get('longitude') or None
    visit.save()
    _notify_visit_progress(
        visit,
        title='Client Visit Started',
        message=f'{visit.employee_name} checked in for {visit.visit_id} at {visit.client_name}.',
        notification_type='info',
    )
    return Response({'success': True, 'message': 'Client check-in recorded.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_start_travel(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can start travel.', 403)
    if visit.status != 'approved':
        return _error('The visit must be approved before office check-out.', 409)
    visit.status = 'travelling'
    visit.office_check_out_at = timezone.now()
    visit.office_check_out_latitude = request.data.get('latitude') or None
    visit.office_check_out_longitude = request.data.get('longitude') or None
    if visit.office_check_out_latitude is not None and visit.office_check_out_longitude is not None:
        visit.travel_route = [{
            'latitude': round(float(visit.office_check_out_latitude), 7),
            'longitude': round(float(visit.office_check_out_longitude), 7),
            'accuracy': round(float(request.data.get('accuracy') or 0), 2),
            'speed': 0,
            'recorded_at': timezone.now().isoformat(),
        }]
    visit.start_odometer = request.data.get('odometer') or None
    visit.save()
    _notify_visit_progress(
        visit, title='Employee Travelling to Client',
        message=f'{visit.employee_name} started travel for {visit.visit_id} to {visit.client_name}.',
    )
    return Response({'success': True, 'message': 'Office check-out recorded.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_reached_client(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can record arrival.', 403)
    if visit.status != 'travelling':
        return _error('Travel must be active before recording arrival.', 409)
    visit.reached_client_at = timezone.now()
    visit.reached_client_latitude = request.data.get('latitude') or None
    visit.reached_client_longitude = request.data.get('longitude') or None
    visit.save(update_fields=[
        'reached_client_at', 'reached_client_latitude',
        'reached_client_longitude', 'updated_at',
    ])
    return Response({'success': True, 'message': 'Client arrival recorded.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_location(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can update travel location.', 403)
    if visit.status != 'travelling':
        return _error('Travel must be active to track location.', 409)
    try:
        latitude = float(request.data.get('latitude'))
        longitude = float(request.data.get('longitude'))
        accuracy = float(request.data.get('accuracy') or 0)
        speed = float(request.data.get('speed') or 0)
    except (TypeError, ValueError):
        return _error('Valid GPS location values are required.')
    if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
        return _error('Latitude or longitude is outside the valid range.')
    point = {
        'latitude': round(latitude, 7),
        'longitude': round(longitude, 7),
        'accuracy': round(accuracy, 2),
        'speed': round(speed, 2),
        'recorded_at': timezone.now().isoformat(),
    }
    route = list(visit.travel_route or [])
    route.append(point)
    # Bound payload growth while retaining a detailed route for the visit report.
    visit.travel_route = route[-2000:]
    visit.save(update_fields=['travel_route', 'updated_at'])
    return Response({
        'success': True,
        'message': 'Travel location recorded.',
        'point': point,
        'route_points': len(visit.travel_route),
    })


@api_view(['POST'])
def visit_progress(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can update the visit.', 403)
    if visit.status != 'in_progress':
        return _error('An active client visit is required.', 409)
    for field in ('attendees', 'checklist'):
        if field in request.data:
            value = request.data.get(field)
            if isinstance(value, str):
                try:
                    value = json.loads(value)
                except ValueError:
                    return _error(f'{field.title()} must be a list.')
            if not isinstance(value, list):
                return _error(f'{field.title()} must be a list.')
            setattr(visit, field, value)
    if 'notes' in request.data:
        visit.notes = str(request.data.get('notes') or '').strip()
    visit.save()
    return Response({'success': True, 'message': 'Visit progress updated.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_complete(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can complete this visit.', 403)
    if visit.status != 'in_progress':
        return _error('An active visit is required.', 409)
    outcome = str(request.data.get('outcome') or '').strip()
    if not outcome:
        return _error('Visit outcome is required.')
    visit.status = 'completed'
    visit.check_out_at = timezone.now()
    visit.check_out_latitude = request.data.get('latitude') or None
    visit.check_out_longitude = request.data.get('longitude') or None
    visit.outcome = outcome
    visit.follow_up = str(request.data.get('follow_up') or '').strip()
    visit.return_mode = str(request.data.get('return_mode') or 'return_office').strip()
    visit.client_signature_name = str(request.data.get('client_signature_name') or '').strip()
    visit.save()
    _notify_visit_progress(
        visit,
        title='Client Visit Completed',
        message=f'{visit.visit_id} at {visit.client_name} was completed. Outcome: {visit.outcome}',
        notification_type='success',
    )
    return Response({'success': True, 'message': 'Visit completed.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_verify(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or user.role not in SUPERVISOR_ROLES:
        return _error('TL, Manager, HR or Admin access is required.', 403)
    if user.role in {'manager', 'tl'} and visit.manager_user_id != user_id:
        return _error('This visit is not assigned to you.', 403)
    if visit.status != 'completed':
        return _error('Only completed visits can be verified.', 409)
    visit.manager_verified_by = user_id
    visit.manager_verified_at = timezone.now()
    visit.save(update_fields=['manager_verified_by', 'manager_verified_at', 'updated_at'])
    _notify(
        user_id=visit.employee_user_id, title='Client Visit Verified',
        message=f'{visit.visit_id} was verified by your reporting TL.',
        notification_type='success', visit=visit,
    )
    return Response({'success': True, 'message': 'Visit verified.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
@parser_classes([MultiPartParser, FormParser])
def visit_attachment(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or not _can_view(visit, user_id, user):
        return _error('You cannot upload to this visit.', 403)
    category = str(request.data.get('category') or 'proof').strip().lower()
    allowed = {key for key, _ in VisitAttachment.CATEGORY_CHOICES}
    if category not in allowed:
        return _error('Invalid attachment category.')
    uploads = request.FILES.getlist('files') or request.FILES.getlist('file')
    if not uploads:
        return _error('At least one file is required.')
    selfie_categories = {
        'check_in', 'office_checkout', 'client_check_in', 'checkout',
    }
    for upload in uploads:
        if upload.size <= 0:
            return _error('The selected attachment is empty.')
        if upload.size > 10 * 1024 * 1024:
            return _error('Each Client Visit attachment must be 10 MB or smaller.', 413)
        if category in selfie_categories and not _is_camera_image(upload):
            return _error('A valid camera image is required for this selfie.')
    created = []
    # Each category receives its own Cloudinary folder, keeping visit media separate.
    try:
        with transaction.atomic():
            for upload in uploads:
                result, cloud_name, _ = upload_client_visit_file(
                    upload, visit_id=visit.visit_id, category=category,
                )
                item = VisitAttachment.objects.create(
                    visit=visit, category=category, cloudinary_url=result['secure_url'],
                    cloudinary_public_id=result['public_id'], resource_type=result.get('resource_type', 'image'),
                    cloudinary_cloud_name=cloud_name,
                    original_name=upload.name, uploaded_by=user_id,
                )
                created.append(item)
    except ImproperlyConfigured as exc:
        return _error(str(exc), 503)
    except CloudinaryError as exc:
        logger.exception(
            'Client Visit Cloudinary rejected %s upload for %s',
            category,
            visit.visit_id,
        )
        reason = str(exc).lower()
        if any(value in reason for value in ('api key', 'signature', 'auth')):
            return _error(
                'Client Visit Cloudinary credentials were rejected. '
                'Update the Render API key and secret, then redeploy.',
                503,
            )
        if 'file size' in reason or 'too large' in reason:
            return _error('The selfie is too large for Cloudinary.', 413)
        if 'invalid image' in reason or 'unsupported' in reason:
            return _error('Cloudinary could not read this camera image. Retake the selfie.', 400)
        return _error(
            'Cloudinary rejected the selfie upload. Retake the image and retry.',
            502,
        )
    except Exception:
        logger.exception(
            'Unexpected Client Visit upload failure for %s',
            visit.visit_id,
        )
        return _error(
            'The Client Visit server could not upload the selfie. Please retry.',
            502,
        )
    return Response({'success': True, 'message': f'{len(created)} file(s) uploaded.', 'attachments': [_attachment_payload(item) for item in created]}, status=201)


@api_view(['POST'])
def visit_expense(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can add expenses.', 403)
    category = str(request.data.get('category') or '').lower()
    if category not in {key for key, _ in VisitExpense.CATEGORY_CHOICES}:
        return _error('Invalid expense category.')
    try:
        amount = Decimal(str(request.data.get('amount') or '0'))
    except InvalidOperation:
        return _error('Enter a valid expense amount.')
    if amount <= 0:
        return _error('Expense amount must be greater than zero.')
    expense = VisitExpense.objects.create(visit=visit, category=category, amount=amount, note=str(request.data.get('note') or '').strip())
    return Response({'success': True, 'message': 'Expense added.', 'expense': {'id': expense.id, 'category': expense.category, 'amount': float(expense.amount), 'note': expense.note}}, status=201)
