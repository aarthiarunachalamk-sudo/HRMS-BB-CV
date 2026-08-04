from decimal import Decimal, InvalidOperation

import cloudinary.uploader
from django.db import transaction
from django.db.models import Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.response import Response

from hrms.models import User
from .models import ClientVisit, VisitAttachment, VisitExpense


SUPERVISOR_ROLES = {'manager', 'tl', 'hr', 'admin', 'superadmin'}
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


def _can_view(visit, user_id, user):
    if visit.employee_user_id == user_id or visit.manager_user_id == user_id:
        return True
    return bool(user and user.role in {'hr', 'admin', 'superadmin'})


def _attachment_payload(item):
    return {
        'id': item.id, 'category': item.category, 'url': item.cloudinary_url,
        'public_id': item.cloudinary_public_id, 'resource_type': item.resource_type,
        'original_name': item.original_name, 'created_at': item.created_at.isoformat(),
    }


def _visit_payload(item, detailed=True):
    payload = {
        'id': item.id, 'visit_id': item.visit_id, 'employee_user_id': item.employee_user_id,
        'employee_name': item.employee_name, 'manager_user_id': item.manager_user_id,
        'client_name': item.client_name, 'contact_person': item.contact_person,
        'contact_phone': item.contact_phone, 'address': item.address,
        'latitude': float(item.latitude) if item.latitude is not None else None,
        'longitude': float(item.longitude) if item.longitude is not None else None,
        'scheduled_date': item.scheduled_date.isoformat() if hasattr(item.scheduled_date, 'isoformat') else str(item.scheduled_date),
        'scheduled_time': item.scheduled_time.strftime('%H:%M') if hasattr(item.scheduled_time, 'strftime') else str(item.scheduled_time)[:5],
        'duration_minutes': item.duration_minutes, 'travel_mode': item.travel_mode,
        'purpose': item.purpose, 'notes': item.notes, 'status': item.status,
        'approval_comment': item.approval_comment, 'approved_by': item.approved_by,
        'check_in_at': item.check_in_at.isoformat() if item.check_in_at else None,
        'check_out_at': item.check_out_at.isoformat() if item.check_out_at else None,
        'outcome': item.outcome, 'follow_up': item.follow_up,
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
            setattr(visit, field, data.get(field))


@api_view(['GET', 'POST'])
@parser_classes([JSONParser, FormParser, MultiPartParser])
def visit_list_create(request):
    user_id, user = _actor(request)
    if not user:
        return _error('An active user_id is required.', 401)
    if request.method == 'GET':
        queryset = ClientVisit.objects.prefetch_related('attachments', 'expenses')
        if user.role in {'hr', 'admin', 'superadmin'}:
            employee = request.query_params.get('employee_user_id')
            if employee:
                queryset = queryset.filter(employee_user_id=employee)
        elif user.role in {'manager', 'tl'}:
            queryset = queryset.filter(manager_user_id=user_id)
        else:
            queryset = queryset.filter(employee_user_id=user_id)
        status_filter = str(request.query_params.get('status') or '').strip()
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        items = list(queryset[:100])
        counts = {key: 0 for key, _ in ClientVisit.STATUS_CHOICES}
        for value in queryset.values_list('status', flat=True):
            counts[value] = counts.get(value, 0) + 1
        return Response({'success': True, 'summary': counts, 'visits': [_visit_payload(item, False) for item in items]})

    required = ('client_name', 'contact_person', 'address', 'scheduled_date', 'scheduled_time', 'purpose')
    missing = [field for field in required if not str(request.data.get(field) or '').strip()]
    if missing:
        return _error(f"Required fields: {', '.join(missing)}.")
    visit = ClientVisit(
        employee_user_id=user_id,
        employee_name=f'{user.first_name} {user.last_name}'.strip() or user.email,
    )
    _assign_fields(visit, request.data)
    visit.status = 'pending' if str(request.data.get('submit') or '').lower() in {'1', 'true', 'yes'} else 'draft'
    try:
        visit.save()
    except (ValueError, TypeError) as exc:
        return _error(f'Invalid visit data: {exc}')
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
    _assign_fields(visit, request.data)
    if str(request.data.get('submit') or '').lower() in {'1', 'true', 'yes'}:
        visit.status = 'pending'
        visit.approval_comment = ''
    try:
        visit.save()
    except (ValueError, TypeError) as exc:
        return _error(f'Invalid visit data: {exc}')
    return Response({'success': True, 'message': 'Visit updated.', 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_approval(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or user.role not in SUPERVISOR_ROLES:
        return _error('Manager, TL, HR or Admin access is required.', 403)
    if user.role in {'manager', 'tl'} and visit.manager_user_id != user_id:
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
    message = 'Visit approved.' if action == 'approve' else 'Visit returned for changes.'
    return Response({'success': True, 'message': message, 'visit': _visit_payload(visit)})


@api_view(['POST'])
def visit_check_in(request, pk):
    user_id, user = _actor(request)
    visit = get_object_or_404(ClientVisit, pk=pk)
    if not user or visit.employee_user_id != user_id:
        return _error('Only the assigned employee can check in.', 403)
    if visit.status != 'approved':
        return _error('The visit must be approved before check-in.', 409)
    visit.status = 'in_progress'
    visit.check_in_at = timezone.now()
    visit.check_in_latitude = request.data.get('latitude') or None
    visit.check_in_longitude = request.data.get('longitude') or None
    visit.save()
    return Response({'success': True, 'message': 'Client check-in recorded.', 'visit': _visit_payload(visit)})


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
    visit.client_signature_name = str(request.data.get('client_signature_name') or '').strip()
    visit.save()
    return Response({'success': True, 'message': 'Visit completed.', 'visit': _visit_payload(visit)})


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
    created = []
    # Each category receives its own Cloudinary folder, keeping visit media separate.
    folder = f'hrms/client_visits/{visit.visit_id}/{category}'
    try:
        with transaction.atomic():
            for upload in uploads:
                result = cloudinary.uploader.upload(upload, folder=folder, resource_type='auto', use_filename=True, unique_filename=True)
                item = VisitAttachment.objects.create(
                    visit=visit, category=category, cloudinary_url=result['secure_url'],
                    cloudinary_public_id=result['public_id'], resource_type=result.get('resource_type', 'image'),
                    original_name=upload.name, uploaded_by=user_id,
                )
                created.append(item)
    except Exception:
        return _error('Cloudinary upload failed. Check the Cloudinary configuration and retry.', 502)
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
