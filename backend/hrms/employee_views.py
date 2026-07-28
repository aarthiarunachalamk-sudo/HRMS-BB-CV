from datetime import date, datetime, timedelta, timezone as datetime_timezone
import json
from pathlib import Path

import cloudinary
from django.conf import settings
from django.db.models import Q
from django.utils import timezone
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status

from .models import (
    AppNotification,
    EmployeeAccount,
    EmployeeAttendanceRecord,
    EmployeeLeaveRequest,
    AttendanceRegularizationRequest,
    MdMeeting,
    EmployeeRegistration,
    TeamTask,
    User,
    EmployeeApprovalRequest,
)
from .payroll import latest_payslip_for_employee


def _approval_payload(item):
    stages = [
        {'stage': 1, 'label': 'Team Lead', 'roles': ['tl']},
        {'stage': 2, 'label': 'CEO Final Approval', 'roles': ['ceo']},
    ]
    attachment_url = ''
    if item.attachment:
        try:
            attachment_url = item.attachment.url
        except (ValueError, AttributeError):
            attachment_url = ''
    return {
        'id': item.id,
        'title': item.title,
        'request_type': item.request_type,
        'sender_role': item.sender_role,
        'department': item.department,
        'assigned_tl_user_id': item.assigned_tl_user_id,
        'date': str(item.request_date),
        'session': item.session,
        'task_details': item.task_details,
        'expected_result': item.expected_result,
        'actual_result': item.actual_result,
        'platforms': item.platforms,
        'posted_by': item.posted_by,
        'scheduled_post': item.scheduled_post,
        'leave_type': item.leave_type,
        'leave_end_date': str(item.leave_end_date) if item.leave_end_date else '',
        'attachment_name': item.attachment.name.rsplit('/', 1)[-1] if item.attachment else '',
        'attachment_url': attachment_url,
        'approvers': item.approvers,
        'decisions': item.decisions,
        'current_stage': item.current_stage,
        'approval_stages': stages,
        'status': item.status.title(),
        'created_at': timezone.localtime(item.created_at).isoformat(),
    }


@api_view(['GET', 'POST'])
def employee_approvals_view(request):
    user_id = str(request.query_params.get('user_id') or request.data.get('user_id') or '').strip()
    if not user_id:
        return Response({'success': False, 'message': 'Employee ID is required.'}, status=400)
    if request.method == 'GET':
        sent = EmployeeApprovalRequest.objects.filter(employee_id=user_id)[:100]
        user = User.objects.filter(user_id=user_id).first()
        role = user.role if user else 'employee'
        received = []
        if role in {'tl', 'ceo'}:
            stage = 0 if role == 'tl' else 1
            queryset = EmployeeApprovalRequest.objects.filter(status='requested', current_stage=stage)
            received = [item for item in queryset[:100] if not any(
                decision.get('role') == role for decision in (item.decisions or [])
            )]
        return Response({'success': True, 'received': [_approval_payload(item) for item in received], 'sent': [_approval_payload(item) for item in sent]})

    request_type = str(request.data.get('request_type') or 'daily_report').strip()
    if request_type not in {'daily_report', 'social_media_post', 'leave_request'}:
        return Response({'success': False, 'message': 'Unsupported approval request type.'}, status=400)
    if request_type == 'social_media_post':
        required = ['title', 'date', 'posted_by', 'scheduled_post']
    elif request_type == 'leave_request':
        required = ['title', 'date', 'leave_end_date', 'leave_type', 'task_details']
    else:
        required = ['title', 'date', 'session', 'task_details', 'expected_result', 'actual_result']
    missing = [key for key in required if not str(request.data.get(key) or '').strip()]
    if missing:
        return Response({'success': False, 'message': 'Complete all required fields.'}, status=400)
    platforms = request.data.get('platforms', [])
    if isinstance(platforms, str):
        try:
            platforms = json.loads(platforms)
        except json.JSONDecodeError:
            platforms = []
    if request_type == 'social_media_post':
        if not isinstance(platforms, list) or not any(str(value).strip() for value in platforms):
            return Response({'success': False, 'message': 'Select at least one social media platform.'}, status=400)
        if request.data.get('scheduled_post') not in {'Yes', 'No', 'Maybe'}:
            return Response({'success': False, 'message': 'Select whether this is a scheduled post.'}, status=400)
        if request.FILES.get('attachment') is None:
            return Response({'success': False, 'message': 'Attachment is required.'}, status=400)
    if request_type == 'leave_request' and request.FILES.get('attachment') is None:
        return Response({'success': False, 'message': 'Attachment is required.'}, status=400)
    try:
        request_date = date.fromisoformat(str(request.data['date']))
    except ValueError:
        return Response({'success': False, 'message': 'Select a valid date.'}, status=400)
    leave_end_date = None
    if request_type == 'leave_request':
        try:
            leave_end_date = date.fromisoformat(str(request.data['leave_end_date']))
        except ValueError:
            return Response({'success': False, 'message': 'Select a valid leave end date.'}, status=400)
        if leave_end_date < request_date:
            return Response({'success': False, 'message': 'Leave end date cannot be before start date.'}, status=400)
    sender = User.objects.filter(user_id=user_id).first()
    account = EmployeeAccount.objects.filter(employee_id=user_id).first()
    sender_role = sender.role if sender else 'employee'
    department = (account.department if account else '') or (sender.department if sender else '')
    assigned_tl = None
    reporting_tl = str(account.reporting_tl if account else '').strip()
    if reporting_tl:
        assigned_tl = User.objects.filter(role='tl', is_active=True).filter(
            Q(user_id__iexact=reporting_tl) |
            Q(email__iexact=reporting_tl) |
            Q(first_name__iexact=reporting_tl)
        ).first()
    if assigned_tl is None:
        tl_candidates = User.objects.filter(role='tl', is_active=True).exclude(user_id=user_id)
        if department:
            assigned_tl = tl_candidates.filter(department=department).first()
        if assigned_tl is None:
            assigned_tl = tl_candidates.first()
    if assigned_tl is None:
        return Response({'success': False, 'message': 'No Team Lead is configured for this department.'}, status=400)

    item = EmployeeApprovalRequest.objects.create(
        employee_id=user_id,
        sender_role=sender_role,
        department=department,
        assigned_tl_user_id=assigned_tl.user_id,
        request_type=request_type,
        title=str(request.data['title']).strip(),
        request_date=request_date,
        session=str(request.data.get('session') or 'Not applicable').strip(),
        task_details=str(request.data.get('task_details') or 'Social media post approval').strip(),
        expected_result=str(request.data.get('expected_result') or 'Approved content for selected platforms').strip(),
        actual_result=str(request.data.get('actual_result') or 'Pending approval').strip(),
        platforms=[str(value).strip() for value in platforms if str(value).strip()],
        posted_by=str(request.data.get('posted_by') or '').strip(),
        scheduled_post=str(request.data.get('scheduled_post') or '').strip(),
        leave_type=str(request.data.get('leave_type') or '').strip(),
        leave_end_date=leave_end_date,
        attachment=request.FILES.get('attachment'),
        approvers=['Team Lead', 'CEO'],
    )
    request_label = {
        'social_media_post': 'Social Media Post',
        'leave_request': 'Leave Request',
    }.get(request_type, 'Daily Report')
    _create_notification(
        role='tl',
        title=f'New {request_label} Approval',
        message=(
            f'{item.title} was sent for Team Lead approval. '
            'Any Team Lead can reply, approve, or reject.'
        ),
        notification_type='info',
        module='approval',
        reference_id=str(item.id),
    )
    for leadership_role in ('md', 'ceo'):
        _create_notification(
            role=leadership_role,
            title=f'New {request_label} Approval',
            message=(
                f'{item.title} was submitted for approval and is awaiting '
                'Team Lead review.'
            ),
            notification_type='info',
            module='approval',
            reference_id=str(item.id),
        )
    return Response({'success': True, 'message': 'Approval request sent.', 'approval': _approval_payload(item)}, status=201)


@api_view(['GET', 'POST'])
def employee_approval_action_view(request, pk):
    item = EmployeeApprovalRequest.objects.filter(pk=pk).first()
    if item is None:
        return Response({'success': False, 'message': 'Approval request not found.'}, status=404)
    user_id = str(request.query_params.get('user_id') or request.data.get('user_id') or '').strip()
    user = User.objects.filter(user_id=user_id).first()
    role = user.role if user else 'employee'
    if request.method == 'GET':
        if role not in {'tl', 'ceo', 'md'} and item.employee_id != user_id:
            return Response({'success': False, 'message': 'You cannot view this approval.'}, status=403)
        return Response({'success': True, 'approval': _approval_payload(item)})
    action = str(request.data.get('action') or '').strip().lower()

    if action == 'cancel' and item.employee_id == user_id and item.status == 'requested':
        item.status = 'cancelled'
        item.save(update_fields=['status', 'updated_at'])
        return Response({'success': True, 'message': 'Request cancelled.', 'approval': _approval_payload(item)})
    if action not in {'approve', 'reject'} or role not in {'tl', 'ceo'}:
        return Response({'success': False, 'message': 'You cannot perform this action.'}, status=403)
    expected_stage = 0 if role == 'tl' else 1
    if item.status != 'requested' or item.current_stage != expected_stage:
        return Response({'success': False, 'message': 'This request is not awaiting your approval.'}, status=409)
    comment = str(request.data.get('comment') or '').strip()
    if role in {'tl', 'ceo'} and not comment:
        reviewer_label = 'Team Lead' if role == 'tl' else 'CEO'
        return Response({'success': False, 'message': f'{reviewer_label} reply is required.'}, status=400)

    decisions = list(item.decisions or [])
    if any(decision.get('role') == role for decision in decisions):
        return Response({'success': False, 'message': 'You already reviewed this request.'}, status=409)
    decisions.append({
        'role': role,
        'approver': user_id,
        'action': action,
        'comment': comment,
        'decided_at': timezone.now().isoformat(),
    })
    item.decisions = decisions
    if action == 'reject':
        item.status = 'rejected'
    elif role == 'tl':
        item.current_stage = 1
        request_label = {
            'social_media_post': 'Social Media Post',
            'leave_request': 'Leave Request',
        }.get(item.request_type, 'Daily Report')
        _create_notification(
            user_id=item.employee_id,
            title=f'{request_label} Approved by Team Lead',
            message=(
                f'{item.title} passed Team Lead approval and was sent to CEO '
                f'for final approval. TL reply: {comment}'
            ),
            notification_type='success',
            module='approval',
            reference_id=str(item.id),
        )
        _create_notification(
            role='ceo',
            title=f'{request_label} Final Approval',
            message=f'{item.title} passed Team Lead review and needs CEO approval.',
            notification_type='info',
            module='approval',
            reference_id=str(item.id),
        )
        _create_notification(
            role='md',
            title=f'{request_label} Passed Team Lead Review',
            message=f'{item.title} is now awaiting final CEO approval.',
            notification_type='info',
            module='approval',
            reference_id=str(item.id),
        )
    elif role == 'ceo':
        item.status = 'approved'
        item.current_stage = 2
    item.save(update_fields=['decisions', 'status', 'current_stage', 'updated_at'])
    if item.status in {'approved', 'rejected'}:
        reviewer_label = 'Team Lead' if role == 'tl' else 'CEO'
        reply_suffix = f' Reply: {comment}' if comment else ''
        _create_notification(
            user_id=item.employee_id,
            title=f'Approval Request {item.status.title()} by {reviewer_label}',
            message=f'{item.title} was {item.status} by {reviewer_label}.{reply_suffix}',
            notification_type='success' if item.status == 'approved' else 'error',
            module='approval',
            reference_id=str(item.id),
        )
        request_label = {
            'social_media_post': 'Social Media Post',
            'leave_request': 'Leave Request',
        }.get(item.request_type, 'Daily Report')
        # Once CEO makes the final decision, notify every Team Lead as well as
        # the employee so the whole review chain sees the final outcome.
        leadership_roles = ('ceo', 'md', 'tl') if role == 'ceo' else ('ceo', 'md')
        for leadership_role in leadership_roles:
            _create_notification(
                role=leadership_role,
                title=f'{request_label} {item.status.title()}',
                message=f'{item.title} was {item.status} by {reviewer_label}.',
                notification_type='success' if item.status == 'approved' else 'error',
                module='approval',
                reference_id=str(item.id),
            )
    message = 'Request approved.' if action == 'approve' else 'Request rejected.'
    return Response({'success': True, 'message': message, 'approval': _approval_payload(item)})


def _employee_context(request):
    user_id = request.query_params.get('user_id') or request.data.get('user_id')
    email = request.query_params.get('email') or request.data.get('email')

    user = None
    account = None

    if user_id:
        user = User.objects.filter(user_id=user_id).first()
        account = EmployeeAccount.objects.filter(employee_id=user_id).select_related('registration').first()
        if account is None and user is not None:
            account = EmployeeAccount.objects.filter(user=user).select_related('registration').first()
    if account is None and email:
        account = (
            EmployeeAccount.objects.select_related('registration')
            .filter(
                Q(employee_email__iexact=email)
                | Q(registration__personal_email__iexact=email)
            )
            .first()
        )
    if user is None and account is not None:
        user = (
            User.objects.filter(email__iexact=account.employee_email).first()
            or User.objects.filter(user_id=account.employee_id).first()
        )
    if user is None and email:
        user = User.objects.filter(email__iexact=email).first()
    if account is None and user is not None:
        account = (
            EmployeeAccount.objects.select_related('registration')
            .filter(Q(employee_id=user.user_id) | Q(employee_email__iexact=user.email))
            .first()
        )

    return user, account


def _employee_id(user, account, request):
    return (
        request.data.get('employee_id')
        or request.query_params.get('employee_id')
        or (account.employee_id if account else '')
        or request.data.get('user_id')
        or request.query_params.get('user_id')
        or (user.user_id if user else '')
    )


def _employee_name(employee_id):
    account = EmployeeAccount.objects.filter(employee_id=employee_id).select_related('registration').first()
    if account:
        name = f'{account.registration.first_name} {account.registration.last_name}'.strip()
        return name or account.employee_email
    user = User.objects.filter(user_id=employee_id).first()
    if user:
        return f'{user.first_name} {user.last_name}'.strip() or user.email
    return employee_id or 'Employee'


def _relative_time(value):
    if not value:
        return ''
    delta = timezone.now() - value
    minutes = max(0, int(delta.total_seconds() // 60))
    if minutes < 1:
        return 'Just now'
    if minutes < 60:
        return f'{minutes} min ago'
    hours = minutes // 60
    if hours < 24:
        return f'{hours} hr ago'
    days = hours // 24
    return f'{days} day ago' if days == 1 else f'{days} days ago'


def _notification_payload(notification):
    return {
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'subtitle': notification.message,
        'time': _relative_time(notification.created_at),
        'type': notification.notification_type,
        'module': notification.module,
        'reference_id': notification.reference_id,
        'is_read': notification.is_read,
        'created_at': notification.created_at.isoformat() if notification.created_at else '',
    }


def _notifications_for_employee(employee_id, employee_email=''):
    if not employee_id:
        return []
    _ensure_meeting_reminders(employee_id, employee_email)
    return [_notification_payload(item) for item in AppNotification.objects.filter(recipient_user_id=employee_id)[:30]]


def _ensure_meeting_reminders(employee_id, employee_email=''):
    now = timezone.now()
    today = timezone.localdate()
    one_hour_before = now + timedelta(hours=1)
    for meeting in MdMeeting.objects.filter(status='upcoming')[:100]:
        participants = meeting.participants if isinstance(meeting.participants, list) else []
        if not _meeting_has_employee(participants, employee_id, employee_email):
            continue
        start = _meeting_start_at(meeting.date_label, meeting.time_label)
        if start is None:
            continue
        meeting_date = start.date()
        if today == meeting_date - timedelta(days=1):
            _create_meeting_reminder_once(
                employee_id,
                meeting,
                'Meeting Tomorrow',
                f'{meeting.title} is scheduled tomorrow at {meeting.time_label}.',
            )
        if today == meeting_date and now <= start:
            _create_meeting_reminder_once(
                employee_id,
                meeting,
                'Meeting Today',
                f'{meeting.title} is scheduled today at {meeting.time_label}.',
            )
        if now <= start <= one_hour_before:
            _create_meeting_reminder_once(
                employee_id,
                meeting,
                'Meeting Reminder',
                f'{meeting.title} starts in less than 1 hour at {meeting.time_label}.',
            )


def _create_meeting_reminder_once(employee_id, meeting, title, message):
    exists = AppNotification.objects.filter(
        recipient_user_id=employee_id,
        module='meeting',
        reference_id=str(meeting.id),
        title=title,
    ).exists()
    if exists:
        return
    _create_notification(
        user_id=employee_id,
        title=title,
        message=message,
        notification_type='warning',
        module='meeting',
        reference_id=meeting.id,
    )


def _meeting_start_at(date_label, time_label):
    date_text = str(date_label or '').strip()
    time_text = str(time_label or '').strip().upper()
    parsed_date = None
    for fmt in ('%d-%m-%Y', '%Y-%m-%d', '%d %b %Y'):
        try:
            parsed_date = datetime.strptime(date_text, fmt).date()
            break
        except ValueError:
            continue
    if parsed_date is None:
        return None
    try:
        parsed_time = datetime.strptime(time_text, '%I:%M %p').time()
    except ValueError:
        try:
            parsed_time = datetime.strptime(time_text, '%H:%M').time()
        except ValueError:
            return None
    return timezone.make_aware(datetime.combine(parsed_date, parsed_time), timezone.get_current_timezone())


def _create_notification(*, user_id='', role='', title, message, notification_type='info', module='', reference_id=''):
    notification = AppNotification.objects.create(
        recipient_user_id=user_id,
        recipient_role=role,
        title=title,
        message=message,
        notification_type=notification_type,
        module=module,
        reference_id=str(reference_id or ''),
    )
    from .push_notifications import send_mobile_push
    notification.push_sent = send_mobile_push(notification)
    if notification.push_sent:
        notification.save(update_fields=['push_sent'])
    return notification


ATTENDANCE_MONITOR_ROLES = ('superadmin', 'admin', 'ceo', 'md', 'director', 'hr')


def _notify_employee_presence(record, event):
    employee_name = _employee_name(record.employee_id)
    event_label = 'checked in' if event == 'check_in' else 'checked out'
    event_time = record.check_in if event == 'check_in' else record.check_out
    offset = (
        record.check_in_timezone_offset_minutes
        if event == 'check_in'
        else record.check_out_timezone_offset_minutes
    )
    message = (
        f'{employee_name} ({record.employee_id}) {event_label} at '
        f'{_format_time(event_time, offset)}. Status: {record.status}.'
    )
    event_key = 'in' if event == 'check_in' else 'out'
    reference_id = f'{record.employee_id}:{record.attendance_date:%Y%m%d}:{event_key}'
    for role in ATTENDANCE_MONITOR_ROLES:
        exists = AppNotification.objects.filter(
            recipient_role=role,
            module='attendance_presence',
            reference_id=reference_id,
        ).exists()
        if not exists:
            _create_notification(
                role=role,
                title='Employee Attendance',
                message=message,
                notification_type='success' if event == 'check_in' else 'info',
                module='attendance_presence',
                reference_id=reference_id,
            )
    tl_recipient = _tl_recipient_for_employee(record.employee_id)
    if tl_recipient and not AppNotification.objects.filter(
        recipient_user_id=tl_recipient,
        module='attendance_presence',
        reference_id=reference_id,
    ).exists():
        _create_notification(
            user_id=tl_recipient,
            title='Team Attendance',
            message=message,
            notification_type='success' if event == 'check_in' else 'info',
            module='attendance_presence',
            reference_id=reference_id,
        )


def _identity_filter(value):
    text = str(value or '').strip()
    if not text:
        return Q(pk__isnull=True)
    parts = text.split()
    name_filter = Q(registration__first_name__icontains=text)
    if len(parts) >= 2:
        name_filter |= Q(
            registration__first_name__iexact=parts[0],
            registration__last_name__iexact=' '.join(parts[1:]),
        )
    return (
        Q(employee_id__iexact=text)
        | Q(employee_email__iexact=text)
        | Q(registration__first_name__iexact=text)
        | Q(registration__last_name__iexact=text)
        | name_filter
    )


def _tl_recipient_for_employee(employee_id):
    account = EmployeeAccount.objects.filter(
        employee_id=employee_id,
    ).select_related('registration').first()
    reporting_tl = str(account.reporting_tl if account else '').strip()
    if not reporting_tl:
        return ''

    tl_account = EmployeeAccount.objects.filter(
        _identity_filter(reporting_tl),
        designation='tl',
    ).first()
    if tl_account:
        return tl_account.employee_id

    user = User.objects.filter(
        Q(user_id__iexact=reporting_tl)
        | Q(email__iexact=reporting_tl)
        | Q(first_name__iexact=reporting_tl)
        | Q(first_name__icontains=reporting_tl)
        | Q(last_name__iexact=reporting_tl)
    ).first()
    return user.user_id if user else ''


DOCUMENT_FIELD_LABELS = {
    'doc_passport_photo': 'Passport Size Photo',
    'doc_aadhar': 'Aadhaar Card Copy',
    'doc_pan': 'PAN Card Copy',
    'doc_bank_passbook': 'Bank Passbook',
    'doc_10th': '10th Marksheet',
    'doc_12th': '12th / Diploma',
    'doc_degree': 'Degree Certificate',
    'doc_consolidated': 'Consolidated Marksheet',
    'doc_college_noc': 'NOC Certificate from College',
    'doc_resume': 'Resume/CV',
    'doc_experience_cert': 'Experience Certificate',
    'doc_relieving': 'Relieving Letter',
    'doc_salary_slips': 'Salary Slips',
    'doc_passport_copy': 'Passport Copy',
    'doc_driving': 'Driving License Copy',
    'doc_vaccination': 'Vaccination Certificate',
}

IMAGE_UPLOAD_EXTENSIONS = {'.jpg', '.jpeg', '.png'}
DOCUMENT_UPLOAD_EXTENSIONS = {'.pdf', '.doc'}


def _validated_document_upload(upload):
    extension = Path(upload.name or '').suffix.lower()
    if extension not in IMAGE_UPLOAD_EXTENSIONS | DOCUMENT_UPLOAD_EXTENSIONS:
        return '', 'Invalid file. Use JPG, JPEG, PNG, PDF, or DOC.'

    try:
        header = upload.read(16)
        upload.seek(0)
        if extension in {'.jpg', '.jpeg'}:
            valid = header.startswith(b'\xff\xd8\xff')
            file_type = 'image'
        elif extension == '.png':
            valid = header.startswith(b'\x89PNG\r\n\x1a\n')
            file_type = 'image'
        elif extension == '.pdf':
            valid = header.startswith(b'%PDF-')
            file_type = 'document'
        elif extension == '.doc':
            valid = header.startswith(b'\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1')
            file_type = 'document'
        else:
            valid = False
            file_type = 'document'
    except (OSError, ValueError):
        upload.seek(0)
        valid = False
        file_type = ''

    if not valid:
        return '', 'The selected file content does not match its extension.'
    return file_type, ''


def _document_url(registration, field_name, request=None):
    if not registration:
        return ''
    field = getattr(registration, field_name, None)
    if not field:
        return ''
    try:
        url = field.url
    except Exception:
        url = ''
    if url:
        return request.build_absolute_uri(url) if request and url.startswith('/') else url
    raw = str(field).strip()
    if not raw:
        return ''
    if raw.startswith('http'):
        return raw
    try:
        return cloudinary.CloudinaryImage(raw).build_url()
    except Exception:
        return raw


def _registration_documents(registration, request=None):
    if not registration:
        return []
    statuses = registration.document_statuses or {}
    documents = []
    for key, title in DOCUMENT_FIELD_LABELS.items():
        url = _document_url(registration, key, request)
        state = statuses.get(key, {})
        status_value = state.get('status') or ('uploaded' if url else 'not_uploaded')
        documents.append({
            'document_key': key,
            'title': title,
            'date': state.get('reviewed_at') or state.get('reuploaded_at') or '',
            'type': state.get('file_type') or 'Image',
            'url': url,
            'status': status_value,
            'issue_type': state.get('issue_type', ''),
            'remark': state.get('remark', ''),
            'suggested_action': state.get('suggested_action', ''),
            'priority': state.get('priority', ''),
        })
    return documents


def _parse_date(value, fallback):
    if not value:
        return fallback
    try:
        return datetime.strptime(value, '%Y-%m-%d').date()
    except ValueError:
        return fallback


def _mobile_time(request):
    timestamp = request.data.get('mobile_timestamp')
    offset_minutes = request.data.get('timezone_offset_minutes')
    try:
        offset = int(offset_minutes)
    except (TypeError, ValueError):
        offset = None

    if timestamp:
        try:
            parsed = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            if offset is not None:
                tzinfo = datetime_timezone(timedelta(minutes=offset))
                parsed = parsed.replace(tzinfo=tzinfo) if parsed.tzinfo is None else parsed.astimezone(tzinfo)
            elif parsed.tzinfo is None:
                parsed = timezone.make_aware(parsed)
            return parsed, offset
        except ValueError:
            pass

    current = timezone.localtime()
    return current, offset


def _format_time(value, offset_minutes=None):
    if not value:
        return '--:--'
    if offset_minutes is not None:
        tzinfo = datetime_timezone(timedelta(minutes=offset_minutes))
        return value.astimezone(tzinfo).strftime('%I:%M %p')
    return timezone.localtime(value).strftime('%I:%M %p')


SHIFT_START_HOUR = 9
SHIFT_END_HOUR = 18
LUNCH_START_HOUR = 13
LUNCH_END_HOUR = 14
GRACE_MINUTES = 10
FULL_DAY_MINUTES = 8 * 60
HALF_DAY_MINUTES = 4 * 60
AUTO_CHECKOUT_HOUR = 18
AUTO_CHECKOUT_MINUTE = 30
EARLY_CHECKOUT_CUTOFF_HOUR = 17
EARLY_CHECKOUT_CUTOFF_MINUTE = 30
HALF_DAY_CHECKOUT_HOUR = 13


def _attendance_today():
    return timezone.now().astimezone(
        datetime_timezone(timedelta(hours=5, minutes=30)),
    ).date()


def _approved_leave_for_day(employee_id, attendance_date):
    return EmployeeLeaveRequest.objects.filter(
        employee_id=employee_id,
        status='approved',
        hr_status='approved',
        from_date__lte=attendance_date,
        to_date__gte=attendance_date,
    ).first()


def _is_before_checkout_cutoff(value):
    return (value.hour, value.minute) < (
        EARLY_CHECKOUT_CUTOFF_HOUR,
        EARLY_CHECKOUT_CUTOFF_MINUTE,
    )


def _format_minutes(minutes):
    minutes = max(0, int(minutes or 0))
    hours, remainder = divmod(minutes, 60)
    return f'{hours:02d}h {remainder:02d}m'


def _local_attendance_time(value, offset_minutes=None):
    if not value:
        return None
    if offset_minutes is not None:
        return value.astimezone(datetime_timezone(timedelta(minutes=offset_minutes)))
    return timezone.localtime(value)


def _overlap_minutes(start, end, block_start, block_end):
    overlap_start = max(start, block_start)
    overlap_end = min(end, block_end)
    if overlap_end <= overlap_start:
        return 0
    return int((overlap_end - overlap_start).total_seconds() // 60)


def _attendance_calculation(check_in, check_out=None, offset_minutes=None):
    local_check_in = _local_attendance_time(check_in, offset_minutes)
    local_check_out = _local_attendance_time(check_out, offset_minutes)
    if not local_check_in:
        return {
            'status': 'Not Marked',
            'working_minutes': 0,
            'working_hours': '--',
            'late_minutes': 0,
            'late_entry': '--',
            'overtime_minutes': 0,
            'overtime': '00h 00m',
            'regular_minutes': FULL_DAY_MINUTES,
            'regular_hours': _format_minutes(FULL_DAY_MINUTES),
            'shift_time': '09:00 AM - 06:00 PM',
            'lunch_time': '01:00 PM - 02:00 PM',
            'grace_time': f'{GRACE_MINUTES} min',
        }

    work_date = local_check_in.date()
    shift_start = local_check_in.replace(
        hour=SHIFT_START_HOUR,
        minute=0,
        second=0,
        microsecond=0,
    )
    grace_end = shift_start + timedelta(minutes=GRACE_MINUTES)
    lunch_start = local_check_in.replace(
        hour=LUNCH_START_HOUR,
        minute=0,
        second=0,
        microsecond=0,
    )
    lunch_end = local_check_in.replace(
        hour=LUNCH_END_HOUR,
        minute=0,
        second=0,
        microsecond=0,
    )

    late_minutes = max(0, int((local_check_in - grace_end).total_seconds() // 60))
    working_minutes = 0
    if local_check_out and local_check_out > local_check_in:
        gross_minutes = int((local_check_out - local_check_in).total_seconds() // 60)
        lunch_minutes = _overlap_minutes(
            local_check_in,
            local_check_out,
            lunch_start,
            lunch_end,
        )
        working_minutes = max(0, gross_minutes - lunch_minutes)

    if local_check_in.date() != work_date:
        working_minutes = 0

    overtime_minutes = max(0, working_minutes - FULL_DAY_MINUTES)
    if local_check_out and working_minutes < HALF_DAY_MINUTES:
        attendance_status = 'Half Day'
    elif late_minutes > 0:
        attendance_status = 'Late Entry'
    else:
        attendance_status = 'Present'

    return {
        'status': attendance_status,
        'working_minutes': working_minutes,
        'working_hours': _format_minutes(working_minutes) if local_check_out else '--',
        'late_minutes': late_minutes,
        'late_entry': _format_minutes(late_minutes),
        'overtime_minutes': overtime_minutes,
        'overtime': _format_minutes(overtime_minutes),
        'regular_minutes': FULL_DAY_MINUTES,
        'regular_hours': _format_minutes(FULL_DAY_MINUTES),
        'shift_time': '09:00 AM - 06:00 PM',
        'lunch_time': '01:00 PM - 02:00 PM',
        'grace_time': f'{GRACE_MINUTES} min',
    }


def _file_url(request, field):
    if not field:
        return ''
    legacy_path = settings.BASE_DIR / field.name
    media_path = settings.MEDIA_ROOT / field.name
    if field.name.startswith('attendance/') and legacy_path.exists() and not media_path.exists():
        legacy_url = f"/attendance-media/{field.name.removeprefix('attendance/')}"
        return request.build_absolute_uri(legacy_url) if request else legacy_url
    url = field.url
    return request.build_absolute_uri(url) if request else url


def _attendance_payload(record, request=None):
    if record is None:
        empty_calc = _attendance_calculation(None)
        return {
            'date': date.today().isoformat(),
            'status': 'Not Marked',
            'check_in': '--:--',
            'check_out': '--:--',
            'working_hours': '--',
            'late_entry': '--',
            'late_minutes': 0,
            'overtime': '00h 00m',
            'overtime_minutes': 0,
            'regular_minutes': empty_calc['regular_minutes'],
            'regular_hours': empty_calc['regular_hours'],
            'shift_time': empty_calc['shift_time'],
            'lunch_time': empty_calc['lunch_time'],
            'grace_time': empty_calc['grace_time'],
            'location': '',
            'accuracy': '--',
        }

    accuracy = _accuracy_display(record.check_out_accuracy or record.check_in_accuracy)
    latitude = record.check_out_latitude or record.check_in_latitude
    longitude = record.check_out_longitude or record.check_in_longitude
    calc = _attendance_calculation(
        record.check_in,
        record.check_out,
        record.check_out_timezone_offset_minutes
        if record.check_out_timezone_offset_minutes is not None
        else record.check_in_timezone_offset_minutes,
    )
    return {
        'id': record.id,
        'date': record.attendance_date.isoformat(),
        'status': calc['status'] if record.check_in else record.status,
        'check_in': _format_time(record.check_in, record.check_in_timezone_offset_minutes),
        'check_out': _format_time(record.check_out, record.check_out_timezone_offset_minutes),
        'working_hours': calc['working_hours'] if record.check_out else record.working_hours or '--',
        'late_entry': calc['late_entry'],
        'late_minutes': calc['late_minutes'],
        'overtime': calc['overtime'],
        'overtime_minutes': calc['overtime_minutes'],
        'regular_hours': calc['regular_hours'],
        'shift_time': calc['shift_time'],
        'lunch_time': calc['lunch_time'],
        'grace_time': calc['grace_time'],
        'location': '',
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'check_in_selfie': _file_url(request, record.check_in_selfie),
        'check_out_selfie': _file_url(request, record.check_out_selfie),
    }


def _accuracy_display(value):
    text = str(value or '').strip()
    if not text:
        return '--'
    try:
        numeric = float(text)
    except ValueError:
        return text if 'meter' in text.lower() else f'{text} meters'
    if numeric <= 0:
        return '--'
    rounded = round(numeric, 1)
    if rounded.is_integer():
        rounded = int(rounded)
    return f'{rounded} meters'


def _certificate_name(record):
    certificate = record.medical_certificate
    if not certificate:
        return ''
    return certificate.name.split('/')[-1]


def _certificate_url(record, request=None):
    certificate = record.medical_certificate
    if not certificate:
        return ''
    try:
        url = certificate.url
    except ValueError:
        return ''
    return request.build_absolute_uri(url) if request is not None else url


def _leave_payload(record, request=None):
    if record.status == 'pending' and record.tl_status == 'approved':
        display_status = 'Pending HR'
    elif record.status == 'pending':
        display_status = 'Pending TL'
    else:
        display_status = record.status.title()
    return {
        'id': record.id,
        'leave_type': record.leave_type,
        'type': record.leave_type,
        'from_date': record.from_date.isoformat(),
        'to_date': record.to_date.isoformat(),
        'date': f'{record.from_date.isoformat()} - {record.to_date.isoformat()}',
        'days': record.total_days,
        'reason': record.reason,
        'session': record.session,
        'medical_certificate': _certificate_name(record),
        'medical_certificate_url': _certificate_url(record, request),
        'document_name': _certificate_name(record),
        'status': display_status,
        'overall_status': record.status.title(),
        'tl_status': record.tl_status.title(),
        'hr_status': record.hr_status.title(),
        'approved_by': record.approved_by,
        'tl_approved_by': record.tl_approved_by,
        'hr_approved_by': record.hr_approved_by,
        'tl_reviewed_at': record.tl_reviewed_at.isoformat() if record.tl_reviewed_at else '',
        'hr_reviewed_at': record.hr_reviewed_at.isoformat() if record.hr_reviewed_at else '',
        'reviewed_at': record.reviewed_at.isoformat() if record.reviewed_at else '',
        'created_at': record.created_at.isoformat() if record.created_at else '',
    }


def _normalize_leave_type(value):
    text = ''.join(ch for ch in str(value or '').lower() if ch.isalpha())
    if text == 'cl' or 'casual' in text:
        return 'casualleave'
    if text == 'sl' or 'sick' in text:
        return 'sickleave'
    if text == 'al' or 'annual' in text or 'earned' in text:
        return 'annualleave'
    if 'comp' in text:
        return 'compoff'
    return text


def _leave_days_for(records, leave_type, status_group=None):
    leave_key = _normalize_leave_type(leave_type)
    total = 0
    for record in records:
        if _normalize_leave_type(record.leave_type) != leave_key:
            continue
        if record.status == 'rejected':
            continue
        if status_group == 'pending' and record.status != 'pending':
            continue
        if status_group == 'used' and record.status == 'pending':
            continue
        total += record.total_days
    return float(total)


def _active_accrual_months(joining_date, today):
    start = max(joining_date or date(today.year, 1, 1), date(today.year, 1, 1))
    if start > today:
        return 0
    return min(((today.year - start.year) * 12) + today.month - start.month + 1, 12)


def _leave_balance_payload(employee_id, account=None):
    today = date.today()
    fiscal_year = f'FY {today.year}-{str(today.year + 1)[-2:]}'
    joining_date = account.date_of_joining if account else date(today.year, 1, 1)
    active_months = _active_accrual_months(joining_date, today)
    year_records = list(EmployeeLeaveRequest.objects.filter(
        employee_id=employee_id,
        from_date__year=today.year,
    )) if employee_id else []
    type_configs = [
        ('Annual Leave', 12.0, 'annualleave', 'palm_tree'),
        ('Sick Leave', 8.0, 'sickleave', 'health_and_safety'),
        ('Casual Leave', 4.0, 'casualleave', 'umbrella'),
        ('Comp-Off', 0.0, 'compoff', 'event_available'),
    ]
    summaries = []
    total_entitlement = 0.0
    total_accrued = 0.0
    total_used = 0.0
    total_pending = 0.0
    for title, entitlement, key, icon in type_configs:
        used = _leave_days_for(year_records, key, 'used')
        pending = _leave_days_for(year_records, key, 'pending')
        accrued = entitlement if entitlement == 0 else round((entitlement / 12) * active_months, 2)
        available = max(entitlement - used, 0)
        summaries.append({
            'type': title,
            'entitlement': entitlement,
            'accrued': accrued,
            'used': used,
            'pending': pending,
            'available': round(available, 2),
            'icon': icon,
        })
        total_entitlement += entitlement
        total_accrued += accrued
        total_used += used
        total_pending += pending
    carry_forward = 0.0
    total_available = max(total_entitlement + carry_forward - total_used, 0)
    next_month = today.month + 1 if today.month < 12 else 1
    next_year = today.year if today.month < 12 else today.year + 1
    next_accrual_date = date(next_year, next_month, 1)
    return {
        'fiscal_year': fiscal_year,
        'total_entitlement': round(total_entitlement, 2),
        'total_available': round(total_available, 2),
        'accrued_this_year': round(total_accrued, 2),
        'used_this_year': round(total_used, 2),
        'pending_approval': round(total_pending, 2),
        'carry_forward': carry_forward,
        'next_accrual_days': 1.5,
        'next_accrual_date': next_accrual_date.isoformat(),
        'accrual_frequency': 'Monthly (1.5 Days / Month)',
        'types': summaries,
    }


def _employee_payload(user, account, request=None):
    today = _attendance_today()
    first_name = user.first_name if user else ''
    last_name = user.last_name if user else ''
    full_name = f'{first_name} {last_name}'.strip() or 'Employee'

    # Employee-owned records are keyed by EmployeeAccount.employee_id. This can
    # differ from User.user_id when a leadership account opens Employee mode.
    employee_id = (account.employee_id if account else '') or (user.user_id if user else '')
    attendance_ids = {
        value
        for value in (
            employee_id,
            account.employee_id if account else '',
            user.user_id if user else '',
        )
        if value
    }
    today_records = EmployeeAttendanceRecord.objects.filter(
        employee_id__in=attendance_ids,
        attendance_date=today,
    ) if attendance_ids else EmployeeAttendanceRecord.objects.none()
    today_record = (
        today_records.filter(employee_id=employee_id).first()
        or today_records.first()
    )
    leave_records = EmployeeLeaveRequest.objects.filter(employee_id=employee_id)[:10] if employee_id else []
    employee_email = user.email if user else account.employee_email if account else ''
    task_owner = Q(pk__isnull=True)
    if employee_id:
        task_owner |= Q(assignee_id=employee_id)
    if employee_email:
        task_owner |= Q(assignee_email__iexact=employee_email)

    return {
        'profile': {
            'name': full_name,
            'first_name': first_name,
            'email': employee_email,
            'employee_id': employee_id,
            'department': account.get_department_display() if account else 'Operations',
            'designation': account.get_designation_display() if account else 'Employee',
            'date_of_joining': str(account.date_of_joining) if account else '',
            'reporting_tl': account.reporting_tl if account else '',
            'work_location': account.work_location if account else '',
            'doc_passport_photo': _document_url(
                account.registration if account else None,
                'doc_passport_photo',
                request,
            ),
        },
        'attendance': _attendance_payload(today_record),
        'leave_balances': _leave_balance_payload(employee_id, account),
        'leaves': [_leave_payload(record) for record in leave_records],
        'notifications': _notifications_for_employee(employee_id, employee_email),
        'meetings': _employee_meetings(employee_id, employee_email),
        'tasks': [
            {
                'id': task.id,
                'title': task.title,
                'project': task.project,
                'description': task.description,
                'due': task.due_date,
                'priority': task.priority,
                'status': task.get_status_display(),
                'assigned_by': task.created_by,
                'created_at': task.created_at.isoformat(),
            }
            for task in TeamTask.objects.filter(task_owner)[:50]
        ],
        'payslip': latest_payslip_for_employee(employee_id),
        'documents': _registration_documents(account.registration if account else None, request),
    }


def _employee_meetings(employee_id, employee_email):
    if not employee_id and not employee_email:
        return []

    meetings = []
    for meeting in MdMeeting.objects.filter(status='upcoming')[:50]:
        participants = meeting.participants if isinstance(meeting.participants, list) else []
        if not _meeting_has_employee(participants, employee_id, employee_email):
            continue
        agenda = meeting.agenda if isinstance(meeting.agenda, list) else []
        metadata = {}
        if agenda and isinstance(agenda[-1], dict) and agenda[-1].get('_meta') == 'meeting':
            metadata = agenda[-1]
            agenda = agenda[:-1]
        meeting_link = metadata.get('meeting_link') or meeting.location
        platform = metadata.get('platform') or meeting.meeting_type or _meeting_mode(meeting_link)
        if 'meet.bitbyte.in' in str(meeting_link):
            meeting_link = _default_employee_meeting_link(platform)
        meetings.append({
            'id': meeting.id,
            'title': meeting.title,
            'date': meeting.date_label,
            'time': meeting.time_label,
            'mode': platform,
            'platform': platform,
            'meeting_link': meeting_link,
            'link': meeting_link,
            'location': meeting_link,
            'description': meeting.description,
            'duration': meeting.duration,
            'agenda': agenda,
            'status': meeting.status,
        })
    return meetings


def _default_employee_meeting_link(platform):
    platform = str(platform or '').lower()
    if 'google' in platform:
        return 'https://meet.google.com/new'
    if 'team' in platform:
        return 'https://teams.microsoft.com/'
    return 'https://zoom.us/join'


def _meeting_has_employee(participants, employee_id, employee_email):
    employee_id = (employee_id or '').lower()
    employee_email = (employee_email or '').lower()
    for participant in participants:
        if isinstance(participant, dict):
            values = [
                participant.get('id'),
                participant.get('employee_id'),
                participant.get('email'),
                participant.get('trailing'),
            ]
        else:
            values = [participant]
        normalized = {str(value or '').lower() for value in values}
        if employee_id and employee_id in normalized:
            return True
        if employee_email and employee_email in normalized:
            return True
    return False


def _meeting_mode(location):
    value = (location or '').lower()
    if 'meet.google' in value:
        return 'Google Meet'
    if 'zoom' in value:
        return 'Zoom Meeting'
    if value.startswith('http'):
        return 'Online Meeting'
    return 'Virtual' if value else ''


@api_view(['GET'])
def employee_dashboard_view(request):
    user, account = _employee_context(request)
    return Response({'success': True, 'data': _employee_payload(user, account, request)})


@api_view(['GET'])
def employee_payslip_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    return Response({
        'success': True,
        'payslip': latest_payslip_for_employee(employee_id, request),
    })


@api_view(['POST'])
def employee_document_reupload_view(request):
    user, account = _employee_context(request)
    if account is None or account.registration is None:
        return Response(
            {'success': False, 'message': 'Employee registration not found.'},
            status=status.HTTP_404_NOT_FOUND,
        )

    document_key = request.data.get('document_key') or request.data.get('document')
    upload = request.FILES.get('document')
    if document_key not in DOCUMENT_FIELD_LABELS:
        return Response({'success': False, 'message': 'Invalid document.'}, status=status.HTTP_400_BAD_REQUEST)
    if upload is None:
        return Response({'success': False, 'message': 'Document file is required.'}, status=status.HTTP_400_BAD_REQUEST)

    file_type, validation_error = _validated_document_upload(upload)
    if validation_error:
        return Response(
            {'success': False, 'message': validation_error},
            status=status.HTTP_400_BAD_REQUEST,
        )
    requested_type = (request.data.get('file_type') or '').strip().lower()
    if requested_type and requested_type != file_type:
        return Response(
            {'success': False, 'message': 'The selected file type does not match the uploaded file.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if document_key == 'doc_passport_photo' and file_type != 'image':
        return Response(
            {'success': False, 'message': 'Passport Size Photo must be a JPG, JPEG, or PNG image.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    registration = account.registration
    setattr(registration, document_key, upload)
    statuses = dict(registration.document_statuses or {})
    statuses[document_key] = {
        **statuses.get(document_key, {}),
        'status': 'pending',
        'file_type': file_type.title(),
        'reuploaded_at': timezone.now().isoformat(),
        'remark': '',
    }
    registration.document_statuses = statuses
    history = list(registration.document_review_history or [])
    history.insert(0, {
        'document_key': document_key,
        'document_title': DOCUMENT_FIELD_LABELS[document_key],
        'status': 'pending',
        'actor': 'Employee',
        'remark': 'Employee re-uploaded corrected document.',
        'created_at': timezone.now().isoformat(),
    })
    registration.document_review_history = history[:50]
    registration.status = 'pending'
    registration.save()

    _create_notification(
        role='hr',
        title='Document Pending Review',
        message=f'{_employee_name(account.employee_id)} re-uploaded {DOCUMENT_FIELD_LABELS[document_key]}.',
        notification_type='warning',
        module='documents',
        reference_id=f'{registration.id}:{document_key}',
    )
    _create_notification(
        user_id=account.employee_id,
        title='Document Submitted',
        message=f'{DOCUMENT_FIELD_LABELS[document_key]} was submitted for HR review.',
        notification_type='info',
        module='documents',
        reference_id=f'{registration.id}:{document_key}',
    )
    return Response({
        'success': True,
        'message': 'Document submitted for HR review.',
        'documents': _registration_documents(registration),
    })


@api_view(['POST'])
def employee_check_in_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    selfie = request.FILES.get('selfie')
    if selfie is None:
        return Response(
            {'success': False, 'message': 'Selfie is required for check-in.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if not employee_id:
        return Response(
            {'success': False, 'message': 'Employee ID is required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    now, offset_minutes = _mobile_time(request)
    record, _ = EmployeeAttendanceRecord.objects.get_or_create(
        employee_id=employee_id,
        attendance_date=now.date(),
        defaults={'status': 'Present'},
    )
    record.check_in = record.check_in or now
    record.check_in_timezone_offset_minutes = offset_minutes
    calc = _attendance_calculation(record.check_in, None, offset_minutes)
    record.status = calc['status']
    record.check_in_latitude = request.data.get('latitude') or ''
    record.check_in_longitude = request.data.get('longitude') or ''
    record.check_in_accuracy = request.data.get('accuracy') or ''
    record.check_in_selfie = selfie
    record.save()
    _notify_employee_presence(record, 'check_in')

    return Response({
        'success': True,
        'message': 'Check-In Successful!',
        **_attendance_payload(record, request),
        'status': record.status,
        'selfie_file': selfie.name,
        'latitude': request.data.get('latitude'),
        'longitude': request.data.get('longitude'),
        'accuracy': _accuracy_display(record.check_in_accuracy),
    })


@api_view(['POST'])
def employee_check_out_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    selfie = request.FILES.get('selfie')
    if selfie is None:
        return Response(
            {'success': False, 'message': 'Selfie is required for check-out.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if not employee_id:
        return Response(
            {'success': False, 'message': 'Employee ID is required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    now, offset_minutes = _mobile_time(request)
    record, _ = EmployeeAttendanceRecord.objects.get_or_create(
        employee_id=employee_id,
        attendance_date=now.date(),
        defaults={'status': 'Present'},
    )
    if record.check_out:
        return Response({
            'success': True,
            'message': 'Check-out has already been recorded.',
            **_attendance_payload(record, request),
        })

    approved_leave = _approved_leave_for_day(employee_id, now.date())
    afternoon_half_day = bool(
        approved_leave and approved_leave.session == 'Second Half'
    )
    if _is_before_checkout_cutoff(now) and not (
        afternoon_half_day and now.hour >= HALF_DAY_CHECKOUT_HOUR
    ):
        approved_permission = AttendanceRegularizationRequest.objects.filter(
            employee_id=employee_id,
            attendance_date=now.date(),
            request_type='early_checkout',
            status='approved',
        ).order_by('-reviewed_at').first()
        if approved_permission is None:
            permission, created = AttendanceRegularizationRequest.objects.get_or_create(
                employee_id=employee_id,
                attendance_date=now.date(),
                request_type='early_checkout',
                status='pending',
                defaults={
                    'requested_check_out': now,
                    'reason': request.data.get('reason') or (
                        'Early checkout permission requested from attendance screen.'
                    ),
                },
            )
            if created:
                tl_recipient = _tl_recipient_for_employee(employee_id)
                message = (
                    f'{_employee_name(employee_id)} requested permission to '
                    f'check out at {_format_time(now, offset_minutes)}.'
                )
                _create_notification(
                    user_id=tl_recipient,
                    role='' if tl_recipient else 'tl',
                    title='Early Check-Out Permission',
                    message=message,
                    notification_type='warning',
                    module='attendance_permission',
                    reference_id=permission.id,
                )
                _create_notification(
                    role='hr',
                    title='Early Check-Out Permission',
                    message=message,
                    notification_type='warning',
                    module='attendance_permission',
                    reference_id=permission.id,
                )
            return Response({
                'success': True,
                'permission_required': True,
                'permission_status': permission.status,
                'permission_id': permission.id,
                'message': 'Early check-out permission was sent to TL and HR for approval.',
                **_attendance_payload(record, request),
            }, status=status.HTTP_202_ACCEPTED)
    if not record.check_in:
        record.check_in = now.replace(hour=SHIFT_START_HOUR, minute=0, second=0, microsecond=0)
        record.check_in_timezone_offset_minutes = offset_minutes
    calc = _attendance_calculation(record.check_in, now, offset_minutes)
    record.status = calc['status']
    record.check_out = now
    record.check_out_timezone_offset_minutes = offset_minutes
    record.working_hours = calc['working_hours']
    record.check_out_latitude = request.data.get('latitude') or ''
    record.check_out_longitude = request.data.get('longitude') or ''
    record.check_out_accuracy = request.data.get('accuracy') or ''
    record.check_out_selfie = selfie
    record.save()
    _notify_employee_presence(record, 'check_out')

    return Response({
        'success': True,
        'message': 'Check-Out Successful!',
        **_attendance_payload(record, request),
        'status': record.status,
        'selfie_file': selfie.name,
        'latitude': request.data.get('latitude'),
        'longitude': request.data.get('longitude'),
        'accuracy': _accuracy_display(record.check_out_accuracy or record.check_in_accuracy),
    })


@api_view(['POST'])
def employee_leave_request_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    if not employee_id:
        return Response(
            {'success': False, 'message': 'Employee ID is required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    from_date = _parse_date(request.data.get('from_date'), None)
    to_date = _parse_date(request.data.get('to_date'), from_date)
    if from_date is None or to_date is None:
        return Response(
            {'success': False, 'message': 'From date and to date are required.'},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if to_date < from_date:
        return Response(
            {'success': False, 'message': 'To date cannot be before from date.'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    leave = EmployeeLeaveRequest.objects.create(
        employee_id=employee_id,
        leave_type=request.data.get('leave_type') or 'Leave',
        session=request.data.get('session') or 'Full Day',
        from_date=from_date,
        to_date=to_date,
        total_days=(to_date - from_date).days + 1,
        reason=request.data.get('reason') or '',
        medical_certificate=request.FILES.get('medical_certificate'),
    )
    _create_notification(
        user_id=employee_id,
        title='Leave Request Submitted',
        message=f'Your {leave.leave_type} request is waiting for TL approval.',
        notification_type='info',
        module='leave',
        reference_id=leave.id,
    )
    tl_recipient = _tl_recipient_for_employee(employee_id)
    _create_notification(
        user_id=tl_recipient,
        role='' if tl_recipient else 'tl',
        title='Leave Approval Pending',
        message=f'{_employee_name(employee_id)} requested {leave.total_days} day(s) of {leave.leave_type}.',
        notification_type='warning',
        module='leave',
        reference_id=leave.id,
    )
    return Response({
        'success': True,
        'message': 'Leave request submitted!',
        'leave': _leave_payload(leave, request),
    })


@api_view(['GET'])
def employee_attendance_history_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    today = date.today()
    from_date = _parse_date(request.query_params.get('from_date'), today)
    to_date = _parse_date(request.query_params.get('to_date'), from_date)
    records = EmployeeAttendanceRecord.objects.filter(
        employee_id=employee_id,
        attendance_date__gte=from_date,
        attendance_date__lte=to_date,
    )
    return Response({
        'success': True,
        'records': [_attendance_payload(record, request) for record in records],
    })


@api_view(['GET'])
def employee_leave_history_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    today = date.today()
    from_date = _parse_date(request.query_params.get('from_date'), today.replace(day=1))
    to_date = _parse_date(request.query_params.get('to_date'), today)
    records = EmployeeLeaveRequest.objects.filter(
        employee_id=employee_id,
        from_date__lte=to_date,
        to_date__gte=from_date,
    )
    return Response({
        'success': True,
        'records': [_leave_payload(record, request) for record in records],
        'leave_balances': _leave_balance_payload(employee_id, account),
    })


@api_view(['POST'])
def employee_task_complete_view(request):
    user, account = _employee_context(request)
    employee_id = _employee_id(user, account, request)
    employee_email = user.email if user else account.employee_email if account else ''
    task_id = request.data.get('task_id')

    if not task_id:
        return Response({'success': False, 'message': 'Task id is required.'}, status=status.HTTP_400_BAD_REQUEST)

    task_owner = Q(pk__isnull=True)
    if employee_id:
        task_owner |= Q(assignee_id=employee_id)
    if employee_email:
        task_owner |= Q(assignee_email__iexact=employee_email)
    task = TeamTask.objects.filter(task_owner, id=task_id).first()
    if task is None:
        return Response({'success': False, 'message': 'Assigned task was not found.'}, status=status.HTTP_404_NOT_FOUND)

    task.status = 'completed'
    task.save(update_fields=['status'])
    return Response({
        'success': True,
        'message': 'Task marked as completed!',
        'task': {'id': task.id, 'status': task.get_status_display()},
    })
