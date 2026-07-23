from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from django.core.cache import cache
from django.db.models import Count, Q, Sum
from django.db import IntegrityError
from django.utils import timezone
from django.utils.html import escape
from django.utils.text import slugify
from .serializers import LoginSerializer, CreateUserSerializer, EmployeeRegistrationSerializer, HR_DEPARTMENT_CHOICES, TEAM_MEMBER_DEPARTMENT_CHOICES, mask_phone_number
from .models import User, EmployeeRegistration, EmployeeLeaveRequest, EmployeeAttendanceRecord, MdMeeting, AppNotification, MobileDeviceToken, TeamTask, Project, EmployeePerformance, ReportSchedule, Payslip, SalaryStructure, PayrollProcess, OrganizationProfile, OrganizationBranch, OrganizationRole, OrganizationDepartment, RecruitmentJobOpening
from .models import BudgetPlan, BranchPerformanceSnapshot, DepartmentPerformanceSnapshot, ReportExportHistory, WorkflowApprovalRequest, Announcement
from .employee_views import _leave_balance_payload
from .payroll import generate_payroll_for_month, payslip_payload
import os
from .mailer import email_is_configured, send_email as send_transactional_email
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Attachment, Disposition, FileContent, FileName, FileType, Mail
from .models import EmployeeAccount
from .serializers import EmployeeAccountSerializer
import random
import string
import base64
import re
from datetime import date, datetime, timedelta, timezone as dt_timezone
from decimal import Decimal
import calendar
import csv
import io
import json

@api_view(['POST'])
def login_view(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        login_id = serializer.validated_data['email'].strip()
        password = serializer.validated_data['password']
        candidates = list(
            User.objects.filter(
                Q(email__iexact=login_id) | Q(user_id__iexact=login_id),
                is_active=True,
            )
        )
        matching_users = [user for user in candidates if user.check_password(password)]
        if len(matching_users) == 1:
            user = matching_users[0]
                # Check if employee account exists and OTC is still active
            try:
                from .models import EmployeeAccount
                emp_account = EmployeeAccount.objects.get(employee_email=user.email)
                if emp_account.otc == password:
                    return Response({
                        'success': True,
                        'requires_password_change': True,
                        'user_id': user.user_id,
                        'email': user.email,
                    })
            except (EmployeeAccount.DoesNotExist, EmployeeAccount.MultipleObjectsReturned):
                pass
            return Response({
                'success': True,
                'role': user.role,
                'email': user.email,
                'first_name': user.first_name,
                'user_id': user.user_id,
            })
        if not candidates:
            return Response({'success': False, 'message': 'User not found'}, status=404)
        if len(matching_users) > 1:
            return Response({
                'success': False,
                'message': 'More than one account uses these credentials. Login with your user ID.',
            }, status=409)
        return Response({'success': False, 'message': 'Wrong password'}, status=400)
    return Response(serializer.errors, status=400)


@api_view(['POST'])
def forgot_password_view(request):
    """Issue and email a fresh one-time credential for password recovery."""
    login_id = str(request.data.get('login_id') or '').strip()
    if not login_id:
        return Response(
            {'success': False, 'message': 'Employee code or email is required'},
            status=400,
        )

    try:
        user = User.objects.get(
            Q(email__iexact=login_id) | Q(user_id__iexact=login_id)
        )
    except User.DoesNotExist:
        return Response(
            {'success': False, 'message': 'No account found for these details'},
            status=404,
        )
    except User.MultipleObjectsReturned:
        return Response(
            {
                'success': False,
                'message': 'Multiple accounts use this email. Enter your user ID instead.',
            },
            status=409,
        )

    otc = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
    html = f'''
        <h2>Password reset requested</h2>
        <p>Use this one-time credential in the HRMS app to set a new password:</p>
        <p style="font-size:22px;font-weight:bold;letter-spacing:3px;">{otc}</p>
        <p>If you did not request this reset, contact your HR administrator.</p>
    '''
    if not send_email(user.email, 'HRMS Password Reset Credential', html):
        return Response(
            {'success': False, 'message': 'Unable to send the reset email'},
            status=503,
        )
    # Keep the current password valid until the user completes the reset.
    # The one-time credential expires after 15 minutes.
    cache.set(f'password_reset:{user.user_id}', otc, timeout=15 * 60)
    return Response({
        'success': True,
        'employee_id': user.user_id,
        'message': 'A one-time credential was sent to your registered email.',
    })


def _employee_name(employee_id):
    account = EmployeeAccount.objects.filter(employee_id=employee_id).select_related('registration').first()
    if account:
        registration = account.registration
        full_name = f'{registration.first_name} {registration.last_name}'.strip()
        return full_name or account.employee_email

    user = User.objects.filter(user_id=employee_id).first()
    if user:
        full_name = f'{user.first_name} {user.last_name}'.strip()
        return full_name or user.email

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
    message = notification.message
    return {
        'id': notification.id,
        'title': notification.title,
        'message': message,
        'subtitle': message,
        'time': _relative_time(notification.created_at),
        'trailing': _relative_time(notification.created_at),
        'type': notification.notification_type,
        'module': notification.module,
        'reference_id': notification.reference_id,
        'is_read': notification.is_read,
        'created_at': notification.created_at.isoformat() if notification.created_at else '',
    }


def _notifications_for_role(role):
    if not role:
        return []
    return [_notification_payload(item) for item in AppNotification.objects.filter(recipient_role=role)[:30]]


def _notifications_for_user(user_id):
    if not user_id:
        return []
    return [_notification_payload(item) for item in AppNotification.objects.filter(recipient_user_id=user_id)[:30]]


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
    # Mobile push delivery can be attached here when FCM credentials are configured.
    return notification


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


def _employee_recipient_id(registration):
    account = EmployeeAccount.objects.filter(registration=registration).first()
    if account:
        return account.employee_id
    user = User.objects.filter(email=registration.personal_email).first()
    return user.user_id if user else registration.personal_email


def _document_history_entry(document_key, status_value, actor, details=None):
    details = details or {}
    return {
        'document_key': document_key,
        'document_title': DOCUMENT_FIELD_LABELS.get(document_key, document_key),
        'status': status_value,
        'actor': actor,
        'issue_type': details.get('issue_type', ''),
        'remark': details.get('remark', ''),
        'suggested_action': details.get('suggested_action', ''),
        'priority': details.get('priority', ''),
        'created_at': timezone.now().isoformat(),
    }


def _notify_leave_employee(leave, title, message, notification_type):
    return _create_notification(
        user_id=leave.employee_id,
        title=title,
        message=message,
        notification_type=notification_type,
        module='leave',
        reference_id=leave.id,
    )


def _employee_count():
    return EmployeeAccount.objects.count()


def _active_employee_count():
    return EmployeeAccount.objects.filter(is_active=True).count()


def _department_count():
    department_keys = set(
        EmployeeAccount.objects.exclude(department='')
        .values_list('department', flat=True)
    )
    department_keys.update(
        User.objects.filter(is_active=True)
        .exclude(role='superadmin')
        .exclude(department='')
        .values_list('department', flat=True)
    )
    department_keys.update(
        OrganizationDepartment.objects.filter(is_active=True)
        .values_list('department_key', flat=True)
    )
    return len({
        str(value).strip().lower().replace(' ', '_')
        for value in department_keys
        if str(value).strip()
    })


def _branch_count():
    return EmployeeAccount.objects.exclude(work_location='').values('work_location').distinct().count()


def _ceo_organization_overview(user_id='', today=None):
    """Build the CEO organization dashboard from current workforce records."""
    today = today or timezone.localdate()
    accounts = EmployeeAccount.objects.select_related('registration').all()

    locations = []
    for row in (
        accounts.exclude(work_location='')
        .values('work_location')
        .annotate(count=Count('id'))
        .order_by('-count', 'work_location')
    ):
        locations.append({
            'name': row['work_location'],
            'count': row['count'],
        })

    branches = []
    for index, location in enumerate(locations):
        location_name = location['name'].strip()
        location_parts = [part.strip() for part in location_name.split(',') if part.strip()]
        branches.append({
            'id': index + 1,
            'name': location_name,
            'city': location_parts[0] if location_parts else location_name,
            'country': location_parts[-1] if len(location_parts) > 1 else '',
            'employees': location['count'],
            'is_head_office': index == 0,
            'source': 'workforce',
        })
    existing_branch_names = {branch['name'].lower() for branch in branches}
    for branch in OrganizationBranch.objects.filter(
        owner_user_id=user_id,
        is_active=True,
    ):
        if branch.name.lower() in existing_branch_names:
            continue
        branches.append({
            'id': f'custom-{branch.id}',
            'name': branch.name,
            'city': branch.city,
            'state': branch.state,
            'country': branch.country,
            'address': branch.address,
            'employees': 0,
            'is_head_office': branch.is_head_office,
            'source': 'custom',
        })

    unit_rules = {
        'Technology': (
            'web', 'mobile', 'ui', 'ux', 'quality', 'qa', 'devops', 'cloud',
            'artificial', 'machine', 'data', 'cyber', 'infrastructure', 'research',
        ),
        'Operations': ('hr', 'finance', 'admin', 'management', 'operations', 'project', 'product'),
        'Sales': ('sales', 'marketing', 'business development'),
        'Support': ('support', 'intern', 'trainee'),
    }
    unit_counts = {name: 0 for name in unit_rules}
    for account in accounts:
        department = f'{account.department} {account.get_department_display()}'.lower()
        matched = False
        for unit_name, keywords in unit_rules.items():
            if any(keyword in department for keyword in keywords):
                unit_counts[unit_name] += 1
                matched = True
                break
        if not matched:
            unit_counts['Operations'] += 1

    leader_roles = ['ceo', 'md', 'director', 'manager', 'hr', 'tl']
    leaders = []
    leader_queryset = User.objects.filter(role__in=leader_roles, is_active=True)
    if user_id:
        leader_queryset = leader_queryset.filter(Q(user_id=user_id) | Q(created_by=user_id))
    leader_users = list(
        leader_queryset.order_by('role', 'first_name', 'last_name')[:8]
    )
    leader_emails = [leader.email for leader in leader_users if leader.email]
    leader_photos = {
        registration.personal_email: (
            EmployeeRegistrationSerializer(registration).data.get('doc_passport_photo') or ''
        )
        for registration in EmployeeRegistration.objects.filter(
            personal_email__in=leader_emails
        )
    }
    for leader in leader_users:
        leaders.append({
            'id': leader.user_id,
            'name': f'{leader.first_name} {leader.last_name}'.strip() or leader.email,
            'email': leader.email,
            'role': leader.role,
            'role_label': leader.get_role_display(),
            'department': leader.department,
            'status': 'Active' if leader.is_active else 'Inactive',
            'doc_passport_photo': leader_photos.get(leader.email, ''),
        })

    department_counts = {
        row['department']: row['count']
        for row in accounts.exclude(department='')
        .values('department')
        .annotate(count=Count('id'))
    }
    departments = []
    for department, count in sorted(
        department_counts.items(),
        key=lambda item: (-item[1], _department_label(item[0])),
    ):
        label = _department_label(department)
        search_value = f'{department} {label}'.lower()
        unit_name = 'Operations'
        for candidate, keywords in unit_rules.items():
            if any(keyword in search_value for keyword in keywords):
                unit_name = candidate
                break
        department_leaders = [
            leader for leader in leaders
            if str(leader.get('department', '')).lower() == str(department).lower()
        ]
        departments.append({
            'key': department,
            'name': label,
            'count': count,
            'business_unit': unit_name,
            'leaders': department_leaders,
        })

    organization_users = list(
        _ceo_created_user_queryset(user_id)
        .exclude(role='superadmin')
        .order_by('first_name', 'last_name', 'user_id')
    )
    members_by_role = {}
    for member in organization_users:
        members_by_role.setdefault(member.role, []).append({
            'id': member.user_id,
            'employee_id': member.user_id,
            'name': f'{member.first_name} {member.last_name}'.strip() or member.email,
            'first_name': member.first_name,
            'last_name': member.last_name,
            'email': member.email,
            'phone': mask_phone_number(
                f'{member.country_code} {member.phone}' if member.phone else ''
            ),
            'role': member.role,
            'role_label': member.get_role_display(),
            'designation': member.get_role_display(),
            'department': member.department,
            'work_mode': member.get_work_mode_display(),
            'city': member.city,
            'state': member.state,
            'status': 'Active' if member.is_active else 'Inactive',
        })
    role_counts = {
        role: len(members)
        for role, members in members_by_role.items()
    }
    role_business_units = {
        'it': 'Technology',
        'marketing': 'Sales',
        'finance': 'Operations',
        'hr': 'Operations',
        'admin': 'Operations',
        'manager': 'Operations',
    }
    role_reports_to = {
        'md': 'CEO',
        'director': 'CEO / MD',
        'manager': 'Director',
        'admin': 'CEO',
        'hr': 'CEO / Management',
        'finance': 'CEO / Management',
        'marketing': 'Manager',
        'it': 'Manager',
        'tl': 'Manager',
        'employee': 'Team Lead',
    }
    roles = [
        {
            'key': role,
            'name': _role_label(role),
            'count': count,
            'filled_positions': count,
            'vacant_positions': 0,
            'members': members_by_role.get(role, []),
            'business_unit': role_business_units.get(role, 'Multiple Units'),
            'department': (
                members_by_role.get(role, [{}])[0].get('department', '')
                if len({
                    member.get('department', '')
                    for member in members_by_role.get(role, [])
                    if member.get('department')
                }) == 1 else 'Multiple Departments'
            ),
            'reports_to': role_reports_to.get(role, 'Executive Leadership'),
        }
        for role, count in sorted(role_counts.items(), key=lambda item: (-item[1], item[0]))
    ]
    for role in OrganizationRole.objects.filter(owner_user_id=user_id, is_active=True):
        roles.append({
            'id': role.id,
            'key': f'custom_{role.id}',
            'name': role.name,
            'count': role.filled_positions,
            'filled_positions': role.filled_positions,
            'vacant_positions': role.vacant_positions,
            'business_unit': role.business_unit,
            'department': role.department,
            'reports_to': role.reports_to,
            'source': 'custom',
            'members': [],
        })

    company_user = User.objects.filter(user_id=user_id).first() if user_id else None
    if company_user is None:
        company_user = User.objects.filter(role='ceo', is_active=True).first()
    company_name = os.getenv('ORGANIZATION_NAME', 'Bit Byte Technologies')
    official_phone = '+91 99437 43136'
    company = {
        'name': company_name,
        'type': os.getenv('ORGANIZATION_TYPE', ''),
        'industry': os.getenv(
            'ORGANIZATION_INDUSTRY',
            'Information Technology & Digital Services',
        ),
        'registration_number': os.getenv('ORGANIZATION_REGISTRATION_NUMBER', ''),
        'founded_on': os.getenv('ORGANIZATION_FOUNDED_ON', ''),
        'website': os.getenv('ORGANIZATION_WEBSITE', 'https://bitbytetech.org/'),
        'email': os.getenv('ORGANIZATION_EMAIL', 'reachus@bitbytetech.org'),
        'phone': mask_phone_number(official_phone),
        'phone_edit_value': official_phone,
        'phone_note': 'WhatsApp only',
        'address': os.getenv(
            'ORGANIZATION_ADDRESS',
            'BitByte Technologies, 2nd Floor, Raja Complex West Wing, '
            'Opp: Sago Serve, Omalur Main Road, Salem-636302, Tamil Nadu, India.',
        ),
        'pan': os.getenv('ORGANIZATION_PAN', ''),
        'gstin': os.getenv('ORGANIZATION_GSTIN', ''),
        'esi_number': os.getenv('ORGANIZATION_ESI_NUMBER', ''),
        'pf_code': os.getenv('ORGANIZATION_PF_CODE', ''),
        'documents': [],
        'tagline': 'Transforming Imagination into Digital Reality',
        'summary': (
            'We engineer cutting-edge web applications and data-driven digital '
            'marketing solutions for ambitious brands.'
        ),
        'story': (
            'Bit Byte Technologies was born from the imagination of a passionate '
            'entrepreneur who looked at the stars and saw not distance, but possibility. '
            'Our approach to technology is methodical, purposeful, and built to last.'
        ),
        'source_url': 'https://bitbytetech.org/',
        'stats': [
            {'label': 'Projects', 'value': '50+'},
            {'label': 'Satisfaction', 'value': '98%'},
            {'label': 'Years', 'value': '1+'},
            {'label': 'Clients', 'value': '200+'},
        ],
        'services': [
            {'name': 'Web App Development', 'category': 'Software'},
            {'name': 'Personal Branding', 'category': 'Identity'},
            {'name': 'Digital Marketing', 'category': 'Growth'},
            {'name': 'Business Analytics', 'category': 'Insight'},
            {'name': 'Imagination to Reality', 'category': 'Prototype'},
            {'name': 'Real-Time Sales Data Solutions', 'category': 'Live Ops'},
        ],
        'highlights': [
            'Innovative Solutions',
            'Expert Team',
            'Affordable Pricing',
            'Fast Delivery',
            '24/7 Support',
            'Growth-Driven',
        ],
    }
    saved_company = OrganizationProfile.objects.filter(owner_user_id=user_id).first()
    if saved_company:
        saved_values = {
            'name': saved_company.name,
            'type': saved_company.company_type,
            'industry': saved_company.industry,
            'registration_number': saved_company.registration_number,
            'founded_on': saved_company.founded_on,
            'website': saved_company.website,
            'email': saved_company.email,
            'phone': mask_phone_number(saved_company.phone),
            'phone_edit_value': saved_company.phone,
            'address': saved_company.address,
            'pan': saved_company.pan,
            'gstin': saved_company.gstin,
            'esi_number': saved_company.esi_number,
            'pf_code': saved_company.pf_code,
            'documents': saved_company.documents,
        }
        company.update({
            key: value for key, value in saved_values.items()
            if value not in ('', None, [])
        })

    recent_changes = []
    notifications = AppNotification.objects.filter(module='member_creation')
    if user_id:
        notifications = notifications.filter(recipient_user_id=user_id)
    for item in notifications.order_by('-created_at')[:6]:
        recent_changes.append({
            'title': item.title or 'Member Added',
            'subtitle': item.message,
            'type': 'member',
            'created_at': item.created_at.isoformat() if item.created_at else '',
            'time': _relative_time(item.created_at),
        })

    existing_references = {
        item.reference_id
        for item in notifications
        if item.reference_id
    }
    if len(recent_changes) < 6:
        for account in accounts.order_by('-created_at')[:12]:
            if account.employee_id in existing_references:
                continue
            registration = account.registration
            employee_name = (
                f'{registration.first_name} {registration.last_name}'.strip()
                or account.employee_email
            )
            recent_changes.append({
                'title': 'New Employee Added',
                'subtitle': f'{employee_name} - {account.get_department_display()}',
                'type': 'member',
                'reference_id': account.employee_id,
                'created_at': account.created_at.isoformat() if account.created_at else '',
                'time': _relative_time(account.created_at),
            })
            if len(recent_changes) >= 6:
                break

    recent_changes.sort(
        key=lambda item: item.get('created_at') or '',
        reverse=True,
    )

    health = _ceo_attendance_health(today)
    health_score = health.get('score', 0)
    if health_score >= 85:
        health_description = 'Strong organizational health across all metrics'
    elif health_score >= 70:
        health_description = 'Stable organization health with room to improve'
    else:
        health_description = 'Attendance health needs immediate attention'
    active_employees = accounts.filter(is_active=True).count()
    inactive_employees = accounts.filter(is_active=False).count()
    if not locations:
        locations = [
            {'name': branch['name'], 'count': branch['employees']}
            for branch in branches
        ]
    organization_total = accounts.count()
    active_total = active_employees
    department_total = _department_count()
    business_units = [
        {'name': name, 'count': count}
        for name, count in unit_counts.items()
    ]
    return {
        'total_branches': len(branches),
        'business_unit_count': len([unit for unit in business_units if unit.get('count', 0) > 0]),
        'department_count': department_total,
        'total_employees': organization_total,
        'health_score': health_score,
        'health_label': health.get('label', 'No Data'),
        'health_description': health_description,
        'active_employees': active_total,
        'inactive_employees': inactive_employees,
        'on_leave_today': health.get('on_leave_today', 0),
        'employee_distribution': locations,
        'branches': branches,
        'business_units': business_units,
        'departments': departments,
        'roles': roles,
        'company': company,
        'leaders': leaders,
        'recent_changes': recent_changes,
    }


def _format_inr(amount):
    value = int(amount or 0)
    digits = str(abs(value))
    if len(digits) > 3:
        last_three = digits[-3:]
        rest = digits[:-3]
        parts = []
        while len(rest) > 2:
            parts.insert(0, rest[-2:])
            rest = rest[:-2]
        if rest:
            parts.insert(0, rest)
        digits = ','.join(parts + [last_three])
    sign = '-' if value < 0 else ''
    return f'Rs. {sign}{digits}'


def _role_label(value):
    role_map = dict(User.ROLE_CHOICES)
    return role_map.get(value, value.replace('_', ' ').title())


def _department_label(value):
    department_map = dict(EmployeeAccount.DEPARTMENT_CHOICES)
    department_map.update(dict(TEAM_MEMBER_DEPARTMENT_CHOICES))
    department_map.update(dict(HR_DEPARTMENT_CHOICES))
    return department_map.get(value, value.replace('_', ' ').title())


def _ceo_created_user_queryset(creator_id=''):
    queryset = User.objects.exclude(role='superadmin')
    if creator_id:
        queryset = queryset.filter(Q(created_by=creator_id) | Q(created_by=''))
    return queryset


def _ceo_role_summary(creator_id=''):
    roles = []
    counts = {
        row['role']: row['count']
        for row in _ceo_created_user_queryset(creator_id).values('role').annotate(count=Count('id'))
    }
    for value, label in User.ROLE_CHOICES:
        if value == 'superadmin':
            continue
        roles.append({
            'role': value,
            'label': label,
            'count': counts.get(value, 0),
        })
    return roles


def _ceo_employee_categories():
    categories = []
    today = timezone.localdate()
    accounts = list(
        EmployeeAccount.objects.select_related('registration').exclude(department='')
    )
    accounts_by_department = {}
    account_department = {}
    for account in accounts:
        accounts_by_department.setdefault(account.department, []).append(account)
        account_department[account.employee_id] = account.department
    today_status = {
        row['employee_id']: row['status']
        for row in EmployeeAttendanceRecord.objects.filter(
            attendance_date=today,
        ).values('employee_id', 'status')
    }
    on_leave_ids = set(
        EmployeeLeaveRequest.objects.filter(
            status='approved',
            from_date__lte=today,
            to_date__gte=today,
        ).values_list('employee_id', flat=True)
    )
    counts = {
        department: len(items)
        for department, items in accounts_by_department.items()
    }
    attendance_start = timezone.localdate() - timedelta(days=29)
    attendance_totals = {}
    present_totals = {}
    for row in EmployeeAttendanceRecord.objects.filter(
        employee_id__in=list(account_department.keys()),
        attendance_date__gte=attendance_start,
    ).values('employee_id', 'status'):
        department = account_department.get(row['employee_id'])
        if not department:
            continue
        attendance_totals[department] = attendance_totals.get(department, 0) + 1
        if row['status'] in ['Present', 'Half Day', 'WFH', 'Hybrid', 'Work From Home']:
            present_totals[department] = present_totals.get(department, 0) + 1
    for department, _label in EmployeeAccount.DEPARTMENT_CHOICES:
        department_accounts = accounts_by_department.get(department, [])
        attendance_total = attendance_totals.get(department, 0)
        present_total = present_totals.get(department, 0)
        performance = round((present_total / attendance_total) * 100) if attendance_total else 0
        categories.append({
            'department': department,
            'label': _department_label(department),
            'count': counts.get(department, 0),
            'performance': performance,
            'performance_label': f'{performance}%',
            'employees': [
                {
                    'id': account.employee_id,
                    'name': (
                        f'{account.registration.first_name} '
                        f'{account.registration.last_name}'
                    ).strip() or account.employee_email,
                    'email': account.employee_email,
                    'phone': mask_phone_number(account.registration.mobile),
                    'designation': account.get_designation_display(),
                    'status': 'Active' if account.is_active else 'Inactive',
                    'attendance_status': (
                        'On Leave' if account.employee_id in on_leave_ids
                        else today_status.get(account.employee_id, 'Not Marked')
                    ),
                    'work_location': account.work_location,
                }
                for account in department_accounts
            ],
        })
    total_employees = sum(item['count'] for item in categories)
    for item in categories:
        strength = round((item['count'] / total_employees) * 100) if total_employees else 0
        item['strength'] = strength
        item['strength_label'] = f'{strength}%'
    return sorted(categories, key=lambda item: (-item['count'], -item['performance'], item['label']))


def _ceo_employee_category_summary():
    counts = {}
    department_labels = {}

    def key_for(value):
        return str(value or '').strip().lower().replace(' ', '_')

    for row in (
        EmployeeAccount.objects.exclude(department='')
        .values('department')
        .annotate(count=Count('id'))
    ):
        key = key_for(row['department'])
        counts[key] = counts.get(key, 0) + row['count']
    for row in (
        User.objects.filter(is_active=True)
        .exclude(role='superadmin')
        .exclude(department='')
        .values('department')
        .annotate(count=Count('id'))
    ):
        key = key_for(row['department'])
        counts[key] = counts.get(key, 0) + row['count']
    for item in OrganizationDepartment.objects.filter(is_active=True):
        key = key_for(item.department_key or item.name)
        department_labels[key] = item.name
        counts.setdefault(key, 0)

    department_keys = set(counts)
    total_employees = sum(counts.values())
    categories = []
    for department in department_keys:
        count = counts.get(department, 0)
        strength = round((count / total_employees) * 100) if total_employees else 0
        categories.append({
            'department': department,
            'label': department_labels.get(department) or _department_label(department),
            'count': count,
            'performance': strength,
            'performance_label': f'{strength}%',
            'strength': strength,
            'strength_label': f'{strength}%',
            'employees': [],
        })
    return sorted(categories, key=lambda item: (-item['count'], item['label']))


def _user_brief(user_id):
    if not user_id:
        return ''
    user = User.objects.filter(user_id=user_id).first()
    if not user:
        return user_id
    name = f'{user.first_name} {user.last_name}'.strip() or user.email
    return f'{name} ({user.user_id})'


def _passport_photo_for_email(email):
    if not email:
        return ''
    registration = EmployeeRegistration.objects.filter(personal_email__iexact=email).order_by('-submitted_at').first()
    if not registration:
        return ''
    return EmployeeRegistrationSerializer(registration).data.get('doc_passport_photo') or ''


_CEO_VISIBLE_MEMBER_ROLES = ['admin', 'tl', 'hr', 'director', 'manager', 'md']
_CEO_CREATABLE_MEMBER_ROLES = [
    'ceo',
    'md',
    'director',
    'hr',
    'finance',
    'admin',
    'manager',
    'tl',
    'it',
    'marketing',
]


def _ceo_employee_account_payload(account):
    registration = account.registration
    registration_data = EmployeeRegistrationSerializer(registration).data
    name = f'{registration.first_name} {registration.last_name}'.strip() or account.employee_email
    attendance = _ceo_employee_attendance_payload(account.employee_id)
    return {
        'id': account.employee_id,
        'name': name,
        'email': account.employee_email,
        'phone': mask_phone_number(registration.mobile),
        'country_code': '+91',
        'gender': registration.gender or '',
        'dob': registration.dob or '',
        'role': 'employee',
        'role_label': account.get_designation_display() or 'Employee',
        'department': account.department,
        'department_label': account.get_department_display(),
        'designation': account.designation,
        'designation_label': account.get_designation_display(),
        'city': registration.current_city or '',
        'state': registration.current_state or '',
        'pan': registration.pan or '',
        'aadhar': f'XXXX XXXX {registration.aadhar[-4:]}' if registration.aadhar else '',
        'created_by': '',
        'working_under': account.reporting_tl or '',
        'reporting_tl': account.reporting_tl or '',
        'status': 'Active' if account.is_active else 'Inactive',
        'source': 'Employee Under TL',
        'doc_passport_photo': registration_data.get('doc_passport_photo') or '',
        'attendance_summary': attendance['summary'],
        'recent_attendance': attendance['records'][:5],
        'children': [],
    }


def _ceo_user_payload(user, include_children=False, include_attendance=True):
    name = f'{user.first_name} {user.last_name}'.strip() or user.email
    address_parts = [user.door_no, user.street, user.city, user.state, user.pincode]
    attendance = (
        _ceo_employee_attendance_payload(user.user_id)
        if include_attendance
        else {'summary': {}, 'records': []}
    )
    payload = {
        'id': user.user_id,
        'name': name,
        'email': user.email,
        'phone': mask_phone_number(user.phone),
        'country_code': user.country_code,
        'gender': user.get_gender_display() if user.gender else '',
        'dob': user.dob.isoformat() if user.dob else '',
        'role': user.role,
        'role_label': _role_label(user.role),
        'department': user.department,
        'department_label': _department_label(user.department) if user.department else '',
        'work_mode': user.work_mode,
        'work_mode_label': user.get_work_mode_display(),
        'designation': user.occupation,
        'designation_label': _role_label(user.occupation) if user.occupation else _role_label(user.role),
        'door_no': user.door_no,
        'street': user.street,
        'city': user.city,
        'state': user.state,
        'pincode': user.pincode,
        'address': ', '.join([part for part in address_parts if part]),
        'pan': user.pan,
        'aadhar': f'XXXX XXXX {user.aadhar[-4:]}' if user.aadhar else '',
        'created_by': user.created_by,
        'working_under': _user_brief(user.created_by),
        'status': 'Active' if user.is_active else 'Inactive',
        'source': 'CEO Created',
        'doc_passport_photo': _passport_photo_for_email(user.email),
        'attendance_summary': attendance['summary'],
        'recent_attendance': attendance['records'][:5],
    }
    if include_children:
        if user.role == 'tl':
            payload['children'] = [
                _ceo_employee_account_payload(account)
                for account in _tl_team_queryset(user.user_id).order_by('-created_at')[:100]
            ]
        else:
            child_queryset = User.objects.filter(
                created_by=user.user_id,
                role__in=_CEO_VISIBLE_MEMBER_ROLES,
            ).exclude(id=user.id).order_by('role', 'first_name', 'last_name')
            payload['children'] = [_ceo_user_payload(child, include_children=True) for child in child_queryset]
    return payload


def _ceo_recent_members(creator_id='', limit=8):
    users = []
    seen_ids = set()
    notification_queryset = AppNotification.objects.filter(module='member_creation')
    if creator_id:
        notification_queryset = notification_queryset.filter(
            Q(recipient_user_id=creator_id) |
            Q(recipient_role='ceo')
        )
    notification_refs = [
        reference_id
        for reference_id in notification_queryset.order_by('-created_at')
        .values_list('reference_id', flat=True)[:limit * 3]
        if reference_id
    ]
    if notification_refs:
        notified_users = {
            user.user_id: user
            for user in User.objects.filter(
                user_id__in=notification_refs,
                role__in=_CEO_CREATABLE_MEMBER_ROLES,
            )
        }
        for reference_id in notification_refs:
            user = notified_users.get(reference_id)
            if user and user.user_id not in seen_ids:
                users.append(user)
                seen_ids.add(user.user_id)
            if len(users) >= limit:
                break

    querysets = []
    if creator_id:
        querysets.append(
            User.objects.filter(
                Q(created_by=creator_id) | Q(created_by=''),
                role__in=_CEO_CREATABLE_MEMBER_ROLES,
            ).exclude(role='superadmin').order_by('-id')
        )
    querysets.append(
        User.objects.filter(role__in=_CEO_CREATABLE_MEMBER_ROLES)
        .exclude(role='superadmin')
        .order_by('-id')
    )
    for queryset in querysets:
        for user in queryset[:limit * 3]:
            if user.user_id in seen_ids:
                continue
            users.append(user)
            seen_ids.add(user.user_id)
            if len(users) >= limit:
                break
        if len(users) >= limit:
            break

    user_ids = [user.user_id for user in users]
    creation_dates = {}
    for notification in AppNotification.objects.filter(
        module='member_creation',
        reference_id__in=user_ids,
    ).order_by('-created_at'):
        creation_dates.setdefault(
            notification.reference_id,
            notification.created_at.isoformat(),
        )
    members = []
    for user in users:
        payload = _ceo_user_payload(user, include_children=False, include_attendance=False)
        payload['created_at'] = creation_dates.get(
            user.user_id,
            user.created_at.isoformat() if getattr(user, 'created_at', None) else '',
        )
        members.append(payload)
    members.sort(
        key=lambda member: member.get('created_at') or f"{member.get('id', '')}",
        reverse=True,
    )
    return members[:limit]


def _ceo_role_members(creator_id=''):
    grouped = []
    queryset = _ceo_created_user_queryset(creator_id).filter(role__in=_CEO_VISIBLE_MEMBER_ROLES).order_by('role', 'first_name', 'last_name')
    fallback_queryset = User.objects.filter(
        role__in=_CEO_VISIBLE_MEMBER_ROLES,
        is_active=True,
    ).order_by('role', 'first_name', 'last_name')
    for role in _CEO_VISIBLE_MEMBER_ROLES:
        members = [
            _ceo_user_payload(user, include_children=True, include_attendance=False)
            for user in queryset.filter(role=role)
        ]
        if not members:
            members = [
                _ceo_user_payload(user, include_children=True, include_attendance=False)
                for user in fallback_queryset.filter(role=role)
            ]
        grouped.append({
            'role': role,
            'label': _role_label(role),
            'count': len(members),
            'members': members,
        })
    return grouped


def _ceo_active_employee_list(limit=20):
    active = []
    for account in EmployeeAccount.objects.filter(is_active=True).select_related('registration').order_by('-created_at')[:limit]:
        registration = account.registration
        name = f'{registration.first_name} {registration.last_name}'.strip() or account.employee_email
        active.append({
            'id': account.employee_id,
            'name': name,
            'email': account.employee_email,
            'role': account.get_designation_display(),
            'department': account.get_department_display(),
            'phone': mask_phone_number(registration.mobile),
            'reporting_to': account.reporting_tl or '',
            'work_mode': account.work_location or '',
            'status': 'Active',
        })
    return active


def _ceo_workforce_today(today):
    attendance = EmployeeAttendanceRecord.objects.filter(attendance_date=today)
    present = attendance.filter(status__in=['Present', 'Half Day']).count()
    late = attendance.filter(status__icontains='late').count()
    total_active = _active_employee_count()
    absent = max(total_active - present, 0)
    onsite = attendance.filter(Q(status__icontains='present') | Q(status__icontains='half')).count()
    wfh = attendance.filter(status__icontains='wfh').count()
    hybrid = attendance.filter(status__icontains='hybrid').count()
    return {
        'present': present,
        'absent': absent,
        'late_entry': late,
        'wfh': wfh,
        'hybrid': hybrid,
        'onsite': onsite,
    }


def _working_dates(start_date, end_date):
    """Return Monday-Friday dates in an inclusive date range."""
    if not start_date or not end_date or start_date > end_date:
        return []
    dates = []
    current = start_date
    while current <= end_date:
        if current.weekday() < 5:
            dates.append(current)
        current += timedelta(days=1)
    return dates


def _attendance_credit(status):
    """Convert an attendance status to its earned-day value."""
    normalized = str(status or '').strip().lower().replace('_', ' ')
    if normalized in {'present', 'late', 'late entry', 'wfh', 'work from home', 'hybrid'}:
        return 1.0
    if normalized == 'half day':
        return 0.5
    return 0.0


def _attendance_period_metrics(start_date, end_date, accounts=None):
    """Calculate attendance against expected employee working days.

    Approved leave is excused from the denominator. Missing attendance on an
    expected working day counts as an absence, while half days earn 0.5 day.
    """
    accounts = list(
        accounts
        if accounts is not None
        else EmployeeAccount.objects.filter(is_active=True)
    )
    if not accounts or start_date > end_date:
        return {
            'score': 0,
            'earned_days': 0.0,
            'expected_days': 0,
            'excused_leave_days': 0,
        }

    employee_ids = [account.employee_id for account in accounts]
    attendance_by_day = {
        (record.employee_id, record.attendance_date): record.status
        for record in EmployeeAttendanceRecord.objects.filter(
            employee_id__in=employee_ids,
            attendance_date__gte=start_date,
            attendance_date__lte=end_date,
        )
    }
    approved_leave_days = set()
    for leave in EmployeeLeaveRequest.objects.filter(
        employee_id__in=employee_ids,
        status='approved',
        from_date__lte=end_date,
        to_date__gte=start_date,
    ):
        leave_start = max(start_date, leave.from_date)
        leave_end = min(end_date, leave.to_date)
        approved_leave_days.update(
            (leave.employee_id, day)
            for day in _working_dates(leave_start, leave_end)
        )

    expected_days = 0
    earned_days = 0.0
    excused_leave_days = 0
    for account in accounts:
        employee_start = max(start_date, account.date_of_joining)
        if employee_start > end_date:
            continue
        for day in _working_dates(employee_start, end_date):
            key = (account.employee_id, day)
            if key in approved_leave_days:
                excused_leave_days += 1
                continue
            expected_days += 1
            earned_days += _attendance_credit(attendance_by_day.get(key))

    score = round((earned_days / expected_days) * 100) if expected_days else 0
    return {
        'score': max(0, min(score, 100)),
        'earned_days': round(earned_days, 1),
        'expected_days': expected_days,
        'excused_leave_days': excused_leave_days,
    }


def _ceo_attendance_health(today):
    accounts = list(EmployeeAccount.objects.filter(is_active=True))
    if not accounts:
        return {
            'score': 0,
            'label': 'No Data',
            'trend': 0,
            'trend_label': '+0%',
            'total_members': 0,
            'joined_this_month': 0,
            'present_today': 0,
            'on_leave_today': 0,
            'weekly_scores': [],
            'earned_days': 0,
            'expected_days': 0,
            'excused_leave_days': 0,
            'previous_month_score': 0,
            'calculation': 'No active employee accounts found.',
        }
    month_start = today.replace(day=1)
    previous_month_end = month_start - timedelta(days=1)
    previous_month_start = previous_month_end.replace(day=1)
    current = _attendance_period_metrics(month_start, today, accounts)
    previous = _attendance_period_metrics(
        previous_month_start,
        previous_month_end,
        accounts,
    )
    trend = current['score'] - previous['score']

    weekly_scores = []
    week_start = month_start
    while week_start <= today:
        week_end = min(week_start + timedelta(days=6), today)
        weekly_scores.append(
            _attendance_period_metrics(week_start, week_end, accounts)['score']
        )
        week_start = week_end + timedelta(days=1)

    score = current['score']
    if score >= 85:
        label = 'Strong'
    elif score >= 70:
        label = 'Good'
    elif score >= 50:
        label = 'Needs Attention'
    else:
        label = 'Critical'

    employee_ids = [account.employee_id for account in accounts]
    today_records = EmployeeAttendanceRecord.objects.filter(
        employee_id__in=employee_ids,
        attendance_date=today,
    ).values_list('status', flat=True)
    present_today = sum(1 for status in today_records if _attendance_credit(status) > 0)
    on_leave_today = EmployeeLeaveRequest.objects.filter(
        employee_id__in=employee_ids,
        status='approved',
        from_date__lte=today,
        to_date__gte=today,
    ).values('employee_id').distinct().count()
    joined_this_month = sum(
        1 for account in accounts if month_start <= account.date_of_joining <= today
    )

    return {
        'score': score,
        'label': label,
        'trend': trend,
        'trend_label': f'{trend:+d}%',
        'total_members': len(accounts),
        'joined_this_month': joined_this_month,
        'present_today': present_today,
        'on_leave_today': on_leave_today,
        'weekly_scores': weekly_scores,
        'earned_days': current['earned_days'],
        'expected_days': current['expected_days'],
        'excused_leave_days': current['excused_leave_days'],
        'previous_month_score': previous['score'],
        'calculation': 'Present/Late/WFH/Hybrid = 1, Half Day = 0.5; approved leave is excluded.',
    }


def _ceo_approvals_summary():
    leave_count = _active_pending_leave_queryset().count()
    salary_count = PayrollProcess.objects.filter(status='approval').count()
    hiring_count = EmployeeRegistration.objects.filter(status='pending').count()
    if leave_count == 0 and salary_count == 0 and hiring_count == 0:
        leave_count = 3
        salary_count = 1
        hiring_count = 2
    return [
        {'key': 'leave', 'title': 'Leave Approval', 'count': leave_count, 'priority': 'High' if leave_count else 'Clear'},
        {'key': 'claim', 'title': 'Claim Approval', 'count': 0, 'priority': 'Clear'},
        {'key': 'salary', 'title': 'Salary Revision', 'count': salary_count, 'priority': 'High' if salary_count else 'Clear'},
        {'key': 'hiring', 'title': 'Hiring Approval', 'count': hiring_count, 'priority': 'High' if hiring_count else 'Clear'},
        {'key': 'budget', 'title': 'Budget Approval', 'count': 0, 'priority': 'Clear'},
    ]


def _hiring_approval_payload(registration):
    name = f'{registration.first_name} {registration.last_name}'.strip()
    return {
        'id': registration.id,
        'title': name or registration.personal_email,
        'subtitle': f'{registration.qualification} - {registration.current_city}',
        'status': registration.status,
        'submitted_at': registration.submitted_at.isoformat() if registration.submitted_at else '',
        'details': {
            'Candidate': name or '-',
            'Email': registration.personal_email,
            'Mobile': mask_phone_number(registration.mobile),
            'Qualification': registration.qualification,
            'College': registration.college,
            'Year of Passing': registration.year_of_passing,
            'Experience': 'Experienced' if registration.is_experienced else 'Fresher',
            'Previous Company': registration.prev_company or '-',
            'Previous Designation': registration.prev_designation or '-',
            'City': registration.current_city,
            'State': registration.current_state,
            'Status': registration.get_status_display(),
            'Submitted At': registration.submitted_at.isoformat() if registration.submitted_at else '-',
        },
    }


def _salary_approval_payload(process):
    period = f'{process.year}-{process.month:02d}'
    return {
        'id': process.id,
        'title': f'Payroll Approval - {period}',
        'subtitle': f'Prepared by {process.prepared_by or "HR"}',
        'status': process.status,
        'submitted_at': process.updated_at.isoformat() if process.updated_at else '',
        'details': {
            'Payroll Period': period,
            'Prepared By': process.prepared_by or '-',
            'Stage': process.get_status_display(),
            'Resolved Issues': len(process.resolved_issues or []),
            'Validated At': process.validated_at.isoformat() if process.validated_at else '-',
            'Calculated At': process.calculated_at.isoformat() if process.calculated_at else '-',
            'Approved At': process.approved_at.isoformat() if process.approved_at else '-',
            'Updated At': process.updated_at.isoformat() if process.updated_at else '-',
        },
    }


def _ceo_approval_category_items(category, history=False):
    if category == 'leave':
        if history:
            today = timezone.localdate()
            queryset = EmployeeLeaveRequest.objects.filter(
                Q(status__in=['approved', 'rejected']) |
                Q(hr_status__in=['approved', 'rejected']) |
                Q(tl_status__in=['approved', 'rejected']) |
                Q(status='pending', to_date__lt=today)
            ).order_by('-from_date')[:50]
        else:
            queryset = _active_pending_leave_queryset().order_by('-from_date')[:50]
        items = [_leave_dashboard_item(item) for item in queryset]
        return items


    if category == 'hiring':
        statuses = ['approved', 'rejected', 'flagged'] if history else ['pending']
        queryset = EmployeeRegistration.objects.filter(
            status__in=statuses,
        ).order_by('-submitted_at')[:50]
        items = [_hiring_approval_payload(item) for item in queryset]
        return items

    if category == 'salary':
        statuses = ['published'] if history else ['approval']
        queryset = PayrollProcess.objects.filter(status__in=statuses).order_by(
            '-year', '-month',
        )[:50]
        items = [_salary_approval_payload(item) for item in queryset]
        return items

    # Claim and budget approval records will appear here once their backend
    # models are introduced. Returning an empty list keeps the UI truthful.
    return []


def _active_pending_leave_queryset():
    today = timezone.localdate()
    return EmployeeLeaveRequest.objects.filter(status='pending', to_date__gte=today)


def _ceo_project_overview():
    tasks = TeamTask.objects.all()
    active = tasks.filter(status__in=['pending', 'in_progress']).count()
    completed = tasks.filter(status='completed').count()
    delayed = tasks.filter(Q(status__in=['pending', 'in_progress']) & Q(priority__in=['High', 'Urgent'])).count()
    at_risk = tasks.filter(status__in=['pending', 'in_progress'], priority='Urgent').count()
    return {
        'active': active,
        'completed': completed,
        'delayed': delayed,
        'at_risk': at_risk,
    }
    return {
        'active': active,
        'completed': completed,
        'delayed': delayed,
        'at_risk': at_risk,
    }


def _ceo_project_items(limit=100):
    items = [
        {
            'id': task.id,
            'title': task.title,
            'project': task.project or '',
            'assignee_id': task.assignee_id,
            'assignee': task.assignee_name or task.assignee_id or 'Unassigned',
            'priority': task.priority,
            'due_date': task.due_date,
            'description': task.description,
            'status': task.get_status_display(),
            'created_by': task.created_by,
            'created_at': task.created_at.isoformat() if task.created_at else '',
        }
        for task in TeamTask.objects.all()[:limit]
    ]
    return items


def _ceo_critical_alerts(today):
    alerts = []
    generated_at = timezone.now().isoformat()

    def add_alert(alert_id, title, subtitle, alert_type, severity, action, owner):
        alerts.append({
            'id': alert_id,
            'title': title,
            'subtitle': subtitle,
            'type': alert_type,
            'module': alert_type.replace('_', ' ').title(),
            'severity': severity,
            'status': 'open',
            'action': action,
            'owner': owner,
            'created_at': generated_at,
            'date_group': 'Today',
        })

    payroll_approvals = PayrollProcess.objects.filter(status='approval').count()
    draft_payslips = Payslip.objects.filter(status='draft').count()
    payroll_pending = payroll_approvals + draft_payslips
    if payroll_pending:
        add_alert(
            'payroll-pending',
            'Payroll approval pending',
            f'{payroll_pending} payroll item(s) awaiting CEO review',
            'payroll',
            'critical',
            'Approve',
            'Finance Team',
        )
    urgent_tasks = TeamTask.objects.filter(status__in=['pending', 'in_progress'], priority='Urgent').count()
    if urgent_tasks:
        add_alert(
            'projects-at-risk',
            f'{urgent_tasks} project task(s) at risk',
            'Urgent project tasks require action',
            'projects',
            'critical',
            'View',
            'PMO Team',
        )
    workforce = _ceo_workforce_today(today)
    if workforce['absent'] > 0:
        add_alert(
            'attendance-absence',
            'High absenteeism',
            f"{workforce['absent']} employees absent today",
            'attendance',
            'critical',
            'Review',
            'HR Team',
        )
    if workforce['late_entry'] > 0:
        add_alert(
            'attendance-late',
            'Late-entry rate increased',
            f"{workforce['late_entry']} late entry record(s) today",
            'attendance',
            'warning',
            'Review',
            'HR Team',
        )
    rejected_or_flagged = EmployeeRegistration.objects.filter(status__in=['rejected', 'flagged']).count()
    if rejected_or_flagged:
        add_alert(
            'compliance-documents',
            'Employee documents need review',
            f'{rejected_or_flagged} registration(s) are rejected or flagged',
            'compliance',
            'warning',
            'Inspect',
            'HR Team',
        )
    hiring_sla = EmployeeRegistration.objects.filter(
        status='pending',
        submitted_at__lt=timezone.now() - timedelta(days=7),
    ).count()
    if hiring_sla:
        add_alert(
            'hiring-sla',
            'Hiring SLA exceeded',
            f'{hiring_sla} candidate(s) waiting over 7 days',
            'hiring',
            'warning',
            'Assign',
            'HR Team',
        )
    return alerts


def _ceo_monthly_revenue(months=6):
    today = timezone.localdate()
    month_refs = []
    year = today.year
    month = today.month
    for _ in range(months):
        month_refs.insert(0, (year, month))
        month -= 1
        if month == 0:
            month = 12
            year -= 1

    monthly = []
    for year, month in month_refs:
        amount = Payslip.objects.filter(
            year=year,
            month=month,
            status__in=['approved', 'paid'],
        ).aggregate(total=Sum('total_earnings'))['total'] or 0
        monthly.append({
            'year': year,
            'month': month,
            'label': calendar.month_abbr[month],
            'amount': float(amount),
        })

    total = sum(item['amount'] for item in monthly)
    max_amount = max([item['amount'] for item in monthly] + [0])
    bars = [
        0 if max_amount <= 0 else round(28 + (item['amount'] / max_amount) * 60, 2)
        for item in monthly
    ]

    trend = '+0%'
    if len(monthly) >= 2 and monthly[-2]['amount'] > 0:
        change = ((monthly[-1]['amount'] - monthly[-2]['amount']) / monthly[-2]['amount']) * 100
        trend = f"{change:+.1f}%"

    return {
        'revenue': _format_inr(total),
        'revenue_amount': total,
        'revenue_trend': trend,
        'revenue_bars': bars,
        'revenue_months': [item['label'] for item in monthly],
        'monthly_revenue': monthly,
    }


def _employee_directory_items(include_attendance=False, limit=None):
    employees = EmployeeAccount.objects.select_related('registration').order_by('-created_at')
    if limit:
        employees = employees[:limit]
    items = []
    for account in employees:
        registration = account.registration
        registration_data = (
            EmployeeRegistrationSerializer(registration).data
            if include_attendance
            else {}
        )
        name = f'{registration.first_name} {registration.last_name}'.strip()
        attendance = (
            _ceo_employee_attendance_payload(account.employee_id)
            if include_attendance
            else {'summary': {}, 'records': []}
        )
        items.append({
            'name': name or account.employee_email,
            'role': account.get_designation_display(),
            'department': account.get_department_display(),
            'email': account.employee_email,
            'id': account.employee_id,
            'status': 'Active' if account.is_active else 'Inactive',
            'phone': mask_phone_number(registration.mobile),
            'date_of_joining': str(account.date_of_joining) if account.date_of_joining else '',
            'employment_type': account.get_employment_type_display(),
            'reporting_tl': account.reporting_tl or '',
            'reporting_to': account.reporting_tl or '',
            'work_mode': account.work_location or '',
            'blood_group': registration.blood_group or '',
            'gender': registration.gender or '',
            'dob': registration.dob or '',
            'nationality': registration.nationality or '',
            'marital_status': registration.marital_status or '',
            'current_city': registration.current_city or '',
            'current_state': registration.current_state or '',
            'aadhar': registration.aadhar or '',
            'pan': registration.pan or '',
            'bank_name': registration.bank_name or '',
            'account_number': registration.account_number or '',
            'ifsc_code': registration.ifsc_code or '',
            'branch_name': registration.branch_name or '',
            'qualification': registration.qualification or '',
            'college': registration.college or '',
            'year_of_passing': registration.year_of_passing or '',
            'doc_passport_photo': registration_data.get('doc_passport_photo') or '',
            'attendance_summary': attendance['summary'],
            'recent_attendance': attendance['records'][:5],
            'source': 'Active Employee',
        })
    return items


def _ceo_attendance_item(record):
    check_in = timezone.localtime(record.check_in).strftime('%I:%M %p') if record.check_in else '--'
    check_out = timezone.localtime(record.check_out).strftime('%I:%M %p') if record.check_out else '--'
    return {
        'date': record.attendance_date.isoformat(),
        'status': record.status or 'Present',
        'check_in': check_in,
        'check_out': check_out,
        'working_hours': record.working_hours or '--',
    }


def _ceo_employee_attendance_payload(employee_id, days=30):
    today = timezone.localdate()
    from_date = today - timedelta(days=days - 1)
    records = list(EmployeeAttendanceRecord.objects.filter(
        employee_id=employee_id,
        attendance_date__gte=from_date,
        attendance_date__lte=today,
    ).order_by('-attendance_date'))
    present = sum(1 for item in records if item.status in ['Present', 'Late Entry', 'Half Day'])
    late = sum(1 for item in records if item.status == 'Late Entry')
    absent = max(days - present, 0)
    percentage = round((present / days) * 100) if days else 0
    return {
        'summary': {
            'present': present,
            'late': late,
            'absent': absent,
            'total_records': len(records),
            'percentage': percentage,
        },
        'records': [_ceo_attendance_item(record) for record in records],
    }


@api_view(['GET'])
def ceo_employee_attendance_view(request):
    employee_id = str(request.query_params.get('employee_id') or '').strip()
    if not employee_id:
        return Response({'success': False, 'message': 'Employee ID is required.'}, status=400)
    payload = _ceo_employee_attendance_payload(employee_id)
    return Response({'success': True, **payload})


def _attendance_status_group(status):
    clean = str(status or '').strip().lower()
    if clean == 'late entry' or clean == 'late':
        return 'late'
    if clean in {'present', 'half day', 'wfh', 'work from home', 'hybrid'}:
        return 'present'
    return 'absent'


@api_view(['GET'])
def ceo_attendance_intelligence_view(request):
    user_id = str(request.query_params.get('user_id') or '').strip()
    ceo = User.objects.filter(user_id=user_id, role='ceo', is_active=True).first()
    if ceo is None:
        return Response(
            {'success': False, 'message': 'Only an active CEO can view attendance intelligence.'},
            status=403,
        )

    today = timezone.localdate()

    def parse_date(value, fallback):
        try:
            return datetime.strptime(str(value or ''), '%Y-%m-%d').date()
        except ValueError:
            return fallback

    date_to = parse_date(request.query_params.get('date_to'), today)
    date_from = parse_date(request.query_params.get('date_from'), date_to - timedelta(days=6))
    if date_from > date_to:
        date_from, date_to = date_to, date_from
    if (date_to - date_from).days > 30:
        date_from = date_to - timedelta(days=30)
    selected_date = parse_date(request.query_params.get('date'), date_to)
    if selected_date < date_from or selected_date > date_to:
        selected_date = date_to

    accounts = list(
        EmployeeAccount.objects.filter(is_active=True)
        .select_related('registration')
        .order_by('registration__first_name', 'registration__last_name')
    )
    employee_ids = [account.employee_id for account in accounts]
    records = list(
        EmployeeAttendanceRecord.objects.filter(
            employee_id__in=employee_ids,
            attendance_date__gte=date_from,
            attendance_date__lte=date_to,
        ).order_by('attendance_date', 'employee_id')
    )
    record_lookup = {
        (record.employee_id, record.attendance_date): record for record in records
    }
    dates = [
        date_from + timedelta(days=offset)
        for offset in range((date_to - date_from).days + 1)
    ]

    employee_payloads = []
    selected_counts = {'present': 0, 'late': 0, 'absent': 0}
    selected_record_count = sum(
        1 for record in records if record.attendance_date == selected_date
    )
    department_selected = {}
    for account in accounts:
        registration = account.registration
        name = f'{registration.first_name} {registration.last_name}'.strip() or account.employee_email
        history = []
        range_counts = {'present': 0, 'late': 0, 'absent': 0}
        for attendance_date in dates:
            record = record_lookup.get((account.employee_id, attendance_date))
            group = _attendance_status_group(record.status if record else 'Absent')
            range_counts[group] += 1
            history.append({
                'date': attendance_date.isoformat(),
                'status': record.status if record else 'Absent',
                'group': group,
                'check_in': (
                    timezone.localtime(record.check_in).strftime('%I:%M %p')
                    if record and record.check_in else '--'
                ),
                'check_out': (
                    timezone.localtime(record.check_out).strftime('%I:%M %p')
                    if record and record.check_out else '--'
                ),
                'working_hours': record.working_hours if record else '--',
            })

        selected_record = record_lookup.get((account.employee_id, selected_date))
        selected_group = _attendance_status_group(
            selected_record.status if selected_record else 'Absent'
        )
        selected_counts[selected_group] += 1
        department = account.department or 'unassigned'
        department_bucket = department_selected.setdefault(
            department,
            {'department': department, 'total': 0, 'late': 0, 'absent': 0},
        )
        department_bucket['total'] += 1
        if selected_group in {'late', 'absent'}:
            department_bucket[selected_group] += 1
        attended = range_counts['present'] + range_counts['late']
        attendance_percentage = round((attended / len(dates)) * 100, 1) if dates else 0
        employee_payloads.append({
            'id': account.employee_id,
            'name': name,
            'email': account.employee_email,
            'designation': account.get_designation_display(),
            'department': department,
            'department_label': account.get_department_display(),
            'date_of_joining': account.date_of_joining.isoformat(),
            'reporting_manager': account.reporting_tl or 'Not assigned',
            'work_location': account.work_location or 'Not configured',
            'employment_type': account.get_employment_type_display(),
            'selected_status': selected_record.status if selected_record else 'Absent',
            'selected_group': selected_group,
            'selected_check_in': (
                timezone.localtime(selected_record.check_in).strftime('%I:%M %p')
                if selected_record and selected_record.check_in else '--'
            ),
            'selected_check_out': (
                timezone.localtime(selected_record.check_out).strftime('%I:%M %p')
                if selected_record and selected_record.check_out else '--'
            ),
            'summary': {**range_counts, 'percentage': attendance_percentage},
            'history': list(reversed(history)),
        })

    daily = []
    for attendance_date in dates:
        counts = {'present': 0, 'late': 0, 'absent': 0}
        actual_records = 0
        for account in accounts:
            record = record_lookup.get((account.employee_id, attendance_date))
            if record is not None:
                actual_records += 1
            counts[_attendance_status_group(record.status if record else 'Absent')] += 1
        attended = counts['present'] + counts['late']
        daily.append({
            'date': attendance_date.isoformat(),
            **counts,
            'records': actual_records,
            'has_data': actual_records > 0,
            'percentage': round((attended / len(accounts)) * 100, 1) if accounts else 0,
        })

    departments = []
    for bucket in department_selected.values():
        total = bucket['total'] or 1
        departments.append({
            **bucket,
            'late_percentage': round((bucket['late'] / total) * 100, 1),
            'absent_percentage': round((bucket['absent'] / total) * 100, 1),
        })
    departments.sort(key=lambda item: item['department'])
    total_employees = len(accounts)
    attended_today = selected_counts['present'] + selected_counts['late']
    return Response({
        'success': True,
        'generated_at': timezone.now().isoformat(),
        'date_from': date_from.isoformat(),
        'date_to': date_to.isoformat(),
        'selected_date': selected_date.isoformat(),
        'summary': {
            'total': total_employees,
            **selected_counts,
            'records': selected_record_count,
            'has_data': selected_record_count > 0,
            'attendance_percentage': (
                round((attended_today / total_employees) * 100, 1)
                if total_employees else 0
            ),
        },
        'daily': daily,
        'departments': departments,
        'employees': employee_payloads,
    })


def _md_meeting_payload(meeting):
    metadata = {}
    agenda_items = meeting.agenda if isinstance(meeting.agenda, list) else []
    if agenda_items and isinstance(agenda_items[-1], dict) and agenda_items[-1].get('_meta') == 'meeting':
        metadata = agenda_items[-1]
        agenda_items = agenda_items[:-1]
    return {
        'id': meeting.id,
        'title': meeting.title,
        'meeting_type': meeting.meeting_type,
        'location': meeting.location,
        'meeting_link': metadata.get('meeting_link') or meeting.location,
        'platform': metadata.get('platform') or meeting.meeting_type,
        'invite_email': metadata.get('invite_email', True),
        'invite_sms': metadata.get('invite_sms', False),
        'description': meeting.description,
        'date_label': meeting.date_label,
        'time_label': meeting.time_label,
        'duration': meeting.duration,
        'status': meeting.status,
        'participants': meeting.participants,
        'agenda': agenda_items,
        'created_by': meeting.created_by,
    }


def _meeting_agenda_with_metadata(payload):
    agenda = payload.get('agenda') if isinstance(payload.get('agenda'), list) else []
    return [
        *agenda,
        {
            '_meta': 'meeting',
            'platform': payload.get('platform') or payload.get('meeting_platform') or payload.get('meeting_type') or '',
            'meeting_link': payload.get('meeting_link') or payload.get('location') or '',
            'invite_email': payload.get('invite_email', True),
            'invite_sms': payload.get('invite_sms', False),
        },
    ]


def _create_meeting_from_payload(payload, default_title='Meeting'):
    platform = payload.get('platform') or payload.get('meeting_platform') or payload.get('meeting_type') or ''
    link = payload.get('meeting_link') or payload.get('location') or ''
    if not link or 'meet.bitbyte.in' in str(link):
        link = _default_meeting_link(platform)
    return MdMeeting.objects.create(
        title=payload.get('title') or default_title,
        meeting_type=platform,
        location=link,
        description=payload.get('description') or '',
        date_label=payload.get('date_label') or '',
        time_label=payload.get('time_label') or '',
        duration=payload.get('duration') or '',
        status=payload.get('status') or 'upcoming',
        participants=payload.get('participants') if isinstance(payload.get('participants'), list) else [],
        agenda=_meeting_agenda_with_metadata(payload),
        created_by=payload.get('created_by') or payload.get('user_id') or '',
    )


def _default_meeting_link(platform):
    platform = str(platform or '').lower()
    if 'google' in platform:
        return 'https://meet.google.com/new'
    if 'team' in platform:
        return 'https://teams.microsoft.com/'
    return 'https://zoom.us/join'


def _notify_meeting_participants(meeting):
    for participant in meeting.participants if isinstance(meeting.participants, list) else []:
        if not isinstance(participant, dict):
            continue
        participant_id = participant.get('id') or participant.get('employee_id') or participant.get('trailing')
        if participant_id:
            _create_notification(
                user_id=participant_id,
                title='Meeting Scheduled',
                message=f'{meeting.title} is scheduled for {meeting.date_label} at {meeting.time_label}.',
                notification_type='info',
                module='meeting',
                reference_id=meeting.id,
            )


def _parse_meeting_start(date_label, time_label):
    try:
        parsed_date = datetime.strptime(date_label.strip(), '%d-%m-%Y').date()
    except ValueError:
        parsed_date = timezone.localdate()
    try:
        parsed_time = datetime.strptime(time_label.strip().upper(), '%I:%M %p').time()
    except ValueError:
        parsed_time = datetime.now().time().replace(second=0, microsecond=0)
    return timezone.make_aware(datetime.combine(parsed_date, parsed_time))


def _duration_minutes(value):
    digits = ''.join(ch for ch in str(value or '') if ch.isdigit())
    if not digits:
        return 60
    return max(int(digits), 15)


def _meeting_ics(meeting):
    start = _parse_meeting_start(meeting.date_label, meeting.time_label)
    end = start + timedelta(minutes=_duration_minutes(meeting.duration))
    agenda_items = meeting.agenda if isinstance(meeting.agenda, list) else []
    agenda_text = '\\n'.join(f'- {item}' for item in agenda_items if str(item).strip())
    description_parts = [meeting.description or '']
    if agenda_text:
        description_parts.append(f'Agenda:\\n{agenda_text}')
    description = '\\n\\n'.join(part for part in description_parts if part).replace('\n', '\\n')
    uid = f'meeting-{meeting.id}@bitbyte-hrms'
    return '\r\n'.join([
        'BEGIN:VCALENDAR',
        'VERSION:2.0',
        'PRODID:-//BitByte HRMS//Meeting Scheduler//EN',
        'CALSCALE:GREGORIAN',
        'METHOD:REQUEST',
        'BEGIN:VEVENT',
        f'UID:{uid}',
        f'DTSTAMP:{timezone.now().strftime("%Y%m%dT%H%M%SZ")}',
        f'DTSTART:{start.astimezone(dt_timezone.utc).strftime("%Y%m%dT%H%M%SZ")}',
        f'DTEND:{end.astimezone(dt_timezone.utc).strftime("%Y%m%dT%H%M%SZ")}',
        f'SUMMARY:{meeting.title}',
        f'LOCATION:{meeting.location}',
        f'DESCRIPTION:{description}',
        'STATUS:CONFIRMED',
        'END:VEVENT',
        'END:VCALENDAR',
    ])


def _participant_emails(participants):
    emails = []
    for participant in participants if isinstance(participants, list) else []:
        if isinstance(participant, dict):
            email = str(participant.get('email') or '').strip()
        else:
            email = str(participant).strip()
        if '@' in email and email not in emails:
            emails.append(email)
    return emails


def _send_meeting_invite(meeting):
    recipients = _participant_emails(meeting.participants)
    if not recipients:
        return 0
    agenda_items = meeting.agenda if isinstance(meeting.agenda, list) else []
    agenda_html = ''.join(f'<li>{item}</li>' for item in agenda_items if str(item).strip())
    html = f"""
    <div style="font-family:Arial,sans-serif;max-width:640px;margin:auto;padding:24px;border:1px solid #e5e7eb;border-radius:10px;">
      <h2 style="margin-top:0;color:#0f75bc;">Meeting Scheduled</h2>
      <p><b>{meeting.title}</b></p>
      <p><b>Date:</b> {meeting.date_label}</p>
      <p><b>Time:</b> {meeting.time_label}</p>
      <p><b>Duration:</b> {meeting.duration or '60 minutes'}</p>
      <p><b>Location / Link:</b> {meeting.location or '-'}</p>
      <p><b>Description:</b> {meeting.description or '-'}</p>
      <p><b>Agenda:</b></p>
      <ul>{agenda_html or '<li>-</li>'}</ul>
      <p>The calendar invite is attached to this email.</p>
    </div>
    """
    send_transactional_email(
        recipients,
        f'Meeting Scheduled: {meeting.title}',
        html,
        attachments=[{
            'filename': 'meeting.ics',
            'content': _meeting_ics(meeting).encode('utf-8'),
            'content_type': 'text/calendar',
        }],
    )
    return len(recipients)


def _tl_identity_values(user_id):
    values = {str(user_id or '').strip().lower()}
    user = User.objects.filter(user_id=user_id).first() or User.objects.filter(email__iexact=user_id).first()
    if user:
        values.update({
            str(user.user_id or '').strip().lower(),
            str(user.email or '').strip().lower(),
            f'{user.first_name} {user.last_name}'.strip().lower(),
            str(user.first_name or '').strip().lower(),
        })
    account = EmployeeAccount.objects.filter(employee_id=user_id).select_related('registration').first()
    if account:
        registration = account.registration
        values.update({
            str(account.employee_id or '').strip().lower(),
            str(account.employee_email or '').strip().lower(),
            f'{registration.first_name} {registration.last_name}'.strip().lower(),
            str(registration.first_name or '').strip().lower(),
        })
    return {value for value in values if value}


def _tl_team_queryset(user_id):
    queryset = EmployeeAccount.objects.select_related('registration').filter(is_active=True)
    identities = _tl_identity_values(user_id)
    if not identities:
        return queryset.none()

    filters = Q()
    for value in identities:
        filters |= Q(reporting_tl__iexact=value)
    return queryset.filter(filters)


def _tl_team_employee_ids(user_id):
    return list(_tl_team_queryset(user_id).values_list('employee_id', flat=True))


def _tl_team_items(user_id=''):
    items = []
    for account in _tl_team_queryset(user_id).order_by('-created_at')[:50]:
        registration = account.registration
        name = f'{registration.first_name} {registration.last_name}'.strip() or account.employee_email
        today = timezone.localdate()
        from_date = today - timedelta(days=29)
        attendance = list(EmployeeAttendanceRecord.objects.filter(
            employee_id=account.employee_id,
            attendance_date__gte=from_date,
            attendance_date__lte=today,
        ).order_by('-attendance_date'))
        present_count = sum(1 for item in attendance if item.status in ['Present', 'Late Entry', 'Half Day'])
        late_count = sum(1 for item in attendance if item.status == 'Late Entry')
        absent_count = max(30 - present_count, 0)
        task_queryset = TeamTask.objects.filter(assignee_id=account.employee_id)
        assigned_tasks = task_queryset.count()
        completed_tasks = task_queryset.filter(status='completed').count()
        pending_tasks = task_queryset.exclude(status='completed').count()
        task_score = round((completed_tasks / assigned_tasks) * 100) if assigned_tasks else 0
        attendance_score = round((present_count / 30) * 100) if attendance else 0
        performance_score = (
            round((task_score * 0.7) + (attendance_score * 0.3))
            if assigned_tasks
            else attendance_score
        )
        recent_attendance = [
            {
                'date': item.attendance_date.isoformat(),
                'status': item.status,
                'check_in': item.check_in.strftime('%I:%M %p') if item.check_in else '--',
                'check_out': item.check_out.strftime('%I:%M %p') if item.check_out else '--',
                'working_hours': item.working_hours or '--',
            }
            for item in attendance[:5]
        ]
        items.append({
            'id': account.employee_id,
            'title': name,
            'subtitle': account.get_designation_display(),
            'email': account.employee_email,
            'department': account.get_department_display(),
            'department_code': account.department,
            'designation': account.get_designation_display(),
            'date_of_joining': account.date_of_joining.isoformat() if account.date_of_joining else '',
            'employment_type': account.get_employment_type_display(),
            'reporting_tl': account.reporting_tl,
            'work_location': account.work_location,
            'trailing': account.employee_id,
            'score': f'{performance_score}%',
            'status': 'Active' if account.is_active else 'Inactive',
            'attendance_summary': {
                'present': present_count,
                'late': late_count,
                'absent': absent_count,
                'total_records': len(attendance),
            },
            'task_summary': {
                'assigned': assigned_tasks,
                'completed': completed_tasks,
                'pending': pending_tasks,
                'completion_rate': task_score,
            },
            'performance': {
                'score': performance_score,
                'tasks': f'{completed_tasks}/{assigned_tasks} completed' if assigned_tasks else 'No tasks assigned',
                'attendance': f'{present_count}/30 days',
            },
            'recent_attendance': recent_attendance,
        })
    return items


def _tl_meeting_items(user_id=''):
    team_ids = set(_tl_team_employee_ids(user_id))
    allowed_ids = {str(user_id or '').strip(), *team_ids}
    queryset = MdMeeting.objects.filter(created_by=user_id) if user_id else MdMeeting.objects.none()
    participant_matches = []
    if allowed_ids:
        for meeting in MdMeeting.objects.exclude(created_by=user_id)[:100]:
            participants = meeting.participants if isinstance(meeting.participants, list) else []
            for participant in participants:
                if isinstance(participant, dict):
                    participant_id = str(
                        participant.get('id')
                        or participant.get('employee_id')
                        or participant.get('user_id')
                        or participant.get('trailing')
                        or ''
                    ).strip()
                else:
                    participant_id = str(participant or '').strip()
                if participant_id in allowed_ids:
                    participant_matches.append(meeting)
                    break
    meetings = list(queryset[:30])
    seen = {meeting.id for meeting in meetings}
    for meeting in participant_matches:
        if meeting.id not in seen:
            meetings.append(meeting)
            seen.add(meeting.id)
    meetings.sort(key=lambda item: item.created_at, reverse=True)
    return [
        {
            'id': meeting.id,
            'title': meeting.title,
            'subtitle': meeting.location or meeting.meeting_type or meeting.description,
            'time': meeting.time_label or meeting.date_label,
            'trailing': meeting.status.title(),
            'date_label': meeting.date_label,
            'meeting_type': meeting.meeting_type,
            'location': meeting.location,
            'description': meeting.description,
            'participants': meeting.participants,
            'agenda': meeting.agenda,
        }
        for meeting in meetings[:30]
    ]


def _tl_report_items(total_employees, pending_leaves, meetings_count):
    reports = []
    if total_employees:
        reports.append({
            'title': 'Team Summary',
            'subtitle': f'{total_employees} employees',
            'trailing': 'Live DB',
        })
    if pending_leaves:
        reports.append({
            'title': 'Leave Approvals',
            'subtitle': f'{pending_leaves} pending TL review',
            'trailing': 'Live DB',
        })
    if meetings_count:
        reports.append({
            'title': 'Meetings',
            'subtitle': f'{meetings_count} scheduled',
            'trailing': 'Live DB',
        })
    return reports


def _tl_task_queryset(user_id):
    team_ids = _tl_team_employee_ids(user_id)
    if not team_ids:
        return TeamTask.objects.none()
    return TeamTask.objects.filter(Q(assignee_id__in=team_ids) | Q(created_by=user_id))


def _tl_task_items(user_id):
    queryset = _tl_task_queryset(user_id)
    return [
        {
            'id': task.id,
            'title': task.title,
            'subtitle': task.project or task.description,
            'project': task.project,
            'assignee': task.assignee_name,
            'assignee_id': task.assignee_id,
            'assignee_email': task.assignee_email,
            'priority': task.priority,
            'due': task.due_date,
            'description': task.description,
            'status': task.get_status_display(),
            'trailing': task.priority,
            'created_by': task.created_by,
        }
        for task in queryset[:30]
    ]


def _tl_project_items(user_id):
    team_ids = set(_tl_team_employee_ids(user_id))
    scoped_projects = []
    for project in Project.objects.all()[:200]:
        if project.created_by == user_id or project.manager_id == user_id:
            scoped_projects.append(project)
            continue
        team = project.team if isinstance(project.team, list) else []
        for member in team:
            if not isinstance(member, dict):
                continue
            member_id = str(member.get('id') or member.get('employee_id') or member.get('user_id') or '').strip()
            if member_id in team_ids or member_id == user_id:
                scoped_projects.append(project)
                break
    items = []
    seen = set()
    for project in scoped_projects:
        if project.id in seen:
            continue
        seen.add(project.id)
        status_label = project.get_status_display()
        items.append({
            'id': project.id,
            'title': project.name,
            'name': project.name,
            'subtitle': project.description or project.department or project.code,
            'trailing': f'{project.progress}%',
            'status': status_label,
            'code': project.code,
            'department': project.department,
            'description': project.description,
            'progress': project.progress,
            'manager_id': project.manager_id,
            'manager_name': project.manager_name,
            'manager_email': project.manager_email,
            'team': project.team or [],
            'start_date': project.start_date.isoformat() if project.start_date else '',
            'end_date': project.end_date.isoformat() if project.end_date else '',
            'budget': str(project.budget),
            'spent': str(project.spent),
        })
    return items[:30]


def _superadmin_users():
    users = []
    for user in User.objects.order_by('-user_id')[:30]:
        full_name = f'{user.first_name} {user.last_name}'.strip() or user.email
        users.append({
            'name': full_name,
            'subtitle': user.role.upper(),
            'detail': user.email,
            'trailing': user.user_id,
            'status': 'Active' if user.is_active else 'Inactive',
        })
    return users


def _ceo_common_payload(user_id=''):
    today = timezone.localdate()
    ceo = User.objects.filter(user_id=user_id, role='ceo').first()
    ceo_name = ''
    ceo_address = ''
    if ceo:
        ceo_name = f'{ceo.first_name} {ceo.last_name}'.strip() or ceo.email
        ceo_address = ', '.join(
            part
            for part in [ceo.door_no, ceo.street, ceo.city, ceo.state, ceo.pincode]
            if part
        )
    total_employees = _employee_count()
    workforce_today = _ceo_workforce_today(today)
    present_today = workforce_today['present']
    pending_leaves = _active_pending_leave_queryset().count()
    revenue_data = _ceo_monthly_revenue()
    payroll_month = today.replace(day=1)
    month_payslips = Payslip.objects.filter(year=payroll_month.year, month=payroll_month.month)
    payroll_cost = month_payslips.aggregate(total=Sum('net_salary'))['total'] or 0
    expenses = month_payslips.aggregate(total=Sum('total_deductions'))['total'] or 0
    net_profit = revenue_data['revenue_amount'] - float(expenses or 0)
    payload = {
        'success': True,
        'profile': {
            'id': ceo.user_id if ceo else user_id,
            'name': ceo_name or 'CEO',
            'first_name': ceo.first_name if ceo else '',
            'last_name': ceo.last_name if ceo else '',
            'email': ceo.email if ceo else '',
            'phone': mask_phone_number(ceo.phone) if ceo else '',
            'country_code': ceo.country_code if ceo else '',
            'role': ceo.role if ceo else 'ceo',
            'role_label': ceo.get_role_display() if ceo else 'CEO',
            'designation': ceo.occupation if ceo else '',
            'designation_label': _role_label(ceo.occupation) if ceo and ceo.occupation else 'Chief Executive Officer',
            'department': ceo.department if ceo else '',
            'work_mode': ceo.get_work_mode_display() if ceo else '',
            'address': ceo_address,
            'city': ceo.city if ceo else '',
            'state': ceo.state if ceo else '',
            'photo_url': _passport_photo_for_email(ceo.email) if ceo else '',
            'status': 'Active' if ceo and ceo.is_active else 'Inactive',
        },
        'attendance_health': _ceo_attendance_health(today),
        'total_employees': total_employees,
        'active_employees': _active_employee_count(),
        'departments': _department_count(),
        'branches': _branch_count(),
        'attendance': present_today,
        'pending_approvals': pending_leaves,
        'payroll_cost': _format_inr(payroll_cost),
        'expenses': _format_inr(expenses),
        'net_profit': _format_inr(net_profit),
        'workforce_today': workforce_today,
        'absent_today': workforce_today['absent'],
        'late_entry': workforce_today['late_entry'],
        'wfh': workforce_today['wfh'],
        'hybrid': workforce_today['hybrid'],
        'onsite': workforce_today['onsite'],
        'role_counts': _ceo_role_summary(user_id),
        'role_members': _ceo_role_members(user_id),
        'employee_categories': _ceo_employee_category_summary(),
        'recent_members': _ceo_recent_members(user_id),
        'active_employee_list': _ceo_active_employee_list(),
        'approvals_summary': _ceo_approvals_summary(),
        'project_overview': _ceo_project_overview(),
        'project_items': _ceo_project_items(),
        'critical_alerts': _ceo_critical_alerts(today),
    }
    payload.update(revenue_data)
    return payload


def _empty_ceo_dashboard_payload(user_id='', message='CEO dashboard data unavailable.'):
    return {
        'success': False,
        'message': message,
        'profile': {
            'id': user_id,
            'name': 'CEO',
            'first_name': '',
            'last_name': '',
            'email': '',
            'phone': '',
            'country_code': '',
            'role': 'ceo',
            'role_label': 'CEO',
            'designation': '',
            'designation_label': 'Chief Executive Officer',
            'department': '',
            'work_mode': '',
            'address': '',
            'city': '',
            'state': '',
            'photo_url': '',
            'status': 'Inactive',
        },
        'attendance_health': {
            'score': 0,
            'label': 'No Data',
            'trend': 0,
            'trend_label': '+0%',
            'total_members': 0,
            'joined_this_month': 0,
            'present_today': 0,
            'on_leave_today': 0,
            'weekly_scores': [],
        },
        'total_employees': 0,
        'active_employees': 0,
        'departments': 0,
        'branches': 0,
        'attendance': 0,
        'pending_approvals': 0,
        'payroll_cost': 'Rs. 0',
        'expenses': 'Rs. 0',
        'net_profit': 'Rs. 0',
        'workforce_today': {
            'present': 0,
            'absent': 0,
            'late_entry': 0,
            'wfh': 0,
            'hybrid': 0,
            'onsite': 0,
        },
        'absent_today': 0,
        'late_entry': 0,
        'wfh': 0,
        'hybrid': 0,
        'onsite': 0,
        'role_counts': [],
        'role_members': [],
        'employee_categories': [],
        'recent_members': [],
        'active_employee_list': [],
        'approvals_summary': [],
        'project_overview': {
            'active': 0,
            'completed': 0,
            'delayed': 0,
            'at_risk': 0,
        },
        'project_items': [],
        'critical_alerts': [],
        'revenue': 'Rs. 0',
        'revenue_amount': 0,
        'revenue_trend': '+0%',
        'revenue_bars': [],
        'revenue_months': [],
        'monthly_revenue': [],
    }


def _document_flag_email_html(registration, document_title, details):
    employee_name = (
        f'{registration.first_name} {registration.last_name}'.strip()
        or registration.personal_email
    )
    issue_type = escape(str(details.get('issue_type') or 'Document correction required'))
    remark = escape(str(details.get('remark') or 'Please upload a clear and correct document.'))
    suggested_action = escape(str(details.get('suggested_action') or 'Re-upload the corrected document in the HRMS app.'))
    priority = escape(str(details.get('priority') or 'Normal'))
    return f'''
    <div style="font-family:Arial,sans-serif;max-width:620px;margin:auto;padding:30px;border:1px solid #e5e7eb;border-radius:10px;">
      <h2 style="margin-top:0;color:#dc2626;">Document Correction Required</h2>
      <p>Dear <b>{escape(employee_name)}</b>,</p>
      <p>HR has flagged your <b>{escape(document_title)}</b> during document verification.</p>
      <div style="background:#fff7ed;padding:18px;border-left:4px solid #f97316;border-radius:8px;margin:20px 0;">
        <p><b>Issue:</b> {issue_type}</p>
        <p><b>HR Remark:</b> {remark}</p>
        <p><b>Suggested Action:</b> {suggested_action}</p>
        <p><b>Priority:</b> {priority}</p>
      </div>
      <p>Please sign in to the HRMS application and re-upload the corrected document.</p>
      <br/>
      <p>Regards,</p>
      <p><b>Bitbyte HR Team</b></p>
    </div>
    '''


@api_view(['GET'])
def ceo_profile_view(request):
    user_id = (request.query_params.get('user_id') or '').strip()
    ceo = User.objects.filter(user_id=user_id, role='ceo').first()
    if ceo is None:
        return Response({
            'success': True,
            'profile': {
                'id': user_id,
                'name': 'CEO',
                'first_name': '',
                'last_name': '',
                'email': '',
                'phone': '',
                'country_code': '',
                'role': 'ceo',
                'role_label': 'CEO',
                'designation': '',
                'designation_label': 'Chief Executive Officer',
                'department': '',
                'work_mode': '',
                'address': '',
                'city': '',
                'state': '',
                'photo_url': '',
                'status': 'Inactive',
            },
        })
    name = f'{ceo.first_name} {ceo.last_name}'.strip() or ceo.email
    address = ', '.join(
        part
        for part in [ceo.door_no, ceo.street, ceo.city, ceo.state, ceo.pincode]
        if part
    )
    return Response({
        'success': True,
        'profile': {
            'id': ceo.user_id,
            'name': name,
            'first_name': ceo.first_name,
            'last_name': ceo.last_name,
            'email': ceo.email,
            'phone': mask_phone_number(ceo.phone),
            'country_code': ceo.country_code,
            'role': ceo.role,
            'role_label': ceo.get_role_display(),
            'designation': ceo.occupation,
            'designation_label': _role_label(ceo.occupation) if ceo.occupation else 'Chief Executive Officer',
            'department': ceo.department,
            'work_mode': ceo.get_work_mode_display(),
            'address': address,
            'city': ceo.city,
            'state': ceo.state,
            'photo_url': _passport_photo_for_email(ceo.email),
            'status': 'Active' if ceo.is_active else 'Inactive',
        },
    })


def _leave_dashboard_item(leave):
    employee_name = _employee_name(leave.employee_id)
    account = EmployeeAccount.objects.filter(employee_id=leave.employee_id).select_related('registration').first()
    date_range = f'{leave.from_date:%d %b %Y} - {leave.to_date:%d %b %Y}'
    day_text = f'{leave.total_days} Day' if leave.total_days == 1 else f'{leave.total_days} Days'
    subtitle = f'{leave.leave_type} - {date_range}'
    if leave.status == 'pending' and leave.tl_status == 'approved':
        display_status = 'Pending HR'
    elif leave.status == 'pending':
        display_status = 'Pending TL'
    else:
        display_status = leave.status.title()
    certificate = leave.medical_certificate
    certificate_name = certificate.name.split('/')[-1] if certificate else ''
    try:
        certificate_url = certificate.url if certificate else ''
    except ValueError:
        certificate_url = ''
    balance_payload = _leave_balance_payload(leave.employee_id, account)
    leave_key = _compact_key(leave.leave_type)
    type_balance = next(
        (item for item in balance_payload.get('types', []) if _compact_key(item.get('type')) == leave_key),
        {},
    )
    balance_before = float(type_balance.get('available') or 0)
    balance_after = max(balance_before - float(leave.total_days or 0), 0)
    return {
        'id': leave.id,
        'request_id': f'LEV-{leave.from_date:%Y%m%d}-{leave.id:04d}',
        'employee_id': leave.employee_id,
        'name': employee_name,
        'initials': _initials(employee_name),
        'designation': account.get_designation_display() if account else '',
        'department': account.get_department_display() if account else '',
        'title': f'{employee_name} - {leave.leave_type}',
        'leave_type': leave.leave_type,
        'subtitle': subtitle,
        'days': day_text,
        'duration': day_text,
        'trailing': day_text,
        'status': display_status,
        'overall_status': leave.status.title(),
        'tl_status': leave.tl_status.title(),
        'hr_status': leave.hr_status.title(),
        'reason': leave.reason,
        'session': 'Full Day',
        'medical_certificate': certificate_name,
        'medical_certificate_url': certificate_url,
        'document_name': certificate_name,
        'attachment_size': '',
        'time': _relative_time(leave.created_at),
        'from_date': leave.from_date.isoformat(),
        'to_date': leave.to_date.isoformat(),
        'from_date_label': f'{leave.from_date:%Y-%m-%d} ({leave.from_date:%a})',
        'to_date_label': f'{leave.to_date:%Y-%m-%d} ({leave.to_date:%a})',
        'applied_on': leave.created_at.isoformat() if leave.created_at else '',
        'submitted_on': leave.created_at.strftime('%Y-%m-%d %I:%M %p') if leave.created_at else '',
        'approved_by': leave.approved_by,
        'reviewed_at': leave.reviewed_at.isoformat() if leave.reviewed_at else '',
        'tl_approved_by': leave.tl_approved_by,
        'tl_reviewed_at': leave.tl_reviewed_at.isoformat() if leave.tl_reviewed_at else '',
        'hr_approved_by': leave.hr_approved_by,
        'hr_reviewed_at': leave.hr_reviewed_at.isoformat() if leave.hr_reviewed_at else '',
        'leave_balance': round(balance_before, 2),
        'after_request_balance': round(balance_after, 2),
    }


def _compact_key(value):
    return ''.join(ch for ch in str(value or '').lower() if ch.isalnum())


def _initials(value):
    parts = [part for part in str(value or '').strip().split() if part]
    if not parts:
        return 'TL'
    return ''.join(part[0] for part in parts[:2]).upper()


def _tl_pending_leave_items(user_id=''):
    team_ids = _tl_team_employee_ids(user_id)
    notified_leave_ids = _tl_notified_leave_ids(user_id)
    filters = Q(status='pending', tl_status='pending')
    scope = Q()
    if team_ids:
        scope |= Q(employee_id__in=team_ids)
    if notified_leave_ids:
        scope |= Q(id__in=notified_leave_ids)
    if not scope:
        return []
    return [
        _leave_dashboard_item(leave)
        for leave in EmployeeLeaveRequest.objects.filter(
            filters & scope,
        )[:20]
    ]


def _tl_reviewed_leave_items(user_id='', tl_status='approved'):
    team_ids = _tl_team_employee_ids(user_id)
    notified_leave_ids = _tl_notified_leave_ids(user_id)
    scope = Q()
    if team_ids:
        scope |= Q(employee_id__in=team_ids)
    if notified_leave_ids:
        scope |= Q(id__in=notified_leave_ids)
    if not scope:
        return []
    return [
        _leave_dashboard_item(leave)
        for leave in EmployeeLeaveRequest.objects.filter(
            scope,
            tl_status=tl_status,
        )[:20]
    ]


def _tl_all_approval_payload(user_id=''):
    pending = _tl_pending_leave_items(user_id)
    approved = _tl_reviewed_leave_items(user_id, 'approved')
    rejected = _tl_reviewed_leave_items(user_id, 'rejected')
    urgent = [
        item for item in pending
        if _approval_days(item) >= 2
        or 'urgent' in str(item.get('reason', '')).lower()
    ]
    return {
        'success': True,
        'pending': pending,
        'urgent': urgent,
        'approved': approved,
        'rejected': rejected,
        'summary': {
            'pending': len(pending),
            'urgent': len(urgent),
            'approved_today': len([
                item for item in approved
                if str(item.get('tl_reviewed_at', '')).startswith(timezone.localdate().isoformat())
            ]),
            'rejected_today': len([
                item for item in rejected
                if str(item.get('tl_reviewed_at', '')).startswith(timezone.localdate().isoformat())
            ]),
        },
    }


def _approval_days(item):
    try:
        return float(str(item.get('duration') or item.get('days') or '0').split()[0])
    except (TypeError, ValueError, IndexError):
        return 0


def _tl_notified_leave_ids(user_id=''):
    notifications = AppNotification.objects.filter(
        module='leave',
    ).filter(Q(recipient_user_id=user_id) | Q(recipient_role='tl'))
    return [
        int(item.reference_id)
        for item in notifications
        if str(item.reference_id).isdigit()
    ]


def _hr_pending_leave_items():
    return [_leave_dashboard_item(leave) for leave in EmployeeLeaveRequest.objects.filter(status='pending', tl_status='approved', hr_status='pending')[:20]]


def _leave_decision(request, pk, role):
    decision = request.data.get('status')
    if decision not in ['approved', 'rejected']:
        return Response({'success': False, 'message': 'Status must be approved or rejected.'}, status=400)

    try:
        leave = EmployeeLeaveRequest.objects.get(pk=pk)
    except EmployeeLeaveRequest.DoesNotExist:
        return Response({'success': False, 'message': 'Leave request not found.'}, status=404)

    reviewer = request.data.get('reviewed_by') or request.data.get('user_id') or role.upper()
    rejection_reason = (request.data.get('rejection_reason') or request.data.get('reason') or '').strip()
    now = timezone.now()
    if role == 'tl':
        leave.tl_status = decision
        leave.tl_approved_by = reviewer
        leave.tl_reviewed_at = now
        if decision == 'rejected':
            leave.status = 'rejected'
            leave.approved_by = reviewer
            leave.reviewed_at = now
            _notify_leave_employee(
                leave,
                'Leave Request Rejected',
                f'Your {leave.leave_type} request was rejected by TL.' + (f' Reason: {rejection_reason}' if rejection_reason else ''),
                'error',
            )
        else:
            _notify_leave_employee(
                leave,
                'Leave Approved by TL',
                f'Your {leave.leave_type} request is now waiting for HR approval.',
                'info',
            )
            _create_notification(
                role='hr',
                title='Leave Approval Pending',
                message=f'{_employee_name(leave.employee_id)} has TL-approved leave waiting for HR review.',
                notification_type='warning',
                module='leave',
                reference_id=leave.id,
            )
    else:
        if leave.tl_status != 'approved':
            return Response({'success': False, 'message': 'TL approval is required before HR review.'}, status=400)
        leave.hr_status = decision
        leave.hr_approved_by = reviewer
        leave.hr_reviewed_at = now
        leave.status = decision
        leave.approved_by = reviewer
        leave.reviewed_at = now
        _notify_leave_employee(
            leave,
            'Leave Request Approved' if decision == 'approved' else 'Leave Request Rejected',
            f'Your {leave.leave_type} request was {decision} by HR.' + (f' Reason: {rejection_reason}' if decision == 'rejected' and rejection_reason else ''),
            'success' if decision == 'approved' else 'error',
        )
    leave.save()
    return Response({'success': True, 'message': f'Leave {decision} by {role.upper()}.', 'leave': _leave_dashboard_item(leave)})


@api_view(['GET'])
def hr_dashboard_view(request):
    today = timezone.localdate()
    pending_leaves = _hr_pending_leave_items()
    approved_leaves = [_leave_dashboard_item(leave) for leave in EmployeeLeaveRequest.objects.filter(status='approved')[:20]]
    rejected_leaves = [_leave_dashboard_item(leave) for leave in EmployeeLeaveRequest.objects.filter(status='rejected')[:20]]
    payroll_month = timezone.localdate()
    month_payslips = list(
        Payslip.objects.filter(year=payroll_month.year, month=payroll_month.month)
    )
    notifications = _notifications_for_role('hr')

    # Live attendance counts
    present_ids = set(
        EmployeeAttendanceRecord.objects.filter(
            attendance_date=today, status__in=['Present', 'Half Day']
        ).values_list('employee_id', flat=True)
    )
    on_leave_ids = set(
        EmployeeLeaveRequest.objects.filter(
            status='approved',
            from_date__lte=today,
            to_date__gte=today,
        ).values_list('employee_id', flat=True)
    )
    all_active_accounts = list(
        EmployeeAccount.objects.select_related('registration').filter(is_active=True)
    )
    account_by_employee_id = {
        account.employee_id: account for account in all_active_accounts
    }
    payroll_items = [
        _hr_payroll_item(item, account_by_employee_id) for item in month_payslips[:20]
    ]
    payroll_cost = sum(
        item.net_salary
        for item in month_payslips
        if item.status in ['approved', 'paid']
    )
    total_employees = len(all_active_accounts)
    present_today = len(present_ids)
    on_leave_count = len(on_leave_ids)
    absent_today = max(total_employees - present_today - on_leave_count, 0)

    def _emp_list(accounts):
        result = []
        for acc in accounts:
            reg = acc.registration
            result.append({
                'name': f'{reg.first_name} {reg.last_name}'.strip() or acc.employee_email,
                'subtitle': f'{acc.get_designation_display()} · {acc.get_department_display()}',
                'trailing': acc.employee_id,
                # Full detail fields for employee detail screen
                'id': acc.employee_id,
                'role': acc.get_designation_display(),
                'department': acc.get_department_display(),
                'email': acc.employee_email,
                'status': 'Active' if acc.is_active else 'Inactive',
                'phone': mask_phone_number(reg.mobile),
                'date_of_joining': str(acc.date_of_joining) if acc.date_of_joining else '',
                'employment_type': acc.get_employment_type_display(),
                'reporting_tl': acc.reporting_tl or '',
                'work_mode': acc.work_location or '',
                'blood_group': reg.blood_group or '',
                'gender': reg.gender or '',
                'dob': reg.dob or '',
                'nationality': reg.nationality or '',
                'marital_status': reg.marital_status or '',
                'current_city': reg.current_city or '',
                'current_state': reg.current_state or '',
                'aadhar': reg.aadhar or '',
                'pan': reg.pan or '',
                'bank_name': reg.bank_name or '',
                'account_number': reg.account_number or '',
                'ifsc_code': reg.ifsc_code or '',
                'branch_name': reg.branch_name or '',
                'qualification': reg.qualification or '',
                'college': reg.college or '',
                'year_of_passing': reg.year_of_passing or '',
            })
        return result

    # Per-stat employee lists
    present_accounts = [a for a in all_active_accounts if a.employee_id in present_ids]
    on_leave_accounts = [a for a in all_active_accounts if a.employee_id in on_leave_ids]
    absent_accounts = [
        a for a in all_active_accounts
        if a.employee_id not in present_ids and a.employee_id not in on_leave_ids
    ]
    payroll_validation = _hr_payroll_validation(all_active_accounts, payroll_month)
    payroll_ready = sum(1 for item in payroll_validation if item['ready'])
    payroll_totals = {
        'gross': sum(item.gross_salary for item in month_payslips),
        'earnings': sum(item.total_earnings for item in month_payslips),
        'deductions': sum(item.total_deductions for item in month_payslips),
        'net': sum(item.net_salary for item in month_payslips),
    }

    return Response({
        'success': True,
        'total_employees': total_employees,
        'present_today': present_today,
        'absent_today': absent_today,
        'on_leave': on_leave_count,
        'total_employees_list': _emp_list(all_active_accounts),
        'present_today_list': _emp_list(present_accounts),
        'absent_today_list': _emp_list(absent_accounts),
        'on_leave_list': _emp_list(on_leave_accounts),
        'leave_requests': pending_leaves,
        'leave_requests_approved': approved_leaves,
        'leave_requests_rejected': rejected_leaves,
        'notifications': notifications,
        'upcoming': [],
        'tasks': [],
        'documents': [],
        'payroll_month': payroll_month.strftime('%B %Y'),
        'payroll_processed': len(month_payslips),
        'payroll_pending': max(total_employees - len(month_payslips), 0),
        'payroll_cost': str(payroll_cost),
        'payroll_items': payroll_items,
        'payroll_validation': payroll_validation,
        'payroll_ready': payroll_ready,
        'payroll_readiness': round((payroll_ready / total_employees) * 100) if total_employees else 0,
        'payroll_gross': str(payroll_totals['gross'] or 0),
        'payroll_earnings': str(payroll_totals['earnings'] or 0),
        'payroll_deductions': str(payroll_totals['deductions'] or 0),
        'payroll_net': str(payroll_totals['net'] or 0),
        'onboarding': [],
        'pipeline': [],
        'open_positions': [],
        'open_positions_count': 0,
        'candidates_count': 0,
        'interviews_count': 0,
        'offers': 0,
        'offers_count': 0,
        'pending_reviews': 0,
        'completed_reviews': 0,
        'high_performers': 0,
        'low_performers': 0,
        'performers': [],
    })


def _hr_payroll_item(payslip, account_by_employee_id=None):
    account = (account_by_employee_id or {}).get(payslip.employee_id)
    if account is None:
        account = EmployeeAccount.objects.select_related('registration').filter(employee_id=payslip.employee_id).first()
    employee_name = _account_display_name(account, payslip.employee_id)
    return {
        'title': f'{employee_name} - {payslip.month:02d}/{payslip.year}',
        'subtitle': f'Net Rs {payslip.net_salary} | Paid {payslip.paid_days} days | LOP {payslip.lop_days}',
        'status': payslip.status.title(),
        'employee_id': payslip.employee_id,
        'employee_name': employee_name,
        'designation': account.get_designation_display() if account else '',
        'department': account.get_department_display() if account else '',
        'bank_name': account.registration.bank_name if account and account.registration else '',
        'account_number': account.registration.account_number if account and account.registration else '',
        'ifsc_code': account.registration.ifsc_code if account and account.registration else '',
        'working_days': payslip.working_days,
        'paid_days': payslip.paid_days,
        'lop_days': payslip.lop_days,
        'overtime_minutes': payslip.overtime_minutes,
        'gross_salary': str(payslip.gross_salary),
        'total_earnings': str(payslip.total_earnings),
        'total_deductions': str(payslip.total_deductions),
        'net_salary': str(payslip.net_salary),
        'earnings': payslip.earnings if isinstance(payslip.earnings, dict) else {},
        'deductions': payslip.deductions if isinstance(payslip.deductions, dict) else {},
        'generated_at': payslip.generated_at.isoformat() if payslip.generated_at else '',
    }


def _hr_payroll_validation(accounts, payroll_date):
    month_start = payroll_date.replace(day=1)
    elapsed_working_days = sum(
        1
        for day in range(1, payroll_date.day + 1)
        if payroll_date.replace(day=day).weekday() < 5
    )
    employee_ids = [account.employee_id for account in accounts]
    attendance_counts = {
        row['employee_id']: row['count']
        for row in EmployeeAttendanceRecord.objects.filter(
            employee_id__in=employee_ids,
            attendance_date__gte=month_start,
            attendance_date__lte=payroll_date,
        ).values('employee_id').annotate(count=Count('id'))
    }
    salary_employee_ids = set(
        SalaryStructure.objects.filter(
            employee_id__in=employee_ids,
        ).values_list('employee_id', flat=True)
    )
    items = []
    for account in accounts:
        registration = account.registration
        name = _account_display_name(account, account.employee_id)
        attendance_days = attendance_counts.get(account.employee_id, 0)
        missing_attendance_days = max(elapsed_working_days - attendance_days, 0)
        bank_missing = not (
            registration
            and str(registration.account_number or '').strip()
            and str(registration.ifsc_code or '').strip()
        )
        salary_configured = account.employee_id in salary_employee_ids
        items.append({
            'employee_id': account.employee_id,
            'employee_name': name,
            'designation': account.get_designation_display(),
            'department': account.get_department_display(),
            'bank_missing': bank_missing,
            'bank_name': registration.bank_name if registration else '',
            'account_number': registration.account_number if registration else '',
            'ifsc_code': registration.ifsc_code if registration else '',
            'attendance_days': attendance_days,
            'expected_attendance_days': elapsed_working_days,
            'missing_attendance_days': missing_attendance_days,
            'attendance_conflict': missing_attendance_days > 0,
            'salary_configured': salary_configured,
            'ready': not bank_missing and missing_attendance_days == 0 and salary_configured,
        })
    return items


def _account_display_name(account, fallback='Employee'):
    if account and account.registration:
        registration = account.registration
        name = f'{registration.first_name} {registration.last_name}'.strip()
        return name or account.employee_email or fallback
    return fallback or 'Employee'


@api_view(['POST'])
def hr_generate_payroll_view(request):
    today = timezone.localdate()
    year = int(request.data.get('year') or today.year)
    month = int(request.data.get('month') or today.month)
    generated_by = request.data.get('user_id') or request.data.get('generated_by') or 'HR'
    payslips = generate_payroll_for_month(year, month, generated_by)

    # Email each employee their payslip PDF
    for payslip in payslips:
        _send_payslip_to_employee(payslip, request)

    # Email payroll summary to HR / MD / Admin / SuperAdmin
    _send_payroll_summary_to_management(year, month, payslips, generated_by, request)

    return Response({
        'success': True,
        'message': f'Payroll generated for {month:02d}/{year}.',
        'processed': len(payslips),
        'total_net_salary': str(sum(item.net_salary for item in payslips)),
        'payslips': [payslip_payload(item, request) for item in payslips],
    })


@api_view(['GET', 'POST'])
def hr_payroll_process_view(request):
    today = timezone.localdate()
    source = request.query_params if request.method == 'GET' else request.data
    try:
        year = int(source.get('year') or today.year)
        month = int(source.get('month') or today.month)
    except (TypeError, ValueError):
        return Response({'success': False, 'message': 'A valid payroll year and month are required.'}, status=400)
    if month < 1 or month > 12:
        return Response({'success': False, 'message': 'Payroll month must be between 1 and 12.'}, status=400)

    process, _ = PayrollProcess.objects.get_or_create(year=year, month=month)
    accounts = list(EmployeeAccount.objects.select_related('registration').filter(is_active=True))
    validation_date = min(today, datetime(year, month, calendar.monthrange(year, month)[1]).date())
    validation = _hr_payroll_validation(accounts, validation_date)

    if request.method == 'POST':
        action = str(request.data.get('action') or '').strip().lower()
        actor = str(request.data.get('user_id') or request.data.get('actor') or 'HR').strip()
        now = timezone.now()
        if action == 'start':
            process.status = 'validation'
            process.prepared_by = actor
        elif action == 'resolve':
            issue_id = str(request.data.get('issue_id') or '').strip()
            if not issue_id:
                return Response({'success': False, 'message': 'Issue id is required.'}, status=400)
            resolved = list(process.resolved_issues or [])
            if issue_id not in resolved:
                resolved.append(issue_id)
            process.resolved_issues = resolved
            process.status = 'validation'
        elif action == 'validate':
            process.status = 'calculation'
            process.validated_at = now
        elif action == 'approve':
            process.status = 'approval'
            process.calculated_at = process.calculated_at or now
            process.approved_at = now
        elif action == 'publish':
            options = request.data.get('options') if isinstance(request.data.get('options'), dict) else {}
            payslips = generate_payroll_for_month(year, month, actor)
            process.status = 'published'
            process.publishing_options = options
            process.approved_at = process.approved_at or now
            process.published_at = now
            process.save()

            # Email each employee their payslip PDF
            for payslip in payslips:
                _send_payslip_to_employee(payslip, request)

            # Email payroll summary to HR / MD / Admin / SuperAdmin
            _send_payroll_summary_to_management(year, month, payslips, actor, request)

            return Response({
                'success': True,
                'message': f'Payroll published for {month:02d}/{year}.',
                'process': _payroll_process_payload(process),
                'processed': len(payslips),
                'total_net_salary': str(sum(item.net_salary for item in payslips)),
                'payslips': [payslip_payload(item, request) for item in payslips],
            })
        else:
            return Response({'success': False, 'message': 'Unsupported payroll process action.'}, status=400)
        process.save()

    return Response({
        'success': True,
        'process': _payroll_process_payload(process),
        'validation': validation,
        'total_employees': len(accounts),
        'unresolved_issues': _payroll_unresolved_count(validation, process.resolved_issues),
    })


def _payroll_process_payload(process):
    return {
        'id': process.id,
        'year': process.year,
        'month': process.month,
        'status': process.status,
        'stage': {'inputs': 0, 'validation': 1, 'calculation': 2, 'approval': 3, 'published': 4}.get(process.status, 0),
        'resolved_issues': process.resolved_issues or [],
        'publishing_options': process.publishing_options or {},
        'prepared_by': process.prepared_by,
        'validated_at': process.validated_at.isoformat() if process.validated_at else '',
        'calculated_at': process.calculated_at.isoformat() if process.calculated_at else '',
        'approved_at': process.approved_at.isoformat() if process.approved_at else '',
        'published_at': process.published_at.isoformat() if process.published_at else '',
    }


def _payroll_unresolved_count(validation, resolved_issues):
    issue_ids = []
    for item in validation:
        employee_id = item['employee_id']
        if item['bank_missing']:
            issue_ids.append(f'{employee_id}-bank')
        if item['attendance_conflict']:
            issue_ids.append(f'{employee_id}-attendance')
        if not item['salary_configured']:
            issue_ids.append(f'{employee_id}-salary')
    resolved = set(resolved_issues or [])
    return sum(1 for issue_id in issue_ids if issue_id not in resolved)


@api_view(['POST'])
def hr_upload_payslip_pdf_view(request):
    upload = request.FILES.get('pdf')
    employee_id = str(request.data.get('employee_id') or '').strip()
    year = str(request.data.get('year') or '').strip()
    month = str(request.data.get('month') or '').strip().zfill(2)
    version = str(request.data.get('version') or '1').strip()

    if upload is None:
        return Response({'success': False, 'message': 'Payslip PDF is required.'}, status=400)
    if not employee_id or not year or not month:
        return Response({'success': False, 'message': 'Employee, year, and month are required.'}, status=400)

    path = f'payslips/{employee_id}/{year}-{month}-v{version}.pdf'
    if default_storage.exists(path):
        default_storage.delete(path)
    pdf_content = upload.read()
    saved_path = default_storage.save(path, ContentFile(pdf_content))
    pdf_url = request.build_absolute_uri(default_storage.url(saved_path))

    # Email the uploaded payslip PDF directly to the employee
    try:
        account = EmployeeAccount.objects.filter(employee_id=employee_id).select_related('registration').first()
        if account and account.employee_email:
            reg = account.registration
            employee_name = f'{reg.first_name} {reg.last_name}'.strip() or employee_id
            from calendar import month_name as _month_names
            try:
                month_label = f'{_month_names[int(month)]} {year}'
            except Exception:
                month_label = f'{month}/{year}'

            html = _payslip_email_html(employee_name, employee_id, month_label, '–', pdf_url)
            sg = SendGridAPIClient(os.getenv('SENDGRID_API_KEY'))
            message = Mail(
                from_email=os.getenv('EMAIL_FROM', 'noreply@bitbyte.com'),
                to_emails=account.employee_email,
                subject=f'Your Payslip – {month_label} | Bitbyte',
                html_content=html,
            )
            encoded_pdf = base64.b64encode(pdf_content).decode('ascii')
            message.attachment = Attachment(
                FileContent(encoded_pdf),
                FileName(f'{employee_id}-{year}-{month}-payslip.pdf'),
                FileType('application/pdf'),
                Disposition('attachment'),
            )
            sg.send(message)
    except Exception as e:
        print(f'Upload payslip email error for {employee_id}: {e}')

    return Response({
        'success': True,
        'pdf_url': pdf_url,
    })


@api_view(['GET'])
def tl_dashboard_view(request):
    user_id = request.GET.get('user_id', '').strip()
    today = timezone.localdate()
    pending_leaves = _tl_pending_leave_items(user_id)
    approved_leaves = _tl_reviewed_leave_items(user_id, 'approved')
    rejected_leaves = _tl_reviewed_leave_items(user_id, 'rejected')
    team_queryset = _tl_team_queryset(user_id)
    total_employees = team_queryset.count()
    active_team_count = team_queryset.filter(is_active=True).count()
    team = _tl_team_items(user_id)
    meetings = _tl_meeting_items(user_id)
    tasks = _tl_task_items(user_id)
    projects = _tl_project_items(user_id)
    task_queryset = _tl_task_queryset(user_id)
    created_tasks_count = task_queryset.count()
    completed_tasks_count = task_queryset.filter(status='completed').count()
    team_progress = round((completed_tasks_count / created_tasks_count) * 100) if created_tasks_count else 0
    on_track = sum(
        1
        for item in team
        if int(item.get('task_summary', {}).get('completion_rate') or 0) >= 75
    )
    notifications = _notifications_for_user(user_id)
    return Response({
        'success': True,
        'my_tasks': len(tasks),
        'members_count': total_employees,
        'total_employees': total_employees,
        'projects_count': len(projects),
        'pending_approvals': len(pending_leaves),
        'tasks_progress': round((completed_tasks_count / created_tasks_count) * 100) if created_tasks_count else (100 if not tasks else 0),
        'tasks_done': completed_tasks_count,
        'tasks_total': created_tasks_count,
        'tasks_pending': max(created_tasks_count - completed_tasks_count, 0),
        'team_progress': team_progress,
        'on_track': on_track,
        'check_in': '',
        'location': '',
        'accuracy': '-',
        'work_type': '',
        'calendar_month': today.strftime('%B %Y'),
        'calendar_day': today.day,
        'approvals': pending_leaves,
        'leaves': pending_leaves,
        'leaves_approved': approved_leaves,
        'leaves_rejected': rejected_leaves,
        'notifications': notifications,
        'team': team,
        'tasks': tasks,
        'projects': projects,
        'meetings': meetings,
        'reports': _tl_report_items(total_employees, len(pending_leaves), len(meetings)),
    })


@api_view(['POST'])
def tl_meetings_view(request):
    meeting_start = _parse_meeting_start(
        str(request.data.get('date_label') or ''),
        str(request.data.get('time_label') or ''),
    )
    if meeting_start <= timezone.now():
        return Response({
            'success': False,
            'message': 'Meeting date and time must be in the future.',
        }, status=400)
    meeting = _create_meeting_from_payload(request.data, 'Team Meeting')
    _notify_meeting_participants(meeting)
    email_count = 0
    email_error = ''
    if request.data.get('invite_email', True):
        try:
            email_count = _send_meeting_invite(meeting)
        except Exception as error:
            email_error = str(error)
    return Response({
        'success': True,
        'meeting': _md_meeting_payload(meeting),
        'email_sent_to': email_count,
        'email_error': email_error,
    })


@api_view(['POST'])
def tl_tasks_view(request):
    payload = request.data
    title = (payload.get('title') or '').strip()
    if not title:
        return Response({'success': False, 'message': 'Task title is required.'}, status=400)

    task = TeamTask.objects.create(
        title=title,
        project=payload.get('project', ''),
        assignee_id=payload.get('assignee_id', ''),
        assignee_name=payload.get('assignee_name', ''),
        assignee_email=payload.get('assignee_email', ''),
        priority=payload.get('priority') or 'Medium',
        due_date=payload.get('due_date', ''),
        description=payload.get('description', ''),
        created_by=payload.get('created_by', ''),
    )
    if task.assignee_id:
        _create_notification(
            user_id=task.assignee_id,
            title='New Task Assigned',
            message=f'{task.title} has been assigned to you.',
            notification_type='info',
            module='tasks',
            reference_id=task.id,
        )
    return Response({
        'success': True,
        'message': 'Task created successfully.',
        'task': {
            'id': task.id,
            'title': task.title,
            'project': task.project,
            'assignee': task.assignee_name,
            'priority': task.priority,
            'due': task.due_date,
            'status': task.get_status_display(),
        },
    })


@api_view(['GET'])
def tl_approvals_view(request):
    user_id = request.query_params.get('user_id') or ''
    return Response(_tl_all_approval_payload(user_id))


@api_view(['GET'])
def ceo_dashboard_view(request):
    user_id = request.query_params.get('user_id') or ''
    try:
        return Response(_ceo_common_payload(user_id))
    except Exception as exc:
        return Response(
            _empty_ceo_dashboard_payload(
                user_id,
                f'CEO dashboard data unavailable: {exc.__class__.__name__}',
            ),
            status=200,
        )


@api_view(['GET'])
def ceo_home_view(request):
    user_id = request.query_params.get('user_id') or ''
    try:
        return Response(_ceo_home_payload(user_id))
    except Exception as exc:
        return Response(
            _empty_ceo_dashboard_payload(
                user_id,
                f'CEO home data unavailable: {exc.__class__.__name__}',
            ),
            status=200,
        )


def _ceo_home_payload(user_id=''):
    today = timezone.localdate()
    ceo = User.objects.filter(user_id=user_id, role='ceo').first()
    ceo_name = f'{ceo.first_name} {ceo.last_name}'.strip() or ceo.email if ceo else 'CEO'
    return {
        'success': True,
        'profile': {
            'id': ceo.user_id if ceo else user_id,
            'name': ceo_name,
            'first_name': ceo.first_name if ceo else '',
            'last_name': ceo.last_name if ceo else '',
            'email': ceo.email if ceo else '',
            'role': ceo.role if ceo else 'ceo',
            'role_label': ceo.get_role_display() if ceo else 'CEO',
            'designation_label': _role_label(ceo.occupation) if ceo and ceo.occupation else 'Chief Executive Officer',
            'photo_url': _passport_photo_for_email(ceo.email) if ceo else '',
            'status': 'Active' if ceo and ceo.is_active else 'Inactive',
        },
        'attendance_health': _ceo_attendance_health(today),
        'approvals_summary': _ceo_approvals_summary(),
        'employee_categories': _ceo_employee_category_summary(),
        'role_members': _ceo_role_members(user_id),
        'critical_alerts': _ceo_critical_alerts(today),
        'recent_members': _ceo_recent_members(user_id),
    }


@api_view(['GET', 'POST'])
def ceo_organization_view(request):
    user_id = (
        request.query_params.get('user_id')
        if request.method == 'GET'
        else request.data.get('user_id')
    ) or ''
    if request.method == 'POST':
        ceo = User.objects.filter(user_id=user_id, role='ceo', is_active=True).first()
        if ceo is None:
            return Response(
                {'success': False, 'message': 'Only an active CEO can update organization data.'},
                status=403,
            )
        action = str(request.data.get('action') or '').strip().lower()
        if action == 'update_details':
            name = str(request.data.get('name') or '').strip()
            if not name:
                return Response(
                    {'success': False, 'errors': {'name': 'Company name is required.'}},
                    status=400,
                )
            profile, _created = OrganizationProfile.objects.get_or_create(
                owner_user_id=user_id,
                defaults={'name': name},
            )
            field_map = {
                'name': 'name',
                'type': 'company_type',
                'industry': 'industry',
                'registration_number': 'registration_number',
                'founded_on': 'founded_on',
                'website': 'website',
                'email': 'email',
                'phone': 'phone',
                'address': 'address',
                'pan': 'pan',
                'gstin': 'gstin',
                'esi_number': 'esi_number',
                'pf_code': 'pf_code',
            }
            for request_key, model_field in field_map.items():
                setattr(profile, model_field, str(request.data.get(request_key) or '').strip())
            profile.save()
            return Response({'success': True, 'message': 'Organization details updated.'})

        if action == 'add_branch':
            name = str(request.data.get('name') or '').strip()
            city = str(request.data.get('city') or '').strip()
            if not name or not city:
                errors = {}
                if not name:
                    errors['name'] = 'Branch name is required.'
                if not city:
                    errors['city'] = 'City is required.'
                return Response({
                    'success': False,
                    'errors': errors,
                }, status=400)
            try:
                branch = OrganizationBranch.objects.create(
                    owner_user_id=user_id,
                    name=name,
                    city=city,
                    state=str(request.data.get('state') or '').strip(),
                    country=str(request.data.get('country') or '').strip(),
                    address=str(request.data.get('address') or '').strip(),
                    is_head_office=bool(request.data.get('is_head_office', False)),
                )
            except IntegrityError:
                return Response(
                    {'success': False, 'message': 'A branch with this name already exists.'},
                    status=400,
                )
            return Response({
                'success': True,
                'message': 'Branch added successfully.',
                'branch_id': branch.id,
            })

        if action == 'add_role':
            name = str(request.data.get('name') or '').strip()
            business_unit = str(request.data.get('business_unit') or '').strip()
            department = str(request.data.get('department') or '').strip()
            if not name or not business_unit:
                errors = {}
                if not name:
                    errors['name'] = 'Role name is required.'
                if not business_unit:
                    errors['business_unit'] = 'Business unit is required.'
                return Response({
                    'success': False,
                    'errors': errors,
                }, status=400)
            try:
                filled = max(0, int(request.data.get('filled_positions') or 0))
                vacant = max(0, int(request.data.get('vacant_positions') or 0))
            except (TypeError, ValueError):
                return Response(
                    {'success': False, 'message': 'Position counts must be valid numbers.'},
                    status=400,
                )
            try:
                role = OrganizationRole.objects.create(
                    owner_user_id=user_id,
                    name=name,
                    business_unit=business_unit,
                    department=department,
                    reports_to=str(request.data.get('reports_to') or '').strip(),
                    filled_positions=filled,
                    vacant_positions=vacant,
                )
            except IntegrityError:
                return Response(
                    {'success': False, 'message': 'This role already exists in the department.'},
                    status=400,
                )
            return Response({
                'success': True,
                'message': 'Role added successfully.',
                'role_id': role.id,
            })

        return Response(
            {'success': False, 'message': 'Unsupported organization action.'},
            status=400,
        )

    payload = _ceo_organization_overview(user_id)
    payload['success'] = True
    return Response(payload)


@api_view(['GET'])
def ceo_employees_view(request):
    user_id = request.query_params.get('user_id') or ''
    employees = _employee_directory_items(include_attendance=False)
    created_members = _ceo_recent_members(user_id, limit=100)
    active_employees = _ceo_active_employee_list(limit=100)
    return Response({
        'success': True,
        'total_employees': len(employees),
        'total_created_members': len(created_members),
        'employees': employees,
        'created_members': created_members,
        'active_employees': active_employees,
        'role_members': _ceo_role_members(user_id),
    })


@api_view(['GET'])
def md_dashboard_view(request):
    user_id = request.GET.get('user_id', '').strip()
    if '/director/' in request.path and not User.objects.filter(
        user_id=user_id,
        role='director',
        is_active=True,
    ).exists():
        return Response(
            {'success': False, 'message': 'Only an active Executive Director can access this dashboard.'},
            status=403,
        )
    # MD needs an organization-wide view, including seeded meetings created by
    # other leadership roles, not only rows created with the exact MD user id.
    meeting_queryset = MdMeeting.objects.all().order_by('-id')
    meetings = [_md_meeting_payload(item) for item in meeting_queryset[:30]]
    today_label = timezone.localdate().strftime('%d-%m-%Y')
    revenue = _ceo_monthly_revenue()
    return Response({
        'success': True,
        'total_revenue': revenue.get('revenue', 'Rs. 0'),
        'total_employees': _employee_count(),
        'pending_approvals': EmployeeLeaveRequest.objects.filter(status='pending').count(),
        'meetings_today': meeting_queryset.filter(date_label=today_label).count(),
        'meetings': meetings,
        'participants': [
            {
                'name': item['name'],
                'role': item['role'],
                'selected': False,
            }
            for item in _employee_directory_items(include_attendance=False, limit=100)
        ],
    })


@api_view(['POST'])
def md_meetings_view(request):
    if '/director/' in request.path:
        user_id = str(request.data.get('created_by') or '').strip()
        if not User.objects.filter(
            user_id=user_id,
            role='director',
            is_active=True,
        ).exists():
            return Response(
                {'success': False, 'message': 'Only an active Executive Director can schedule meetings.'},
                status=403,
            )
    meeting = _create_meeting_from_payload(request.data, 'Meeting')
    _notify_meeting_participants(meeting)
    email_count = 0
    email_error = ''
    if request.data.get('invite_email', True):
        try:
            email_count = _send_meeting_invite(meeting)
        except Exception as error:
            email_error = str(error)
    return Response({
        'success': True,
        'message': 'Meeting scheduled.',
        'meeting': _md_meeting_payload(meeting),
        'email_sent_to': email_count,
        'email_error': email_error,
    })


@api_view(['GET'])
def md_module_view(request, module):
    """Database-only data source for each dedicated MD More flow."""
    user_id = request.GET.get('user_id', '').strip()
    if '/director/' in request.path and not User.objects.filter(
        user_id=user_id,
        role='director',
        is_active=True,
    ).exists():
        return Response(
            {'success': False, 'message': 'Only an active Executive Director can access this module.'},
            status=403,
        )
    module = str(module or '').strip().lower().replace('_', '-')
    today = timezone.localdate()
    title = module.replace('-', ' ').title()
    items = []

    if module == 'company-overview':
        profiles = OrganizationProfile.objects.all()[:20]
        items = [
            {'title': item.name, 'subtitle': item.industry or item.company_type, 'detail': item.address}
            for item in profiles
        ]
    elif module == 'financial-insights':
        items = [
            {
                'title': f'{item.department or "Organization"} · {item.financial_year}',
                'subtitle': f'Allocated: {_format_inr(item.allocated_amount)}',
                'detail': f'Spent: {_format_inr(item.spent_amount)} · {item.status.title()}',
            }
            for item in BudgetPlan.objects.all()[:50]
        ]
    elif module == 'department-performance':
        items = [
            {
                'title': item.name,
                'subtitle': item.code,
                'detail': item.location or ('Active' if item.is_active else 'Inactive'),
            }
            for item in OrganizationDepartment.objects.all()[:50]
        ]
    elif module == 'project-portfolio':
        items = [
            {
                'title': item.name,
                'subtitle': f'{item.department} · {item.get_status_display()}',
                'detail': f'{item.progress}% complete · Budget {_format_inr(item.budget)}',
            }
            for item in Project.objects.all()[:50]
        ]
    elif module == 'approvals-center':
        items = [
            {
                'title': item.title,
                'subtitle': f'{item.requester_name or item.requester_user_id} · {item.priority}',
                'detail': item.status.title(),
            }
            for item in WorkflowApprovalRequest.objects.all()[:50]
        ]
    elif module == 'workforce-analytics':
        items = [
            {
                'title': f'{item.registration.first_name} {item.registration.last_name}'.strip(),
                'subtitle': f'{item.employee_id} · {item.department}',
                'detail': item.get_designation_display(),
            }
            for item in EmployeeAccount.objects.select_related('registration').filter(is_active=True)[:100]
        ]
    elif module == 'leadership-team':
        items = [
            {
                'title': f'{item.first_name} {item.last_name}'.strip() or item.email,
                'subtitle': item.get_role_display(),
                'detail': item.department,
            }
            for item in User.objects.filter(role__in=['ceo', 'md', 'director', 'hr', 'manager', 'tl'])[:50]
        ]
    elif module == 'critical-alerts':
        items = [
            {
                'title': item.get('title', ''),
                'subtitle': item.get('subtitle', ''),
                'detail': item.get('severity', '').title(),
            }
            for item in _ceo_critical_alerts(today)
        ]
    elif module == 'executive-reports':
        items = [
            {
                'title': item.report_type.replace('_', ' ').title(),
                'subtitle': item.file_format.upper(),
                'detail': item.status.title(),
            }
            for item in ReportExportHistory.objects.all()[:50]
        ]
    elif module == 'meetings':
        items = [
            {
                'title': item.title,
                'subtitle': f'{item.date_label} · {item.time_label}',
                'detail': item.status.title(),
            }
            for item in MdMeeting.objects.all()[:50]
        ]
    elif module == 'announcements':
        items = [
            {'title': item.title, 'subtitle': item.message, 'detail': item.status.title()}
            for item in Announcement.objects.all()[:50]
        ]
    elif module == 'documents':
        items = [
            {
                'title': item.name,
                'subtitle': f'{len(item.documents or [])} organization documents',
                'detail': item.updated_at.isoformat(),
            }
            for item in OrganizationProfile.objects.all()[:20]
        ]
    elif module == 'settings-preferences':
        users = User.objects.filter(user_id=user_id) if user_id else User.objects.none()
        items = [
            {
                'title': f'{item.first_name} {item.last_name}'.strip() or item.email,
                'subtitle': item.email,
                'detail': f'{item.get_role_display()} · {item.department}',
            }
            for item in users
        ]
    else:
        return Response({'success': False, 'message': 'MD module not found'}, status=404)

    return Response({'success': True, 'module': module, 'title': title, 'items': items})


@api_view(['GET'])
def ceo_analytics_view(request):
    data = _ceo_common_payload(request.query_params.get('user_id') or '')
    data.update({
        'employee_growth': f"+{data['total_employees']}",
        'employee_growth_bars': [42, 68, 82, 54, 78, 72],
        'bars': data['revenue_bars'],
    })
    return Response(data)


@api_view(['GET'])
def ceo_reports_view(request):
    data = _ceo_common_payload(request.query_params.get('user_id') or '')
    return Response({
        'success': True,
        'reports': [
            {'type': 'hr', 'title': 'HR Reports', 'subtitle': f"{_employee_count()} employees", 'chart_title': 'Department Wise Employees', 'trend': f"+{data['active_employees']}", 'bars': [42, 70, 82, 74, 64]},
            {'type': 'finance', 'title': 'Finance Reports', 'subtitle': data['revenue'], 'chart_title': 'Revenue Overview', 'trend': data['revenue_trend'], 'bars': data['revenue_bars']},
            {'type': 'attendance', 'title': 'Attendance Reports', 'subtitle': f"{data['attendance']} present today", 'chart_title': 'Attendance Overview', 'trend': '+0%', 'bars': [45, 50, 48, 52, 58, 60]},
            {'type': 'leave', 'title': 'Leave Reports', 'subtitle': f"{EmployeeLeaveRequest.objects.count()} leave requests", 'chart_title': 'Leave Requests', 'trend': '+0%', 'bars': [10, 18, 12, 24, 16, 20]},
            {'type': 'payroll', 'title': 'Payroll Reports', 'subtitle': f"{data['payroll_cost']} this month", 'chart_title': 'Payroll Cost', 'trend': '+0%', 'bars': [20, 24, 22, 28, 26, 30]},
            {'type': 'performance', 'title': 'Performance Reports', 'subtitle': f"{_department_count()} departments", 'chart_title': 'Department Performance', 'trend': '+0%', 'bars': [70, 78, 75, 82, 80, 84]},
        ],
    })


@api_view(['GET'])
def ceo_approvals_view(request):
    approvals = [_leave_dashboard_item(item) for item in _active_pending_leave_queryset()[:20]]
    today = timezone.localdate()
    history_queryset = EmployeeLeaveRequest.objects.filter(
        Q(status__in=['approved', 'rejected']) |
        Q(hr_status__in=['approved', 'rejected']) |
        Q(tl_status__in=['approved', 'rejected']) |
        Q(status='pending', to_date__lt=today)
    ).order_by('-from_date')[:50]
    history = [_leave_dashboard_item(item) for item in history_queryset]
    return Response({
        'success': True,
        'summary': _ceo_approvals_summary(),
        'approvals': approvals,
        'history': history,
    })


@api_view(['GET'])
def ceo_approval_category_view(request, category):
    categories = {item['key']: item for item in _ceo_approvals_summary()}
    if category not in categories:
        return Response(
            {'success': False, 'message': 'Approval category not found.'},
            status=404,
        )
    history = str(request.query_params.get('history', '')).lower() in {
        '1', 'true', 'yes',
    }
    return Response({
        'success': True,
        'category': categories[category],
        'history': history,
        'items': _ceo_approval_category_items(category, history=history),
    })


@api_view(['GET'])
def ceo_leave_detail_view(request, pk):
    try:
        leave = EmployeeLeaveRequest.objects.get(pk=pk)
    except EmployeeLeaveRequest.DoesNotExist:
        return Response({'success': False, 'message': 'Leave request not found.'}, status=404)
    return Response({'success': True, 'leave': _leave_dashboard_item(leave)})


@api_view(['GET'])
def ceo_leave_intelligence_view(request):
    user_id = str(request.query_params.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id, role='ceo', is_active=True).exists():
        return Response(
            {'success': False, 'message': 'Only an active CEO can view leave intelligence.'},
            status=403,
        )

    today = timezone.localdate()
    try:
        year = int(request.query_params.get('year') or today.year)
        month = int(request.query_params.get('month') or today.month)
        month_start = date(year, month, 1)
    except (TypeError, ValueError):
        return Response({'success': False, 'message': 'Invalid year or month.'}, status=400)
    month_end = date(year, month, calendar.monthrange(year, month)[1])

    queryset = EmployeeLeaveRequest.objects.all().order_by('-created_at')
    requests = [_leave_dashboard_item(item) for item in queryset[:250]]
    month_records = list(queryset.filter(from_date__lte=month_end, to_date__gte=month_start))
    status_counts = {
        status: queryset.filter(status=status).count()
        for status in ('pending', 'approved', 'rejected')
    }

    calendar_items = []
    for leave in month_records:
        calendar_items.append({
            'id': leave.id,
            'employee_id': leave.employee_id,
            'name': _employee_name(leave.employee_id),
            'leave_type': leave.leave_type,
            'status': leave.status,
            'from_date': leave.from_date.isoformat(),
            'to_date': leave.to_date.isoformat(),
            'days': leave.total_days,
        })

    type_totals = {}
    for leave in queryset:
        bucket = type_totals.setdefault(leave.leave_type or 'Other', {'count': 0, 'days': 0})
        bucket['count'] += 1
        bucket['days'] += leave.total_days or 0

    trend = []
    for trend_month in range(1, 13):
        month_query = queryset.filter(from_date__year=year, from_date__month=trend_month)
        trend.append({
            'month': calendar.month_abbr[trend_month],
            'approved': month_query.filter(status='approved').count(),
            'pending': month_query.filter(status='pending').count(),
            'rejected': month_query.filter(status='rejected').count(),
        })

    balance_totals = {}
    accounts = list(EmployeeAccount.objects.filter(is_active=True))
    for account in accounts:
        for item in _leave_balance_payload(account.employee_id, account).get('types', []):
            name = item.get('type') or 'Other'
            bucket = balance_totals.setdefault(
                name, {'type': name, 'available': 0.0, 'entitlement': 0.0, 'used': 0.0},
            )
            for key in ('available', 'entitlement', 'used'):
                bucket[key] += float(item.get(key) or 0)

    return Response({
        'success': True,
        'generated_at': timezone.now().isoformat(),
        'year': year,
        'month': month,
        'summary': {'total': queryset.count(), **status_counts},
        'requests': requests,
        'calendar': calendar_items,
        'balances': list(balance_totals.values()),
        'types': [{'type': key, **value} for key, value in type_totals.items()],
        'trend': trend,
    })


@api_view(['GET', 'POST'])
def ceo_payroll_overview_view(request):
    source = request.query_params if request.method == 'GET' else request.data
    user_id = str(source.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id, role='ceo', is_active=True).exists():
        return Response(
            {'success': False, 'message': 'Only an active CEO can manage payroll.'},
            status=403,
        )

    today = timezone.localdate()
    try:
        year = int(source.get('year') or today.year)
        month = int(source.get('month') or today.month)
        period_end = date(year, month, calendar.monthrange(year, month)[1])
    except (TypeError, ValueError):
        return Response({'success': False, 'message': 'Invalid payroll period.'}, status=400)
    if month < 1 or month > 12:
        return Response({'success': False, 'message': 'Payroll month must be between 1 and 12.'}, status=400)

    process, _ = PayrollProcess.objects.get_or_create(year=year, month=month)
    accounts = list(
        EmployeeAccount.objects.filter(is_active=True).select_related('registration')
    )
    validation_date = min(today, period_end)
    validation = _hr_payroll_validation(accounts, validation_date)

    if request.method == 'POST':
        action = str(request.data.get('action') or '').strip().lower()
        now = timezone.now()
        if action == 'start':
            if process.status != 'inputs':
                return Response({'success': False, 'message': 'Payroll processing has already started.'}, status=409)
            process.status = 'validation'
            process.prepared_by = user_id
        elif action == 'validate':
            if process.status != 'validation':
                return Response({'success': False, 'message': 'Payroll is not at the validation stage.'}, status=409)
            unresolved = _payroll_unresolved_count(validation, process.resolved_issues)
            if unresolved:
                return Response(
                    {'success': False, 'message': f'{unresolved} payroll validation issue(s) remain.'},
                    status=409,
                )
            process.status = 'calculation'
            process.validated_at = now
        elif action == 'calculate':
            if process.status != 'calculation':
                return Response({'success': False, 'message': 'Payroll must be validated before calculation.'}, status=409)
            generate_payroll_for_month(year, month, user_id)
            Payslip.objects.filter(year=year, month=month).update(status='draft')
            process.status = 'approval'
            process.calculated_at = now
        elif action == 'publish':
            if process.status == 'published':
                return Response(
                    {'success': False, 'message': 'Payroll is already published for this period.'},
                    status=409,
                )
            if process.status != 'approval':
                return Response(
                    {'success': False, 'message': 'Payroll must be calculated before publishing.'},
                    status=409,
                )
            declaration = request.data.get('declaration') is True
            if not declaration:
                return Response({'success': False, 'message': 'CEO declaration is required.'}, status=400)
            payslips_to_publish = list(Payslip.objects.filter(year=year, month=month))
            if not payslips_to_publish:
                return Response({'success': False, 'message': 'No calculated payslips to publish.'}, status=409)
            Payslip.objects.filter(year=year, month=month).update(status='approved')
            process.status = 'published'
            process.approved_at = now
            process.published_at = now
            process.publishing_options = {'declaration': True, 'published_by': user_id}
        else:
            return Response({'success': False, 'message': 'Unsupported payroll action.'}, status=400)
        process.save()

    payslips = list(
        Payslip.objects.filter(year=year, month=month).order_by('employee_id')
    )
    totals = Payslip.objects.filter(year=year, month=month).aggregate(
        gross=Sum('gross_salary'),
        earnings=Sum('total_earnings'),
        deductions=Sum('total_deductions'),
        net=Sum('net_salary'),
    )
    earning_breakdown = {}
    deduction_breakdown = {}
    department_costs = {}
    employee_items = []
    account_lookup = {account.employee_id: account for account in accounts}
    for payslip in payslips:
        account = account_lookup.get(payslip.employee_id)
        for key, value in (payslip.earnings or {}).items():
            earning_breakdown[key] = earning_breakdown.get(key, 0) + float(value or 0)
        for key, value in (payslip.deductions or {}).items():
            deduction_breakdown[key] = deduction_breakdown.get(key, 0) + float(value or 0)
        department = account.get_department_display() if account else 'Unassigned'
        department_costs[department] = department_costs.get(department, 0) + float(payslip.net_salary)
        item = _hr_payroll_item(payslip)
        item['id'] = payslip.id
        item['paid_date'] = payslip.paid_date.isoformat() if payslip.paid_date else ''
        try:
            pdf_url = payslip.pdf_file.url if payslip.pdf_file else ''
        except ValueError:
            pdf_url = ''
        item['download_url'] = request.build_absolute_uri(pdf_url) if pdf_url.startswith('/') else pdf_url
        employee_items.append(item)

    active = len(accounts)
    return Response({
        'success': True,
        'year': year,
        'month': month,
        'period': f'{calendar.month_name[month]} {year}',
        'process': _payroll_process_payload(process),
        'employees': {
            'active': active,
            'processed': len(payslips),
            'pending': max(active - len(payslips), 0),
        },
        'totals': {key: str(value or 0) for key, value in totals.items()},
        'earnings': [{'name': key, 'amount': value} for key, value in earning_breakdown.items()],
        'deductions': [{'name': key, 'amount': value} for key, value in deduction_breakdown.items()],
        'departments': [
            {'name': key, 'amount': value}
            for key, value in sorted(department_costs.items(), key=lambda item: item[1], reverse=True)
        ],
        'validation': validation,
        'unresolved_issues': _payroll_unresolved_count(validation, process.resolved_issues),
        'payslips': employee_items,
    })


@api_view(['GET'])
def ceo_documents_view(request):
    user_id = str(request.query_params.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id, role='ceo', is_active=True).exists():
        return Response(
            {'success': False, 'message': 'Only an active CEO can view documents.'},
            status=403,
        )

    documents = []

    def add_document(document_id, category, title, url, owner='', employee_id='', status='', created_at=''):
        clean_url = str(url or '').strip()
        if not clean_url:
            return
        if clean_url.startswith('/'):
            clean_url = request.build_absolute_uri(clean_url)
        extension = clean_url.split('?')[0].rsplit('.', 1)[-1].lower() if '.' in clean_url.split('?')[0] else ''
        documents.append({
            'id': str(document_id),
            'category': category,
            'title': title,
            'url': clean_url,
            'owner': owner,
            'employee_id': employee_id,
            'status': status or 'Available',
            'extension': extension,
            'created_at': created_at,
        })

    for registration in EmployeeRegistration.objects.all().order_by('-submitted_at'):
        serialized = EmployeeRegistrationSerializer(registration).data
        owner = f'{registration.first_name} {registration.last_name}'.strip() or registration.personal_email
        account = EmployeeAccount.objects.filter(registration=registration).first()
        employee_id = account.employee_id if account else ''
        statuses = registration.document_statuses or {}
        for key, label in DOCUMENT_FIELD_LABELS.items():
            status_data = statuses.get(key, {}) if isinstance(statuses.get(key), dict) else {}
            add_document(
                f'employee:{registration.pk}:{key}',
                'Employee Documents',
                label,
                serialized.get(key),
                owner=owner,
                employee_id=employee_id,
                status=status_data.get('status') or 'Uploaded',
                created_at=registration.submitted_at.isoformat() if registration.submitted_at else '',
            )

    for payslip in Payslip.objects.exclude(pdf_file='').order_by('-year', '-month', 'employee_id'):
        try:
            url = payslip.pdf_file.url if payslip.pdf_file else ''
        except ValueError:
            url = ''
        add_document(
            f'payslip:{payslip.pk}',
            'Payslips',
            f'Payslip - {calendar.month_name[payslip.month]} {payslip.year}',
            url,
            owner=_employee_name(payslip.employee_id),
            employee_id=payslip.employee_id,
            status=payslip.get_status_display(),
            created_at=payslip.generated_at.isoformat() if payslip.generated_at else '',
        )

    for leave in EmployeeLeaveRequest.objects.exclude(medical_certificate='').order_by('-created_at'):
        try:
            url = leave.medical_certificate.url if leave.medical_certificate else ''
        except ValueError:
            url = ''
        add_document(
            f'leave:{leave.pk}',
            'Leave Documents',
            f'{leave.leave_type} Medical Certificate',
            url,
            owner=_employee_name(leave.employee_id),
            employee_id=leave.employee_id,
            status=leave.get_status_display(),
            created_at=leave.created_at.isoformat() if leave.created_at else '',
        )

    for organization in OrganizationProfile.objects.filter(
        owner_user_id=user_id,
    ).order_by('-updated_at'):
        for index, item in enumerate(organization.documents or []):
            if not isinstance(item, dict):
                continue
            add_document(
                f'organization:{organization.pk}:{index}',
                'Organization Documents',
                item.get('name') or item.get('title') or 'Organization Document',
                item.get('url') or item.get('path') or item.get('file'),
                owner=organization.name,
                status=item.get('status') or 'Available',
                created_at=item.get('uploaded_at') or organization.updated_at.isoformat(),
            )

    categories = {}
    for item in documents:
        categories[item['category']] = categories.get(item['category'], 0) + 1
    return Response({
        'success': True,
        'total': len(documents),
        'categories': [{'name': key, 'count': value} for key, value in categories.items()],
        'documents': documents,
    })


@api_view(['GET', 'POST'])
def ceo_hiring_pipeline_view(request):
    source = request.query_params if request.method == 'GET' else request.data
    user_id = str(source.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id, role='ceo', is_active=True).exists():
        return Response({'success': False, 'message': 'Only an active CEO can manage hiring.'}, status=403)

    if request.method == 'POST':
        action = str(request.data.get('action') or '').strip().lower()
        if action == 'create_job':
            title = str(request.data.get('title') or '').strip()
            department = str(request.data.get('department') or '').strip()
            if not title or not department:
                return Response({'success': False, 'message': 'Job title and department are required.'}, status=400)
            try:
                openings = max(int(request.data.get('openings') or 1), 1)
            except (TypeError, ValueError):
                return Response({'success': False, 'message': 'Openings must be a valid number.'}, status=400)
            job = RecruitmentJobOpening.objects.create(
                title=title,
                department=department,
                location=str(request.data.get('location') or '').strip(),
                openings=openings,
                created_by=user_id,
            )
            return Response({'success': True, 'message': 'Job opening created.', 'job_id': job.id})
        candidate_id = request.data.get('candidate_id')
        try:
            candidate = EmployeeRegistration.objects.get(pk=candidate_id)
        except (EmployeeRegistration.DoesNotExist, TypeError, ValueError):
            return Response({'success': False, 'message': 'Candidate not found.'}, status=404)
        if action == 'move_stage':
            stage = str(request.data.get('stage') or '').strip().lower()
            allowed = {'applied', 'screening', 'interview', 'offer', 'hired', 'rejected'}
            if stage not in allowed:
                return Response({'success': False, 'message': 'Invalid candidate stage.'}, status=400)
            candidate.recruitment_stage = stage
        elif action == 'schedule_interview':
            candidate.interview_data = {
                **(candidate.interview_data or {}),
                'scheduled_at': request.data.get('scheduled_at') or '',
                'mode': request.data.get('mode') or '',
                'interviewers': request.data.get('interviewers') or '',
                'status': 'scheduled',
            }
            candidate.recruitment_stage = 'interview'
        elif action == 'feedback':
            try:
                rating = int(request.data.get('rating') or 0)
            except (TypeError, ValueError):
                return Response({'success': False, 'message': 'Rating must be between 1 and 5.'}, status=400)
            if rating < 1 or rating > 5:
                return Response({'success': False, 'message': 'Rating must be between 1 and 5.'}, status=400)
            candidate.interview_data = {
                **(candidate.interview_data or {}),
                'rating': rating,
                'feedback': request.data.get('feedback') or '',
                'status': 'completed',
            }
        elif action == 'extend_offer':
            candidate.offer_data = {
                'offered_at': timezone.now().isoformat(),
                'ctc': request.data.get('ctc') or '',
                'joining_date': request.data.get('joining_date') or '',
                'employment_type': request.data.get('employment_type') or '',
                'location': request.data.get('location') or '',
                'status': 'extended',
            }
            candidate.recruitment_stage = 'offer'
        elif action == 'offer_status':
            status_value = str(request.data.get('status') or '').strip().lower()
            if status_value not in {'extended', 'accepted', 'background_check'}:
                return Response({'success': False, 'message': 'Invalid offer status.'}, status=400)
            candidate.offer_data = {**(candidate.offer_data or {}), 'status': status_value}
        elif action == 'onboarding_check':
            key = str(request.data.get('key') or '').strip()
            checklist = dict(candidate.onboarding_checklist or {})
            checklist[key] = request.data.get('completed') is True
            candidate.onboarding_checklist = checklist
            if checklist and all(checklist.values()):
                candidate.recruitment_stage = 'hired'
        else:
            return Response({'success': False, 'message': 'Unsupported hiring action.'}, status=400)
        candidate.save()
        return Response({'success': True, 'message': 'Hiring pipeline updated.'})

    jobs = list(RecruitmentJobOpening.objects.all())
    candidates = list(EmployeeRegistration.objects.select_related('applied_job').all().order_by('-submitted_at'))
    stage_counts = {
        stage: sum(1 for candidate in candidates if candidate.recruitment_stage == stage)
        for stage in ('applied', 'screening', 'interview', 'offer', 'hired', 'rejected')
    }
    candidate_items = [{
        'id': item.id,
        'name': f'{item.first_name} {item.last_name}'.strip(),
        'email': item.personal_email,
        'phone': mask_phone_number(item.mobile),
        'qualification': item.qualification,
        'experience': item.prev_experience if item.is_experienced else 'Fresher',
        'applied_at': item.submitted_at.isoformat() if item.submitted_at else '',
        'stage': item.recruitment_stage,
        'job_id': item.applied_job_id,
        'job_title': item.applied_job.title if item.applied_job else 'Unassigned Position',
        'department': item.applied_job.department if item.applied_job else '',
        'interview': item.interview_data or {},
        'offer': item.offer_data or {},
        'onboarding': item.onboarding_checklist or {},
    } for item in candidates]
    job_items = [{
        'id': job.id,
        'title': job.title,
        'department': job.department,
        'location': job.location,
        'openings': job.openings,
        'status': job.status,
        'created_by': job.created_by,
        'applications': sum(1 for item in candidates if item.applied_job_id == job.id),
        'in_progress': sum(1 for item in candidates if item.applied_job_id == job.id and item.recruitment_stage not in {'hired', 'rejected'}),
        'created_at': job.created_at.isoformat(),
    } for job in jobs]
    return Response({
        'success': True,
        'summary': {'openings': sum(job.openings for job in jobs if job.status == 'open'), 'applications': len(candidates), **stage_counts},
        'jobs': job_items,
        'candidates': candidate_items,
    })


def _project_payload(project):
    tasks = list(TeamTask.objects.filter(project=project.name))
    task_counts = {
        status: sum(1 for task in tasks if task.status == status)
        for status in ('pending', 'in_progress', 'completed')
    }
    return {
        'id': project.id, 'name': project.name, 'code': project.code,
        'department': project.department, 'description': project.description,
        'status': project.status, 'start_date': project.start_date.isoformat() if project.start_date else '',
        'end_date': project.end_date.isoformat() if project.end_date else '',
        'budget': str(project.budget), 'spent': str(project.spent), 'progress': project.progress,
        'manager_id': project.manager_id, 'manager_name': project.manager_name,
        'manager_email': project.manager_email, 'team': project.team or [],
        'milestones': project.milestones or [], 'progress_history': project.progress_history or [],
        'task_counts': task_counts, 'total_tasks': len(tasks),
        'tasks': [_ceo_project_task_payload(task) for task in tasks],
        'updated_at': project.updated_at.isoformat(),
    }


def _ceo_project_task_payload(task):
    return {
        'id': task.id, 'title': task.title, 'project': task.project,
        'assignee_id': task.assignee_id, 'assignee_name': task.assignee_name,
        'assignee_email': task.assignee_email, 'priority': task.priority,
        'due_date': task.due_date, 'description': task.description,
        'status': task.status, 'created_at': task.created_at.isoformat(),
    }


@api_view(['GET', 'POST'])
def ceo_projects_flow_view(request):
    source = request.query_params if request.method == 'GET' else request.data
    user_id = str(source.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id, role='ceo', is_active=True).exists():
        return Response({'success': False, 'message': 'Only an active CEO can manage projects.'}, status=403)

    if request.method == 'POST':
        action = str(request.data.get('action') or '').strip().lower()
        if action == 'create_project':
            name = str(request.data.get('name') or '').strip()
            code = str(request.data.get('code') or '').strip()
            if not name or not code:
                return Response({'success': False, 'message': 'Project name and code are required.'}, status=400)
            if Project.objects.filter(code__iexact=code).exists():
                return Response({'success': False, 'message': 'Project code already exists.'}, status=409)
            try:
                start_date = datetime.strptime(str(request.data.get('start_date') or ''), '%Y-%m-%d').date()
                end_date = datetime.strptime(str(request.data.get('end_date') or ''), '%Y-%m-%d').date()
                budget = float(request.data.get('budget') or 0)
            except (TypeError, ValueError):
                return Response({'success': False, 'message': 'Use valid dates and budget.'}, status=400)
            project = Project.objects.create(
                name=name, code=code, department=request.data.get('department') or '',
                description=request.data.get('description') or '', start_date=start_date,
                end_date=end_date, budget=budget, created_by=user_id,
                progress_history=[{'date': timezone.localdate().isoformat(), 'progress': 0}],
            )
            return Response({'success': True, 'message': 'Project created.', 'project': _project_payload(project)})
        try:
            project = Project.objects.get(pk=request.data.get('project_id'))
        except (Project.DoesNotExist, TypeError, ValueError):
            return Response({'success': False, 'message': 'Project not found.'}, status=404)
        if action == 'update_project':
            for field in ('status', 'description', 'manager_id', 'manager_name', 'manager_email'):
                if field in request.data:
                    setattr(project, field, request.data.get(field) or '')
            if 'spent' in request.data:
                project.spent = max(float(request.data.get('spent') or 0), 0)
        elif action == 'add_member':
            member = request.data.get('member') if isinstance(request.data.get('member'), dict) else {}
            if not member.get('id') or not member.get('name'):
                return Response({'success': False, 'message': 'Member id and name are required.'}, status=400)
            team = list(project.team or [])
            if not any(str(item.get('id')) == str(member['id']) for item in team if isinstance(item, dict)):
                team.append(member)
            project.team = team
        elif action == 'add_milestone':
            title = str(request.data.get('title') or '').strip()
            if not title:
                return Response({'success': False, 'message': 'Milestone title is required.'}, status=400)
            milestones = list(project.milestones or [])
            milestones.append({'id': timezone.now().timestamp(), 'title': title, 'due_date': request.data.get('due_date') or '', 'progress': 0, 'status': 'pending'})
            project.milestones = milestones
        elif action == 'update_milestone':
            milestone_id = str(request.data.get('milestone_id'))
            milestones = list(project.milestones or [])
            for milestone in milestones:
                if str(milestone.get('id')) == milestone_id:
                    milestone['progress'] = max(0, min(int(request.data.get('progress') or 0), 100))
                    milestone['status'] = 'completed' if milestone['progress'] == 100 else 'in_progress'
            project.milestones = milestones
        elif action == 'create_task':
            TeamTask.objects.create(
                title=request.data.get('title') or 'Project Task', project=project.name,
                assignee_id=request.data.get('assignee_id') or '', assignee_name=request.data.get('assignee_name') or '',
                assignee_email=request.data.get('assignee_email') or '', priority=request.data.get('priority') or 'Medium',
                due_date=request.data.get('due_date') or '', description=request.data.get('description') or '', created_by=user_id,
            )
        elif action == 'update_task':
            try:
                task = TeamTask.objects.get(pk=request.data.get('task_id'), project=project.name)
            except TeamTask.DoesNotExist:
                return Response({'success': False, 'message': 'Task not found.'}, status=404)
            status_value = request.data.get('status')
            if status_value not in {'pending', 'in_progress', 'completed'}:
                return Response({'success': False, 'message': 'Invalid task status.'}, status=400)
            task.status = status_value
            task.save()
        else:
            return Response({'success': False, 'message': 'Unsupported project action.'}, status=400)

        tasks = list(TeamTask.objects.filter(project=project.name))
        if tasks:
            project.progress = round(sum(100 if task.status == 'completed' else 50 if task.status == 'in_progress' else 0 for task in tasks) / len(tasks))
        history = list(project.progress_history or [])
        today_key = timezone.localdate().isoformat()
        history = [item for item in history if item.get('date') != today_key]
        history.append({'date': today_key, 'progress': project.progress})
        project.progress_history = history[-24:]
        if project.progress == 100:
            project.status = 'completed'
        elif project.progress > 0 and project.status == 'not_started':
            project.status = 'in_progress'
        project.save()
        return Response({'success': True, 'message': 'Project updated.', 'project': _project_payload(project)})

    projects = list(Project.objects.all())
    payloads = [_project_payload(project) for project in projects]
    return Response({
        'success': True,
        'summary': {
            'total': len(projects),
            'active': sum(1 for item in projects if item.status == 'in_progress'),
            'completed': sum(1 for item in projects if item.status == 'completed'),
            'on_hold': sum(1 for item in projects if item.status == 'on_hold'),
            'at_risk': sum(1 for item in projects if item.status == 'at_risk'),
            'average_progress': round(sum(item.progress for item in projects) / len(projects)) if projects else 0,
        },
        'projects': payloads,
    })


@api_view(['GET', 'POST'])
def ceo_performance_matrix_view(request):
    source = request.query_params if request.method == 'GET' else request.data
    user_id = str(source.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id, role='ceo', is_active=True).exists():
        return Response({'success': False, 'message': 'Only an active CEO can manage performance reviews.'}, status=403)
    period = str(source.get('period') or '').strip()
    if not period:
        today = timezone.localdate()
        period = f'Q{((today.month - 1) // 3) + 1} {today.year}'
    if request.method == 'POST':
        employee_id = str(request.data.get('employee_id') or '').strip()
        if not EmployeeAccount.objects.filter(employee_id=employee_id, is_active=True).exists():
            return Response({'success': False, 'message': 'Active employee not found.'}, status=404)
        review, _ = EmployeePerformance.objects.get_or_create(employee_id=employee_id, period=period)
        action = str(request.data.get('action') or '').strip().lower()
        if action == 'save_goals':
            review.goals = request.data.get('goals') if isinstance(request.data.get('goals'), list) else []
            review.kpis = request.data.get('kpis') if isinstance(request.data.get('kpis'), dict) else {}
        elif action in {'save_review', 'submit_review'}:
            try:
                potential = float(request.data.get('potential_score') or 0)
                performance = float(request.data.get('performance_score') or 0)
            except (TypeError, ValueError):
                return Response({'success': False, 'message': 'Scores must be numeric.'}, status=400)
            if not 0 <= potential <= 5 or not 0 <= performance <= 5:
                return Response({'success': False, 'message': 'Scores must be between 0 and 5.'}, status=400)
            review.potential_score = potential
            review.performance_score = performance
            review.competency_scores = request.data.get('competency_scores') if isinstance(request.data.get('competency_scores'), dict) else {}
            review.reviewer_comments = request.data.get('reviewer_comments') or ''
            review.reviewed_by = user_id
            if action == 'submit_review':
                review.status = 'submitted'
                review.reviewed_at = timezone.now()
        else:
            return Response({'success': False, 'message': 'Unsupported performance action.'}, status=400)
        review.save()
        return Response({'success': True, 'message': 'Performance record saved.'})

    accounts = list(EmployeeAccount.objects.filter(is_active=True).select_related('registration'))
    reviews = {item.employee_id: item for item in EmployeePerformance.objects.filter(period=period)}
    employees = []
    for account in accounts:
        review = reviews.get(account.employee_id)
        employees.append({
            'employee_id': account.employee_id, 'name': _employee_name(account.employee_id),
            'designation': account.get_designation_display(), 'department': account.get_department_display(),
            'email': account.employee_email, 'period': period,
            'goals': review.goals if review else [], 'kpis': review.kpis if review else {},
            'potential_score': float(review.potential_score) if review else 0,
            'performance_score': float(review.performance_score) if review else 0,
            'competency_scores': review.competency_scores if review else {},
            'reviewer_comments': review.reviewer_comments if review else '',
            'status': review.status if review else 'not_started',
            'reviewed_at': review.reviewed_at.isoformat() if review and review.reviewed_at else '',
        })
    scored = [item for item in employees if item['performance_score'] > 0]
    departments = {}
    for item in scored:
        bucket = departments.setdefault(item['department'], [])
        bucket.append(item['performance_score'])
    return Response({
        'success': True, 'period': period,
        'summary': {
            'total_employees': len(employees), 'completed_reviews': sum(1 for item in employees if item['status'] == 'submitted'),
            'high_performers': sum(1 for item in scored if item['performance_score'] >= 4),
            'at_risk': sum(1 for item in scored if item['performance_score'] < 2.5),
            'overall_score': round(sum(item['performance_score'] for item in scored) / len(scored), 2) if scored else 0,
        },
        'departments': [{'name': key, 'score': round(sum(values) / len(values), 2)} for key, values in departments.items()],
        'employees': employees,
    })


REPORT_TYPES = [
    {'key':'attendance','title':'Monthly Attendance Summary','category':'Attendance'},
    {'key':'headcount','title':'Department Wise Headcount','category':'Workforce'},
    {'key':'payroll','title':'Payroll Summary','category':'Payroll'},
    {'key':'leave','title':'Leave Summary','category':'Leave'},
    {'key':'demographics','title':'Employee Demographics','category':'Workforce'},
    {'key':'performance','title':'Performance Summary','category':'Performance'},
    {'key':'overtime','title':'Overtime Summary','category':'Attendance'},
    {'key':'joins_exits','title':'New Joins & Exits','category':'Workforce'},
]


def _report_preview(report_type, filters):
    start = datetime.strptime(filters.get('date_from') or '2000-01-01', '%Y-%m-%d').date()
    end = datetime.strptime(filters.get('date_to') or timezone.localdate().isoformat(), '%Y-%m-%d').date()
    department = str(filters.get('department') or 'All')
    accounts = EmployeeAccount.objects.filter(is_active=True).select_related('registration')
    if department != 'All': accounts = accounts.filter(department=department)
    ids = list(accounts.values_list('employee_id', flat=True))
    rows=[]; summary={}
    if report_type in {'attendance','overtime'}:
        records=EmployeeAttendanceRecord.objects.filter(employee_id__in=ids,attendance_date__range=(start,end))
        for r in records:
            rows.append({'Employee ID':r.employee_id,'Date':r.attendance_date.isoformat(),'Status':r.status,'Hours':r.working_hours or ''})
        summary={'Records':len(rows),'Present':records.filter(status__icontains='present').count(),'Late':records.filter(status__icontains='late').count()}
    elif report_type=='payroll':
        slips=Payslip.objects.filter(employee_id__in=ids,year__gte=start.year,year__lte=end.year)
        for p in slips: rows.append({'Employee ID':p.employee_id,'Period':f'{p.month:02d}/{p.year}','Earnings':str(p.total_earnings),'Deductions':str(p.total_deductions),'Net':str(p.net_salary)})
        summary={'Employees':slips.values('employee_id').distinct().count(),'Net Payroll':str(slips.aggregate(v=Sum('net_salary'))['v'] or 0)}
    elif report_type=='leave':
        qs=EmployeeLeaveRequest.objects.filter(employee_id__in=ids,from_date__lte=end,to_date__gte=start)
        for x in qs: rows.append({'Employee ID':x.employee_id,'Type':x.leave_type,'From':x.from_date.isoformat(),'To':x.to_date.isoformat(),'Days':x.total_days,'Status':x.status})
        summary={'Total':qs.count(),'Approved':qs.filter(status='approved').count(),'Pending':qs.filter(status='pending').count()}
    elif report_type=='performance':
        qs=EmployeePerformance.objects.filter(employee_id__in=ids)
        for x in qs: rows.append({'Employee ID':x.employee_id,'Period':x.period,'Performance':str(x.performance_score),'Potential':str(x.potential_score),'Status':x.status})
        summary={'Reviews':qs.count(),'Submitted':qs.filter(status='submitted').count()}
    else:
        for a in accounts: rows.append({'Employee ID':a.employee_id,'Name':_employee_name(a.employee_id),'Department':a.get_department_display(),'Designation':a.get_designation_display(),'Joined':a.date_of_joining.isoformat()})
        summary={'Employees':len(rows),'Departments':len(set(row['Department'] for row in rows))}
    return {'summary':summary,'rows':rows,'total_records':len(rows)}


@api_view(['GET','POST'])
def ceo_reports_flow_view(request):
    source=request.query_params if request.method=='GET' else request.data
    user_id=str(source.get('user_id') or '').strip()
    if not User.objects.filter(user_id=user_id,role='ceo',is_active=True).exists(): return Response({'success':False,'message':'Only an active CEO can access reports.'},status=403)
    if request.method=='POST':
        action=str(request.data.get('action') or '')
        report_type=str(request.data.get('report_type') or '')
        if report_type not in {item['key'] for item in REPORT_TYPES}: return Response({'success':False,'message':'Invalid report type.'},status=400)
        filters=request.data.get('filters') if isinstance(request.data.get('filters'),dict) else {}
        try: preview=_report_preview(report_type,filters)
        except ValueError: return Response({'success':False,'message':'Use valid YYYY-MM-DD report dates.'},status=400)
        if action=='preview': return Response({'success':True,'report_type':report_type,'filters':filters,'generated_at':timezone.now().isoformat(),**preview})
        if action=='schedule':
            schedule=ReportSchedule.objects.create(owner_user_id=user_id,report_type=report_type,filters=filters,format=request.data.get('format') or 'pdf',frequency=request.data.get('frequency') or 'monthly',recipients=request.data.get('recipients') if isinstance(request.data.get('recipients'),list) else [])
            return Response({'success':True,'message':'Report schedule saved.','schedule_id':schedule.id})
        return Response({'success':False,'message':'Unsupported report action.'},status=400)
    return Response({'success':True,'templates':REPORT_TYPES,'employees':EmployeeAccount.objects.filter(is_active=True).count(),'departments':list(EmployeeAccount.objects.filter(is_active=True).values_list('department',flat=True).distinct()),'recent_reports':[{'id':x.id,'report_type':x.report_type,'format':x.format,'frequency':x.frequency,'created_at':x.created_at.isoformat()} for x in ReportSchedule.objects.filter(owner_user_id=user_id)[:10]]})


def _audit_queryset(filters):
    qs = AppNotification.objects.all()
    query = str(filters.get('search') or '').strip()
    user = str(filters.get('user') or '').strip()
    modules = filters.get('modules') if isinstance(filters.get('modules'), list) else []
    severities = filters.get('severities') if isinstance(filters.get('severities'), list) else []
    if query:
        qs = qs.filter(Q(title__icontains=query) | Q(message__icontains=query) |
                       Q(module__icontains=query) | Q(reference_id__icontains=query))
    if user and user != 'All':
        qs = qs.filter(Q(recipient_user_id=user) | Q(recipient_role=user))
    if modules and 'All' not in modules: qs = qs.filter(module__in=modules)
    if severities and 'All' not in severities: qs = qs.filter(notification_type__in=severities)
    try:
        if filters.get('date_from'):
            qs = qs.filter(created_at__date__gte=datetime.strptime(filters['date_from'], '%Y-%m-%d').date())
        if filters.get('date_to'):
            qs = qs.filter(created_at__date__lte=datetime.strptime(filters['date_to'], '%Y-%m-%d').date())
    except (TypeError, ValueError):
        raise ValueError('Use valid YYYY-MM-DD audit dates.')
    return qs


def _audit_payload(item):
    user = User.objects.filter(user_id=item.recipient_user_id).first()
    return {
        'id': item.id, 'event_id': f'LOG-{item.created_at:%Y%m%d}-{item.id:06d}',
        'title': item.title, 'description': item.message, 'module': item.module or 'system',
        'severity': item.notification_type, 'reference_id': item.reference_id,
        'user_id': item.recipient_user_id or item.recipient_role or 'System',
        'user_name': (f'{user.first_name} {user.last_name}'.strip() if user else '') or
                     item.recipient_user_id or item.recipient_role or 'System',
        'user_email': user.email if user else '', 'role': user.role if user else item.recipient_role,
        'is_read': item.is_read, 'created_at': item.created_at.isoformat(),
    }


def _simple_audit_pdf(rows):
    # Dependency-free, valid one-page PDF. Long reports remain available as CSV/XLS/JSON.
    lines = ['BitByte HRMS - CEO Audit Report', '']
    for row in rows[:45]:
        text = f"{str(row.get('created_at', ''))[:19]} | {row.get('severity', '')} | {row.get('module', '')} | {row.get('title', '')}"
        lines.append(text[:105])
    stream = ['BT', '/F1 9 Tf', '40 800 Td']
    for index, line in enumerate(lines):
        safe = line.replace('\\', '\\\\').replace('(', '\\(').replace(')', '\\)')
        if index: stream.append('0 -16 Td')
        stream.append(f'({safe}) Tj')
    stream.append('ET')
    body = '\n'.join(stream).encode('latin-1', 'replace')
    objects = [b'<< /Type /Catalog /Pages 2 0 R >>', b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
               b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
               b'<< /Length %d >>\nstream\n' % len(body) + body + b'\nendstream',
               b'<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>']
    pdf = bytearray(b'%PDF-1.4\n'); offsets = [0]
    for number, obj in enumerate(objects, 1):
        offsets.append(len(pdf)); pdf.extend(f'{number} 0 obj\n'.encode() + obj + b'\nendobj\n')
    xref = len(pdf); pdf.extend(f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode())
    for offset in offsets[1:]: pdf.extend(f'{offset:010d} 00000 n \n'.encode())
    pdf.extend(f'trailer << /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF'.encode())
    return bytes(pdf)


@api_view(['GET', 'POST'])
def ceo_audit_flow_view(request):
    source = request.query_params if request.method == 'GET' else request.data
    user_id = str(source.get('user_id') or '').strip()
    ceo = User.objects.filter(user_id=user_id, role='ceo', is_active=True).first()
    if not ceo:
        return Response({'success': False, 'message': 'Only an active CEO can access audit logs.'}, status=403)
    filters = source.get('filters') if isinstance(source.get('filters'), dict) else {}
    if request.method == 'GET':
        filters = {key: source.get(key) for key in ('search', 'user', 'date_from', 'date_to') if source.get(key)}
        filters['modules'] = source.getlist('module') if hasattr(source, 'getlist') else []
        filters['severities'] = source.getlist('severity') if hasattr(source, 'getlist') else []
    try: qs = _audit_queryset(filters)
    except ValueError as exc: return Response({'success': False, 'message': str(exc)}, status=400)
    total = qs.count()
    rows = [_audit_payload(item) for item in qs[:500]]
    if request.method == 'POST' and source.get('action') == 'export':
        export_format = str(source.get('format') or 'pdf').lower()
        include = source.get('include') if isinstance(source.get('include'), list) else []
        allowed_fields = {'id', 'event_id', 'created_at'}
        if 'Event Summary' in include: allowed_fields.update({'title', 'description', 'severity', 'module'})
        if 'Timeline' in include: allowed_fields.add('created_at')
        if 'User Details' in include: allowed_fields.update({'user_id', 'user_name', 'user_email', 'role'})
        if 'Change Details' in include: allowed_fields.update({'reference_id', 'is_read'})
        export_rows = [{key: value for key, value in row.items() if key in allowed_fields} for row in rows]
        for index, export_row in enumerate(export_rows):
            if 'IP & Location' in include: export_row['IP & Location'] = 'Not captured by this event'
            if 'Device Information' in include: export_row['Device Information'] = 'Not captured by this event'
            if 'Notes & Comments' in include: export_row['Notes & Comments'] = rows[index].get('description', '')
        if export_format == 'pdf': data, mime, ext = _simple_audit_pdf(export_rows), 'application/pdf', 'pdf'
        elif export_format == 'json': data, mime, ext = json.dumps(export_rows, indent=2).encode(), 'application/json', 'json'
        else:
            output = io.StringIO(); fields = list(export_rows[0].keys()) if export_rows else ['message']
            writer = csv.DictWriter(output, fieldnames=fields); writer.writeheader(); writer.writerows(export_rows)
            data = output.getvalue().encode('utf-8-sig')
            mime, ext = ('application/vnd.ms-excel', 'xls') if export_format in {'excel', 'xlsx'} else ('text/csv', 'csv')
        if not os.getenv('SENDGRID_API_KEY'):
            return Response({'success': False, 'message': 'Email delivery is not configured on the backend.'}, status=503)
        filename = f'audit_report_{timezone.localdate().isoformat()}.{ext}'
        message = Mail(from_email=os.getenv('EMAIL_FROM', 'noreply@bitbyte.com'), to_emails=ceo.email,
                       subject='BitByte HRMS Audit Report',
                       html_content=f'<p>Your requested audit report is attached.</p><p><b>Events:</b> {total}</p>')
        message.attachment = Attachment(FileContent(base64.b64encode(data).decode('ascii')), FileName(filename),
                                        FileType(mime), Disposition('attachment'))
        try: SendGridAPIClient(os.getenv('SENDGRID_API_KEY')).send(message)
        except Exception: return Response({'success': False, 'message': 'The email provider could not deliver the report.'}, status=502)
        return Response({'success': True, 'message': f'Audit report sent to {ceo.email}.', 'email': ceo.email})
    module_counts = list(qs.values('module').annotate(count=Count('id')).order_by('-count'))
    return Response({'success': True, 'summary': {'total_events': total,
        'users': qs.exclude(recipient_user_id='').values('recipient_user_id').distinct().count(),
        'modules': len(module_counts), 'critical_events': qs.filter(notification_type='error').count()},
        'module_counts': module_counts, 'logs': rows,
        'users': list(User.objects.filter(is_active=True).values('user_id', 'first_name', 'last_name', 'role')),
        'modules': list(AppNotification.objects.exclude(module='').values_list('module', flat=True).distinct()),
        'email': ceo.email, 'applied_filters': filters})


@api_view(['POST'])
def ceo_approval_decision_view(request, pk):
    decision = request.data.get('status')
    if decision not in ['approved', 'rejected']:
        return Response({'success': False, 'message': 'Status must be approved or rejected.'}, status=400)
    try:
        leave = EmployeeLeaveRequest.objects.get(pk=pk)
    except EmployeeLeaveRequest.DoesNotExist:
        return Response({'success': False, 'message': 'Leave request not found.'}, status=404)

    reviewer = str(request.data.get('reviewed_by') or request.data.get('user_id') or '').strip()
    if not User.objects.filter(user_id=reviewer, role='ceo', is_active=True).exists():
        return Response(
            {'success': False, 'message': 'Only an active CEO can decide this leave request.'},
            status=403,
        )
    now = timezone.now()
    leave.status = decision
    leave.hr_status = decision
    leave.hr_approved_by = reviewer
    leave.hr_reviewed_at = now
    leave.approved_by = reviewer
    leave.reviewed_at = now
    _notify_leave_employee(
        leave,
        'Leave Request Approved' if decision == 'approved' else 'Leave Request Rejected',
        f'Your {leave.leave_type} request was {decision} by CEO.',
        'success' if decision == 'approved' else 'error',
    )
    leave.save()
    return Response({'success': True, 'status': decision, 'message': f'Leave {decision} by CEO.', 'leave': _leave_dashboard_item(leave)})


@api_view(['GET'])
def ceo_notifications_view(request):
    user_id = (request.query_params.get('user_id') or '').strip()
    notification_query = Q(recipient_role='ceo')
    if user_id:
        notification_query |= Q(recipient_user_id=user_id)
    notifications = [
        _notification_payload(item)
        for item in AppNotification.objects.filter(notification_query)[:30]
    ]
    approval_notifications = [
        {
            'id': f'approval-{item["key"]}',
            'title': f'{item["title"]} Pending',
            'message': f'{item["count"]} {item["title"].lower()} request(s) need review.',
            'subtitle': f'{item["count"]} request(s) need review',
            'time': 'Pending',
            'trailing': 'Pending',
            'type': 'warning',
            'module': 'approval',
            'reference_id': item['key'],
            'category_title': item['title'],
            'is_read': False,
        }
        for item in _ceo_approvals_summary()
        if item['count'] > 0
    ]
    return Response({
        'success': True,
        'notifications': approval_notifications + notifications,
    })


@api_view(['POST'])
def ceo_notification_read_view(request, pk):
    user_id = (request.data.get('user_id') or '').strip()
    notification_query = Q(pk=pk, recipient_role='ceo')
    if user_id:
        notification_query |= Q(pk=pk, recipient_user_id=user_id)
    notification = AppNotification.objects.filter(notification_query).first()
    if notification is None:
        return Response(
            {'success': False, 'message': 'Notification not found.'},
            status=404,
        )
    if not notification.is_read:
        notification.is_read = True
        notification.save(update_fields=['is_read'])
    return Response({'success': True, 'notification_id': notification.id})


def _ceo_meeting_participant_options(user_id=''):
    def add_option(options, seen, item):
        if not isinstance(item, dict):
            return
        participant_id = str(
            item.get('id') or item.get('employee_id') or item.get('trailing') or ''
        ).strip()
        if not participant_id or participant_id in seen or participant_id == user_id:
            return
        seen.add(participant_id)
        role = item.get('role') or item.get('designation') or ''
        options.append({
            'id': participant_id,
            'employee_id': participant_id,
            'name': item.get('name') or item.get('title') or participant_id,
            'email': item.get('email') or item.get('detail') or '',
            'role': role,
            'role_label': item.get('role_label') or item.get('designation_label') or role,
            'department': item.get('department_label') or item.get('department') or '',
            'status': item.get('status') or 'Active',
        })

    options = []
    seen = set()
    visible_users = _ceo_created_user_queryset(user_id).filter(
        role__in=_CEO_VISIBLE_MEMBER_ROLES,
        is_active=True,
    ).order_by('first_name', 'last_name', 'user_id')
    tl_ids = []
    for user in visible_users:
        add_option(options, seen, {
            'id': user.user_id,
            'name': f'{user.first_name} {user.last_name}'.strip() or user.email,
            'email': user.email,
            'role': user.role,
            'role_label': _role_label(user.role),
            'department': _department_label(user.department) if user.department else '',
            'status': 'Active',
        })
        if user.role == 'tl':
            tl_ids.append(user.user_id)
    employee_accounts = EmployeeAccount.objects.filter(is_active=True).select_related('registration')
    if tl_ids:
        employee_accounts = employee_accounts.filter(reporting_tl__in=tl_ids)
    for account in employee_accounts.order_by('registration__first_name', 'registration__last_name', 'employee_id')[:300]:
        registration = account.registration
        add_option(options, seen, {
            'id': account.employee_id,
            'name': f'{registration.first_name} {registration.last_name}'.strip() or account.employee_email,
            'email': account.employee_email,
            'role': account.get_designation_display(),
            'role_label': account.get_designation_display(),
            'department': account.get_department_display(),
            'status': 'Active',
        })
    options.sort(key=lambda item: (item.get('name') or '').lower())
    return options


def _normalize_meeting_participants(payload_participants, allowed):
    allowed_by_id = {str(item.get('id')): item for item in allowed}
    participants = []
    seen = set()
    for raw in payload_participants if isinstance(payload_participants, list) else []:
        participant_id = ''
        if isinstance(raw, dict):
            participant_id = str(
                raw.get('id') or raw.get('employee_id') or raw.get('trailing') or ''
            ).strip()
        else:
            participant_id = str(raw or '').strip()
        if not participant_id or participant_id in seen or participant_id not in allowed_by_id:
            continue
        seen.add(participant_id)
        participants.append(allowed_by_id[participant_id])
    return participants


@api_view(['GET', 'POST'])
def ceo_meetings_view(request):
    user_id = (
        request.data.get('user_id')
        if request.method == 'POST'
        else request.query_params.get('user_id')
    ) or ''
    user_id = str(user_id).strip()
    participant_options = _ceo_meeting_participant_options(user_id)
    if request.method == 'POST':
        ceo = User.objects.filter(user_id=user_id, role='ceo', is_active=True).first()
        if ceo is None:
            return Response(
                {'success': False, 'message': 'Only an active CEO can schedule CEO meetings.'},
                status=403,
            )
        participants = _normalize_meeting_participants(
            request.data.get('participants'),
            participant_options,
        )
        if not participants:
            return Response(
                {'success': False, 'message': 'Select at least one scheduled user.'},
                status=400,
            )
        payload = request.data.copy()
        payload['participants'] = participants
        payload['created_by'] = user_id
        meeting = _create_meeting_from_payload(payload, 'Meeting')
        _notify_meeting_participants(meeting)
        email_count = 0
        email_error = ''
        if request.data.get('invite_email', True):
            try:
                email_count = _send_meeting_invite(meeting)
            except Exception as error:
                email_error = str(error)
        return Response({
            'success': True,
            'message': 'Meeting scheduled.',
            'meeting': _md_meeting_payload(meeting),
            'notified_to': len(participants),
            'email_sent_to': email_count,
            'email_error': email_error,
        })
    queryset = MdMeeting.objects.all()
    if user_id:
        queryset = queryset.filter(created_by=user_id)
    return Response({
        'success': True,
        'meetings': [_md_meeting_payload(item) for item in queryset.order_by('-id')[:30]],
        'participants': participant_options,
        'available_participants': participant_options,
    })


@api_view(['GET'])
def ceo_budget_view(request):
    projects = Project.objects.all()
    total_budget = float(projects.aggregate(total=Sum('budget'))['total'] or 0)
    total_spent = float(projects.aggregate(total=Sum('spent'))['total'] or 0)
    remaining_budget = total_budget - total_spent
    spent_percent_value = round((total_spent / total_budget) * 100) if total_budget else 0
    remaining_percent_value = max(0, 100 - spent_percent_value) if total_budget else 0
    budget_bars = []
    today = timezone.localdate()
    for offset in range(5, -1, -1):
        month = (today.replace(day=1) - timedelta(days=offset * 31)).replace(day=1)
        month_projects = projects.filter(created_at__year=month.year, created_at__month=month.month)
        month_budget = float(month_projects.aggregate(total=Sum('budget'))['total'] or 0)
        month_spent = float(month_projects.aggregate(total=Sum('spent'))['total'] or 0)
        budget_bars.append(round((month_spent / month_budget) * 100) if month_budget else 0)
    return Response({
        'success': True,
        'total_budget': _format_inr(total_budget),
        'total_spent': _format_inr(total_spent),
        'remaining_budget': _format_inr(remaining_budget),
        'total_budget_amount': total_budget,
        'total_spent_amount': total_spent,
        'remaining_budget_amount': remaining_budget,
        'spent_percent': f'{spent_percent_value}%',
        'remaining_percent': f'{remaining_percent_value}%',
        'budget_bars': budget_bars,
    })


@api_view(['GET', 'POST'])
def ceo_department_performance_view(request):
    user_id = (
        request.query_params.get('user_id')
        if request.method == 'GET'
        else request.data.get('user_id')
    ) or ''
    if request.method == 'POST':
        ceo = User.objects.filter(user_id=user_id, role='ceo', is_active=True).first()
        if ceo is None:
            return Response(
                {'success': False, 'message': 'Only an active CEO can manage departments.'},
                status=403,
            )
        action = str(request.data.get('action') or '').strip().lower()
        if action == 'save_department':
            name = str(request.data.get('name') or '').strip()
            department_key = str(request.data.get('department_key') or '').strip()
            if not department_key:
                department_key = slugify(name).replace('-', '_')
            errors = {}
            if not name:
                errors['name'] = 'Department name is required.'
            if not department_key:
                errors['department_key'] = 'Department key is required.'
            established_date = None
            established_raw = str(request.data.get('established_date') or '').strip()
            if established_raw:
                try:
                    established_date = datetime.strptime(established_raw, '%Y-%m-%d').date()
                except ValueError:
                    errors['established_date'] = 'Use YYYY-MM-DD format.'
            if errors:
                return Response({'success': False, 'errors': errors}, status=400)

            # Department codes are owned by the server and are derived from the
            # name.  This prevents a client from saving a code that does not
            # represent its department. Technical Support Team -> TST.
            code_name = re.sub(r'\([^)]*\)', ' ', name)
            code_words = re.findall(r'[A-Za-z0-9]+', code_name)
            ignored_words = {'and', 'of', 'the', 'for'}
            meaningful_words = [
                word for word in code_words if word.lower() not in ignored_words
            ] or code_words
            if len(meaningful_words) > 1:
                base_code = ''.join(word[0] for word in meaningful_words).upper()
            elif meaningful_words:
                base_code = meaningful_words[0][:3].upper()
            else:
                base_code = 'DEPT'
            base_code = base_code[:12]
            code = base_code
            suffix = 2
            code_scope = OrganizationDepartment.objects.filter(
                owner_user_id=user_id,
            ).exclude(department_key=department_key)
            while code_scope.filter(code__iexact=code).exists():
                code = f'{base_code[:16]}{suffix}'
                suffix += 1
            department, _created = OrganizationDepartment.objects.update_or_create(
                owner_user_id=user_id,
                department_key=department_key,
                defaults={
                    'name': name,
                    'code': code,
                    'description': str(request.data.get('description') or '').strip(),
                    'head_user_id': str(request.data.get('head_user_id') or '').strip(),
                    'email': str(request.data.get('email') or '').strip(),
                    'phone': str(request.data.get('phone') or '').strip(),
                    'location': str(request.data.get('location') or '').strip(),
                    'established_date': established_date,
                    'is_active': str(request.data.get('status') or 'active').lower() == 'active',
                },
            )
            return Response({
                'success': True,
                'message': 'Department saved successfully.',
                'department_id': department.id,
                'department_key': department.department_key,
                'department_code': department.code,
            })

        if action == 'assign_employee':
            employee_id = str(request.data.get('employee_id') or '').strip()
            department_key = str(request.data.get('department_key') or '').strip()
            if not employee_id or not department_key:
                return Response(
                    {'success': False, 'message': 'Employee and department are required.'},
                    status=400,
                )
            account = EmployeeAccount.objects.filter(employee_id=employee_id).first()
            if account is None:
                return Response(
                    {'success': False, 'message': 'Employee ID was not found.'},
                    status=404,
                )
            account.department = department_key
            account.save(update_fields=['department'])
            User.objects.filter(email__iexact=account.employee_email).update(
                department=department_key,
            )
            return Response({
                'success': True,
                'message': 'Employee assigned to the department.',
            })

        return Response(
            {'success': False, 'message': 'Unsupported department action.'},
            status=400,
        )

    if not EmployeeAccount.objects.exists():
        return Response({
            'success': True,
            'departments': [],
            'summary': {
                'total_departments': 0,
                'total_employees': 0,
                'active_departments': 0,
                'inactive_departments': 0,
            },
            'recent_departments': [],
            'available_employees': [],
        })

    categories = [
        item for item in _ceo_employee_categories()
        if int(item.get('count') or 0) > 0
    ]
    category_keys = {item['department'] for item in categories}
    overrides = {
        item.department_key: item
        for item in OrganizationDepartment.objects.filter(owner_user_id=user_id)
    }
    for key, override in overrides.items():
        if key in category_keys:
            continue
        accounts = list(
            EmployeeAccount.objects.filter(department=key).select_related('registration')
        )
        if not accounts:
            continue
        categories.append({
            'department': key,
            'label': override.name,
            'count': len(accounts),
            'performance': 0,
            'performance_label': '0%',
            'strength': 0,
            'strength_label': '0%',
            'employees': [
                {
                    'id': account.employee_id,
                    'name': f'{account.registration.first_name} {account.registration.last_name}'.strip(),
                    'email': account.employee_email,
                    'phone': mask_phone_number(account.registration.mobile),
                    'designation': account.get_designation_display(),
                    'status': 'Active' if account.is_active else 'Inactive',
                    'attendance_status': 'Not Marked',
                    'work_location': account.work_location,
                }
                for account in accounts
            ],
        })
    total_employees = sum(item['count'] for item in categories)
    departments = [
        {
            'department': item['department'],
            'name': (
                overrides[item['department']].name
                if item['department'] in overrides else item['label']
            ),
            'code': (
                overrides[item['department']].code
                if item['department'] in overrides
                else ''.join(word[0] for word in item['label'].split() if word)[:6].upper()
            ),
            'count': item['count'],
            'score': f'{item["count"]} Employees',
            'performance': item['performance'],
            'trend': item['performance_label'],
            'strength': (
                round((item['count'] / total_employees) * 100)
                if total_employees else 0
            ),
            'strength_label': (
                f'{round((item["count"] / total_employees) * 100)}%'
                if total_employees else '0%'
            ),
            'employees': item['employees'],
            'description': (
                overrides[item['department']].description
                if item['department'] in overrides
                else f'The {item["label"]} department supports Bit Byte Technologies operations and delivery.'
            ),
            'head_user_id': (
                overrides[item['department']].head_user_id
                if item['department'] in overrides else ''
            ),
            'head_name': (
                _user_brief(overrides[item['department']].head_user_id)
                if item['department'] in overrides else ''
            ),
            'email': (
                overrides[item['department']].email
                if item['department'] in overrides else ''
            ),
            'phone': (
                mask_phone_number(overrides[item['department']].phone)
                if item['department'] in overrides else ''
            ),
            'phone_edit_value': (
                overrides[item['department']].phone
                if item['department'] in overrides else ''
            ),
            'location': (
                overrides[item['department']].location
                if item['department'] in overrides else ', '.join(sorted({
                    employee.get('work_location', '')
                    for employee in item['employees']
                    if employee.get('work_location')
                }))
            ),
            'locations': len({
                employee.get('work_location', '')
                for employee in item['employees']
                if employee.get('work_location')
            }),
            'teams': User.objects.filter(
                role='tl',
                department=item['department'],
                is_active=True,
            ).count(),
            'established_date': (
                overrides[item['department']].established_date.isoformat()
                if item['department'] in overrides and overrides[item['department']].established_date
                else ''
            ),
            'status': (
                'Active'
                if item['department'] not in overrides or overrides[item['department']].is_active
                else 'Inactive'
            ),
            'is_customized': item['department'] in overrides,
        }
        for item in categories
    ]
    departments = [item for item in departments if item['count'] > 0]
    departments.sort(key=lambda item: (-item['count'], item['name']))
    active_count = sum(1 for item in departments if item['status'] == 'Active')
    return Response({
        'success': True,
        'departments': departments,
        'summary': {
            'total_departments': len(departments),
            'total_employees': total_employees,
            'active_departments': active_count,
            'inactive_departments': len(departments) - active_count,
        },
        'recent_departments': [
            item for item in departments if item['is_customized']
        ][:5],
        'available_employees': [
            {
                'id': account.employee_id,
                'name': f'{account.registration.first_name} {account.registration.last_name}'.strip(),
                'department': account.department,
                'designation': account.get_designation_display(),
            }
            for account in EmployeeAccount.objects.select_related('registration').order_by(
                'registration__first_name', 'registration__last_name'
            )
        ],
    })


@api_view(['GET'])
def ceo_branch_performance_view(request):
    branches = []
    for row in (
        EmployeeAccount.objects.exclude(work_location='')
        .values('work_location')
        .annotate(count=Count('id'))
        .order_by('work_location')
    ):
        location = row['work_location']
        count = row['count']
        branches.append({'name': location, 'score': f'{count} Employees', 'trend': '+0%', 'revenue': 0})
    return Response({'success': True, 'branches': branches})


@api_view(['GET'])
def superadmin_dashboard_view(request):
    today = timezone.localdate()
    present_today = EmployeeAttendanceRecord.objects.filter(attendance_date=today, status__in=['Present', 'Half Day']).count()
    total_employees = _employee_count()
    attendance = f'{round((present_today / total_employees) * 100)}%' if total_employees else '0%'
    absent_today = max(total_employees - present_today, 0)
    late_today = EmployeeAttendanceRecord.objects.filter(attendance_date=today, status='Late Entry').count()
    departments = [
        {
            'id': item.id,
            'name': item.name,
            'code': item.code,
            'head_user_id': item.head_user_id,
            'location': item.location,
            'is_active': item.is_active,
            'employees': EmployeeAccount.objects.filter(department=item.department_key).count(),
        }
        for item in OrganizationDepartment.objects.order_by('name')[:50]
    ]
    if not departments:
        department_map = dict(EmployeeAccount.DEPARTMENT_CHOICES)
        departments = [
            {
                'id': row['department'],
                'name': department_map.get(row['department'], row['department'] or 'Unassigned'),
                'code': row['department'],
                'head_user_id': '',
                'location': '',
                'is_active': True,
                'employees': row['count'],
            }
            for row in EmployeeAccount.objects.exclude(department='').values('department').annotate(count=Count('id')).order_by('department')
        ]
    if not departments:
        departments = [
            {'id': 'hr', 'name': 'HR', 'code': 'HR', 'head_user_id': '', 'location': 'Salem HQ', 'is_active': True, 'employees': 5},
            {'id': 'web_application_development', 'name': 'Web Application Development', 'code': 'WEB', 'head_user_id': '', 'location': 'Salem HQ', 'is_active': True, 'employees': 8},
            {'id': 'mobile_application_development', 'name': 'Mobile Application Development', 'code': 'MOB', 'head_user_id': '', 'location': 'Salem HQ', 'is_active': True, 'employees': 7},
            {'id': 'digital_marketing', 'name': 'Digital Marketing', 'code': 'DM', 'head_user_id': '', 'location': 'Chennai Branch', 'is_active': True, 'employees': 4},
            {'id': 'technical_support', 'name': 'Technical Support', 'code': 'SUP', 'head_user_id': '', 'location': 'Bangalore Branch', 'is_active': True, 'employees': 6},
            {'id': 'management', 'name': 'Management', 'code': 'MGT', 'head_user_id': '', 'location': 'Salem HQ', 'is_active': True, 'employees': 3},
        ]
    roles = [
        {
            'id': item.id,
            'name': item.name,
            'department': item.department,
            'business_unit': item.business_unit,
            'filled_positions': item.filled_positions,
            'vacant_positions': item.vacant_positions,
            'is_active': item.is_active,
        }
        for item in OrganizationRole.objects.order_by('name')[:50]
    ]
    meetings = [
        {
            'id': item.id,
            'title': item.title,
            'date': item.date_label,
            'time': item.time_label,
            'location': item.location,
            'status': item.status,
            'participants': item.participants,
        }
        for item in MdMeeting.objects.order_by('-created_at')[:30]
    ]
    tasks = [
        {
            'id': item.id,
            'title': item.title,
            'project': item.project,
            'assignee': item.assignee_name or item.assignee_id,
            'priority': item.priority,
            'due_date': item.due_date,
            'status': item.status,
        }
        for item in TeamTask.objects.order_by('-created_at')[:50]
    ]
    leaves = [
        {
            'id': item.id,
            'employee_id': item.employee_id,
            'name': _employee_name(item.employee_id),
            'leave_type': item.leave_type,
            'from_date': item.from_date.isoformat() if item.from_date else '',
            'to_date': item.to_date.isoformat() if item.to_date else '',
            'days': item.total_days,
            'status': item.status,
        }
        for item in EmployeeLeaveRequest.objects.order_by('-created_at')[:50]
    ]
    payslips = Payslip.objects.all()
    payroll = {
        'processed': str(sum((item.net_salary for item in payslips), Decimal('0'))),
        'pending': PayrollProcess.objects.exclude(status='published').count(),
        'employees_paid': payslips.filter(status='paid').values('employee_id').distinct().count(),
        'average_salary': str(
            round(sum((item.net_salary for item in payslips), Decimal('0')) / payslips.count(), 2)
            if payslips.count() else Decimal('0')
        ),
        'processes': [
            {'year': item.year, 'month': item.month, 'status': item.status}
            for item in PayrollProcess.objects.order_by('-year', '-month')[:12]
        ],
    }
    reports = [
        {
            'id': item.id,
            'report_type': item.report_type,
            'format': item.file_format,
            'status': item.status,
            'created_at': item.created_at.isoformat() if item.created_at else '',
        }
        for item in ReportExportHistory.objects.order_by('-created_at')[:30]
    ]
    budget_total = sum((item.allocated_amount for item in BudgetPlan.objects.all()), Decimal('0'))
    budget_spent = sum((item.spent_amount for item in BudgetPlan.objects.all()), Decimal('0'))
    return Response({
        'success': True,
        'total_employees': total_employees,
        'total_departments': _department_count(),
        'active_users': User.objects.filter(is_active=True).count(),
        'attendance': attendance,
        'pending_leaves': EmployeeLeaveRequest.objects.filter(status='pending').count(),
        'open_tasks': TeamTask.objects.exclude(status='completed').count(),
        'present': present_today,
        'absent': absent_today,
        'late': late_today,
        'present_today': present_today,
        'absent_today': absent_today,
        'users': _superadmin_users(),
        'employees': _admin_employee_items(),
        'notifications': _notifications_for_role('superadmin'),
        'roles': roles,
        'departments': departments,
        'attendance_detail': {
            'total': total_employees or 40,
            'present': present_today or 32,
            'absent': absent_today if total_employees else 6,
            'late': late_today or 2,
            'percentage': attendance if total_employees else '80%',
            'records': EmployeeAttendanceRecord.objects.filter(attendance_date=today).count() or 40,
        },
        'tasks': tasks,
        'leaves': leaves,
        'meetings': meetings,
        'payroll': payroll,
        'reports': reports,
        'budgets': {
            'total': str(budget_total),
            'spent': str(budget_spent),
            'remaining': str(budget_total - budget_spent),
        },
        'branch_performance': [
            {'name': item.branch_name, 'period': item.period, 'employees': item.total_employees, 'revenue': str(item.revenue), 'score': str(item.productivity_rate)}
            for item in BranchPerformanceSnapshot.objects.order_by('branch_name')[:30]
        ],
        'department_performance': [
            {'name': item.department, 'period': item.period, 'employees': item.total_employees, 'score': str(item.performance_score)}
            for item in DepartmentPerformanceSnapshot.objects.order_by('department')[:30]
        ],
        'approvals': [
            {'id': item.id, 'title': item.title, 'module': item.module, 'status': item.status, 'priority': item.priority, 'amount': str(item.amount)}
            for item in WorkflowApprovalRequest.objects.order_by('-created_at')[:30]
        ],
    })


@api_view(['GET'])
def superadmin_notifications_view(request):
    notifications = _notifications_for_role('superadmin')
    return Response({'success': True, 'notifications': notifications})


def _admin_employee_payload_from_account(account):
    registration = account.registration
    name = f'{registration.first_name} {registration.last_name}'.strip()
    return {
        'id': account.employee_id,
        'employee_id': account.employee_id,
        'name': name or account.employee_email,
        'role': account.get_designation_display(),
        'designation': account.get_designation_display(),
        'email': account.employee_email,
        'department': account.get_department_display(),
        'status': 'Active' if account.is_active else 'Inactive',
        'phone': mask_phone_number(getattr(registration, 'mobile', '') or ''),
        'date_of_joining': account.date_of_joining.isoformat() if account.date_of_joining else '',
        'reporting_manager': account.reporting_tl,
    }


def _admin_employee_payload_from_user(user):
    name = f'{user.first_name} {user.last_name}'.strip() or user.email
    return {
        'id': user.user_id,
        'employee_id': user.user_id,
        'name': name,
        'role': _role_label(user.role),
        'designation': _role_label(user.occupation) if user.occupation else _role_label(user.role),
        'email': user.email,
        'department': _department_label(user.department) if user.department else '',
        'status': 'Active' if user.is_active else 'Inactive',
        'phone': mask_phone_number(f'{user.country_code} {user.phone}' if user.phone else ''),
        'date_of_joining': '',
        'reporting_manager': '',
    }


def _admin_employee_items():
    items = [
        _admin_employee_payload_from_account(account)
        for account in EmployeeAccount.objects.select_related('registration').order_by('employee_id')
    ]
    account_emails = {
        str(item.get('email') or '').lower()
        for item in items
        if item.get('email')
    }
    for user in User.objects.exclude(role='superadmin').order_by('first_name', 'last_name', 'user_id'):
        if user.email.lower() in account_emails:
            continue
        items.append(_admin_employee_payload_from_user(user))
    return items


def _admin_attendance_record_payload(record):
    group = _attendance_status_group(record.status)
    status = {
        'present': 'Present',
        'late': 'Late',
        'absent': 'Absent',
        'leave': 'Leave',
    }.get(group, str(record.status or 'Present').title())
    return {
        'id': record.id,
        'employee_id': record.employee_id,
        'name': _employee_name(record.employee_id),
        'status': status,
        'checkin': record.check_in.strftime('%I:%M %p') if record.check_in else '--',
        'checkout': record.check_out.strftime('%I:%M %p') if record.check_out else '--',
        'working_hours': record.working_hours,
        'date': record.attendance_date.isoformat(),
    }


def _admin_leave_payload(leave):
    item = _leave_dashboard_item(leave)
    return {
        'id': str(leave.id),
        'name': item['name'],
        'employee_id': item['employee_id'],
        'role': item.get('designation') or item.get('department') or 'Employee',
        'department': item.get('department', ''),
        'type': item['leave_type'],
        'from': leave.from_date.isoformat(),
        'to': leave.to_date.isoformat(),
        'days': str(leave.total_days),
        'reason': leave.reason,
        'status': leave.status.title(),
        'tl_status': leave.tl_status.title(),
        'hr_status': leave.hr_status.title(),
    }


@api_view(['GET'])
def admin_dashboard_view(request):
    today = timezone.localdate()
    total_employees = len(_admin_employee_items())
    today_records = EmployeeAttendanceRecord.objects.filter(attendance_date=today)
    present_today = sum(1 for record in today_records if _attendance_status_group(record.status) == 'present')
    late_today = sum(1 for record in today_records if _attendance_status_group(record.status) == 'late')
    on_leave = EmployeeLeaveRequest.objects.filter(
        status='approved',
        from_date__lte=today,
        to_date__gte=today,
    ).count()
    absent_today = max(total_employees - present_today - late_today - on_leave, 0)

    bars = []
    for offset in range(5, -1, -1):
        day = today - timedelta(days=offset)
        day_records = EmployeeAttendanceRecord.objects.filter(attendance_date=day)
        day_present = sum(1 for record in day_records if _attendance_status_group(record.status) in {'present', 'late'})
        bars.append(round((day_present / total_employees) * 100, 1) if total_employees else 0)

    activity = []
    for leave in EmployeeLeaveRequest.objects.order_by('-created_at')[:5]:
        activity.append({
            'type': 'leave_approved' if leave.status == 'approved' else 'info',
            'title': f'{leave.status.title()} leave request',
            'subtitle': f'{_employee_name(leave.employee_id)} - {leave.leave_type}',
        })
    for notification in AppNotification.objects.filter(Q(recipient_role='admin') | Q(recipient_role='')).order_by('-created_at')[:5]:
        activity.append({
            'type': notification.notification_type,
            'title': notification.title,
            'subtitle': notification.message,
        })

    return Response({
        'success': True,
        'total_employees': total_employees,
        'present_today': present_today,
        'late_today': late_today,
        'absent_today': absent_today,
        'on_leave': on_leave,
        'meetings_today': MdMeeting.objects.filter(date_label__icontains=str(today.day)).count(),
        'pending_leaves': EmployeeLeaveRequest.objects.filter(status='pending').count(),
        'new_joinings': EmployeeAccount.objects.filter(
            created_at__date__gte=today.replace(day=1),
        ).count(),
        'attendance_bars': bars,
        'attendance_trend': '',
        'recent_activity': activity[:8],
    })


@api_view(['GET'])
def admin_employees_view(request):
    return Response({'success': True, 'employees': _admin_employee_items()})


@api_view(['GET'])
def admin_employee_detail_view(request, employee_id):
    account = EmployeeAccount.objects.filter(employee_id=employee_id).select_related('registration').first()
    if account:
        return Response({'success': True, 'employee': _admin_employee_payload_from_account(account)})
    user = User.objects.filter(user_id=employee_id).first()
    if user:
        return Response({'success': True, 'employee': _admin_employee_payload_from_user(user)})
    return Response({'success': False, 'message': 'Employee not found.'}, status=404)


@api_view(['GET'])
def admin_attendance_view(request):
    requested_date = request.query_params.get('date') or ''
    try:
        selected_date = datetime.strptime(requested_date, '%Y-%m-%d').date() if requested_date else timezone.localdate()
    except ValueError:
        selected_date = timezone.localdate()
    records = list(EmployeeAttendanceRecord.objects.filter(attendance_date=selected_date))
    groups = [_attendance_status_group(record.status) for record in records]
    on_leave = EmployeeLeaveRequest.objects.filter(
        status='approved',
        from_date__lte=selected_date,
        to_date__gte=selected_date,
    ).count()
    return Response({
        'success': True,
        'date': selected_date.isoformat(),
        'present': groups.count('present'),
        'late': groups.count('late'),
        'absent': groups.count('absent'),
        'on_leave': on_leave,
        'records': [_admin_attendance_record_payload(record) for record in records],
    })


@api_view(['GET'])
def admin_leaves_view(request):
    leaves = EmployeeLeaveRequest.objects.all().order_by('-created_at')[:100]
    return Response({'success': True, 'leaves': [_admin_leave_payload(leave) for leave in leaves]})


@api_view(['GET'])
def admin_reports_view(request):
    today = timezone.localdate()
    return Response({
        'success': True,
        'reports': [
            {'title': 'Employees', 'value': _employee_count(), 'subtitle': 'Total employee accounts'},
            {'title': 'Attendance Today', 'value': EmployeeAttendanceRecord.objects.filter(attendance_date=today).count(), 'subtitle': today.isoformat()},
            {'title': 'Leave Requests', 'value': EmployeeLeaveRequest.objects.count(), 'subtitle': 'All statuses'},
        ],
    })


@api_view(['GET'])
def admin_meetings_view(request):
    today = timezone.localdate()
    meetings = []
    for meeting in MdMeeting.objects.all()[:50]:
        payload = _md_meeting_payload(meeting)
        meetings.append({
            'id': str(payload['id']),
            'title': payload['title'],
            'time': payload.get('time_label') or payload.get('duration') or '',
            'location': payload.get('location') or payload.get('meeting_link') or '',
            'participants': str(len(payload.get('participants') or [])),
            'status': payload.get('status', ''),
        })
    return Response({
        'success': True,
        'date': today.isoformat(),
        'meetings': meetings,
    })


@api_view(['GET', 'POST'])
def admin_tasks_view(request):
    if request.method == 'POST':
        title = str(request.data.get('title') or '').strip()
        if not title:
            return Response({'success': False, 'message': 'Task title is required.'}, status=400)
        task = TeamTask.objects.create(
            title=title,
            description=str(request.data.get('description') or '').strip(),
            assignee_id=str(request.data.get('assignee_id') or '').strip(),
            assignee_name=str(request.data.get('assignee_name') or request.data.get('assignee') or '').strip(),
            assignee_email=str(request.data.get('assignee_email') or '').strip(),
            priority=str(request.data.get('priority') or 'Medium').strip(),
            due_date=str(request.data.get('due_date') or '').strip(),
            project=str(request.data.get('project') or '').strip(),
            created_by=str(request.data.get('created_by') or request.data.get('user_id') or 'admin').strip(),
        )
        return Response({
            'success': True,
            'message': 'Task created successfully.',
            'task': {
                'id': task.id,
                'title': task.title,
                'project': task.project,
                'assignee': task.assignee_name or task.assignee_id,
                'priority': task.priority,
                'status': task.status,
                'due_date': task.due_date,
                'description': task.description,
            },
        })
    tasks = TeamTask.objects.all()[:100]
    return Response({
        'success': True,
        'tasks': [
            {
                'id': task.id,
                'title': task.title,
                'project': task.project,
                'assignee': task.assignee_name or task.assignee_id,
                'priority': task.priority,
                'status': task.status,
                'due_date': task.due_date,
                'description': task.description,
            }
            for task in tasks
        ],
    })


@api_view(['GET'])
def admin_assets_view(request):
    return Response({'success': True, 'assets': []})


@api_view(['GET'])
def admin_notifications_view(request):
    user_id = request.query_params.get('user_id') or ''
    notifications = (_notifications_for_user(user_id) if user_id else []) + _notifications_for_role('admin')
    return Response({'success': True, 'notifications': notifications})


@api_view(['GET'])
def admin_profile_view(request):
    user_id = request.query_params.get('user_id') or ''
    user = User.objects.filter(user_id=user_id).first() if user_id else None
    if not user:
        user = User.objects.filter(role='admin', is_active=True).first()
    if not user:
        return Response({'success': True, 'profile': {}})
    return Response({'success': True, 'profile': _admin_employee_payload_from_user(user)})


@api_view(['POST'])
def admin_leave_approve_view(request, pk):
    status = str(request.data.get('status') or '').strip().lower()
    if status in {'approved', 'approve'}:
        status = 'approved'
    elif status in {'rejected', 'reject'}:
        status = 'rejected'
    else:
        return Response({'success': False, 'message': 'Status must be Approved or Rejected.'}, status=400)
    try:
        leave = EmployeeLeaveRequest.objects.get(pk=pk)
    except EmployeeLeaveRequest.DoesNotExist:
        return Response({'success': False, 'message': 'Leave request not found.'}, status=404)
    now = timezone.now()
    reviewer = request.data.get('user_id') or request.data.get('reviewed_by') or 'Admin'
    leave.tl_status = 'approved' if leave.tl_status == 'pending' and status == 'approved' else leave.tl_status
    leave.hr_status = status
    leave.status = status
    leave.approved_by = reviewer
    leave.hr_approved_by = reviewer
    leave.reviewed_at = now
    leave.hr_reviewed_at = now
    leave.save()
    _notify_leave_employee(
        leave,
        'Leave Request Approved' if status == 'approved' else 'Leave Request Rejected',
        f'Your {leave.leave_type} request was {status} by Admin.',
        'success' if status == 'approved' else 'error',
    )
    return Response({'success': True, 'message': f'Leave {status}.', 'leave': _admin_leave_payload(leave)})


@api_view(['POST'])
def admin_create_employee_view(request):
    full_name = str(request.data.get('name') or '').strip()
    email = str(request.data.get('email') or '').strip().lower()
    phone = ''.join(ch for ch in str(request.data.get('phone') or '') if ch.isdigit())[-10:]
    role_label = str(request.data.get('role') or 'Employee').strip().lower()
    role = {
        'team lead': 'tl',
        'manager': 'manager',
        'hr': 'hr',
        'finance': 'finance',
        'admin': 'admin',
        'employee': 'employee',
    }.get(role_label, 'employee')
    if not full_name or not email:
        return Response({'success': False, 'message': 'Name and email are required.'}, status=400)
    if User.objects.filter(email=email).exists():
        return Response({'success': False, 'message': 'Email already exists.'}, status=400)
    parts = full_name.split()
    first_name = parts[0]
    last_name = ' '.join(parts[1:])
    password = ''.join(random.choices(string.ascii_letters + string.digits, k=10))
    user = User(
        email=email,
        role=role,
        first_name=first_name,
        last_name=last_name,
        country_code='+91',
        phone=phone,
        department=str(request.data.get('department') or role).strip(),
        occupation=str(request.data.get('designation') or role).strip(),
        created_by=str(request.data.get('created_by') or '').strip(),
    )
    user.set_password(password)
    user.save()
    _create_notification(
        role='admin',
        title='Employee Created',
        message=f'{full_name} ({user.user_id}) was created from Admin mobile.',
        notification_type='success',
        module='employee',
        reference_id=user.user_id,
    )
    return Response({
        'success': True,
        'message': 'Employee created successfully.',
        'employee': _admin_employee_payload_from_user(user),
        'temporary_password': password,
    })


@api_view(['GET'])
def notifications_view(request):
    user_id = request.query_params.get('user_id') or ''
    role = request.query_params.get('role') or ''
    notifications = _notifications_for_user(user_id) if user_id else _notifications_for_role(role)
    return Response({'success': True, 'notifications': notifications})


@api_view(['POST'])
def notification_read_view(request, pk):
    user_id = (request.data.get('user_id') or '').strip()
    role = (request.data.get('role') or '').strip()
    query = Q(pk=pk)
    target = Q()
    if user_id:
        target |= Q(recipient_user_id=user_id)
    if role:
        target |= Q(recipient_role=role)
    if target:
        query &= target
    notification = AppNotification.objects.filter(query).first()
    if notification is None:
        return Response({'success': False, 'message': 'Notification not found.'}, status=404)
    if not notification.is_read:
        notification.is_read = True
        notification.save(update_fields=['is_read'])
    return Response({'success': True, 'notification_id': notification.id})


@api_view(['POST'])
def register_device_token_view(request):
    user_id = request.data.get('user_id') or ''
    token = request.data.get('token') or ''
    if not user_id or not token:
        return Response({'success': False, 'message': 'user_id and token are required.'}, status=400)
    device, _ = MobileDeviceToken.objects.update_or_create(
        token=token,
        defaults={
            'user_id': user_id,
            'role': request.data.get('role') or '',
            'platform': request.data.get('platform') or '',
            'is_active': True,
        },
    )
    return Response({'success': True, 'device_id': device.id})


@api_view(['GET', 'POST'])
def tl_leave_decision_view(request, pk):
    if request.method == 'GET':
        try:
            leave = EmployeeLeaveRequest.objects.get(pk=pk)
        except EmployeeLeaveRequest.DoesNotExist:
            return Response({'success': False, 'message': 'Leave request not found.'}, status=404)
        return Response({'success': True, 'leave': _leave_dashboard_item(leave)})
    return _leave_decision(request, pk, 'tl')


@api_view(['POST'])
def hr_leave_decision_view(request, pk):
    return _leave_decision(request, pk, 'hr')

@api_view(['POST'])
def create_user_view(request):
    serializer = CreateUserSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        existing_email_users = User.objects.filter(email__iexact=data['email'])
        if existing_email_users.exists() and (
            data['role'] != 'admin'
            or existing_email_users.exclude(role='admin').exists()
        ):
            return Response({
                'success': False,
                'message': 'Email already exists. Shared email is allowed only between Admin accounts.',
            }, status=400)
        user = User(
            email=data['email'],
            role=data['role'],
            first_name=data['first_name'],
            last_name=data['last_name'],
            country_code=data['country_code'],
            phone=data['phone'],
            gender=data['gender'],
            dob=data['dob'],
            door_no=data['door_no'],
            street=data['street'],
            pincode=data['pincode'],
            city=data['city'],
            state=data['state'],
            department=data.get('department', ''),
            work_mode=data.get('work_mode', 'onsite'),
            occupation=data.get('designation') or data.get('occupation') or data['role'],
            created_by=data.get('created_by', ''),
            pan=data['pan'],
            aadhar=data['aadhar'],
        )
        user.set_password(data['password'])
        user.save()
        creator_id = data.get('created_by', '').strip()
        if creator_id:
            member_name = f'{user.first_name} {user.last_name}'.strip() or user.email
            _create_notification(
                user_id=creator_id,
                title='Team Member Created',
                message=(
                    f'{member_name} ({user.user_id}) was created successfully '
                    f'as {user.get_role_display()}.'
                ),
                notification_type='success',
                module='member_creation',
                reference_id=user.user_id,
            )
        return Response({
            'success': True,
            'user_id': user.user_id,
            'employee_id': user.user_id,
            'designation': user.occupation,
            'department': user.department,
            'work_mode': user.work_mode,
            'created_by': user.created_by,
            'message': f'{data["role"].upper()} created!',
        })
    first_error = next(iter(serializer.errors.items()), None)
    message = 'User validation failed'
    if first_error:
        field, errors = first_error
        message = f'{field}: {errors[0] if errors else "Invalid value"}'
    return Response({'success': False, 'message': message, 'errors': serializer.errors}, status=400)

@api_view(['POST'])
def register_employee_view(request):
    doc_fields = [
        'doc_passport_photo', 'doc_aadhar', 'doc_pan', 'doc_bank_passbook',
        'doc_10th', 'doc_12th', 'doc_degree', 'doc_consolidated', 'doc_college_noc',
        'doc_resume', 'doc_experience_cert', 'doc_relieving', 'doc_salary_slips',
        'doc_passport_copy', 'doc_driving', 'doc_vaccination',
    ]
    registration_data = {
    key: value
    for key, value in request.data.items()
    if key not in doc_fields
}

    serializer = EmployeeRegistrationSerializer(data=registration_data)
    if serializer.is_valid():
        emp = serializer.save()
        updated = False
        for field in doc_fields:
            if field in request.FILES:
                setattr(emp, field, request.FILES[field])
                updated = True
        if updated:
            emp.save()
        return Response({'success': True, 'message': 'Registration submitted!', 'id': emp.id})
    print('Employee registration validation errors:', serializer.errors)
    first_error = next(iter(serializer.errors.items()), None)
    message = 'Registration validation failed'
    if first_error:
        field, errors = first_error
        message = f'{field}: {errors[0] if errors else "Invalid value"}'
    return Response({'success': False, 'message': message, 'errors': serializer.errors}, status=400)

@api_view(['GET'])
def get_registered_employees_view(request):
    employees = EmployeeRegistration.objects.all().order_by('-submitted_at')
    serializer = EmployeeRegistrationSerializer(employees, many=True)
    return Response({'success': True, 'employees': serializer.data})


@api_view(['GET'])
def reporting_tls_view(request):
    department = (request.query_params.get('department') or '').strip()

    # Reporting TL must always be an actual Team Lead, never an employee or
    # another senior role.
    base_qs = EmployeeAccount.objects.select_related('registration').filter(
        is_active=True,
        designation='tl',
    )
    if department:
        base_qs = base_qs.filter(department=department)

    queryset = base_qs
    # If the selected department has no TL, offer TLs from other departments;
    # never fall back to ordinary employees.
    if department and not queryset.exists():
        queryset = EmployeeAccount.objects.select_related('registration').filter(
            is_active=True,
            designation='tl',
        )

    # Build a lookup of email -> user_id from User table for role-based IDs
    emails = list(queryset.values_list('employee_email', flat=True))
    user_id_map = {
        u.email.lower(): u.user_id
        for u in User.objects.filter(email__in=emails)
        if u.user_id
    }

    tls = []
    seen_emails = set()

    for account in queryset.order_by('registration__first_name', 'registration__last_name'):
        registration = account.registration
        name = f'{registration.first_name} {registration.last_name}'.strip()
        display_name = name or account.employee_email
        # Prefer role-based ID (BBTL..., BBHR...) over BBEMP ID
        tl_id = user_id_map.get(account.employee_email.lower(), '') or account.employee_id
        tls.append({
            'value': display_name,
            'label': display_name,
            'employee_id': tl_id,
            'email': account.employee_email,
            'department': account.department,
            'department_label': account.get_department_display(),
            'role': 'tl',
        })
        seen_emails.add(account.employee_email.lower())

    # Also include TL-role users who may not have an EmployeeAccount yet
    user_queryset = User.objects.filter(role='tl', is_active=True)
    if department:
        user_queryset = user_queryset.filter(Q(department=department) | Q(department=''))
        if not user_queryset.exists():
            user_queryset = User.objects.filter(role='tl', is_active=True)
    for user in user_queryset.order_by('first_name', 'last_name'):
        if user.email.lower() in seen_emails:
            continue
        name = f'{user.first_name} {user.last_name}'.strip()
        display_name = name or user.email
        department_value = user.department or ''
        tls.append({
            'value': display_name,
            'label': display_name,
            'employee_id': user.user_id or '',
            'email': user.email,
            'department': department_value,
            'department_label': department_value.replace('_', ' ').title() if department_value else '',
            'role': 'tl',
        })

    return Response({'success': True, 'tls': tls})


@api_view(['PATCH'])
def update_employee_status_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        emp.status = request.data.get('status', emp.status)
        emp.save()
        return Response({'success': True, 'message': 'Status updated!'})
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)


@api_view(['POST'])
def employee_document_action_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)

    document_key = request.data.get('document_key') or request.data.get('document')
    action = (request.data.get('action') or '').strip().lower()
    if document_key not in DOCUMENT_FIELD_LABELS:
        return Response({'success': False, 'message': 'Invalid document.'}, status=400)
    if action not in ['verify', 'flag', 'reject']:
        return Response({'success': False, 'message': 'Invalid document action.'}, status=400)

    status_value = {
        'verify': 'verified',
        'flag': 'flagged',
        'reject': 'rejected',
    }[action]
    details = {
        'status': status_value,
        'issue_type': request.data.get('issue_type', ''),
        'remark': request.data.get('remark', ''),
        'suggested_action': request.data.get('suggested_action', ''),
        'priority': request.data.get('priority', ''),
        'reviewed_at': timezone.now().isoformat(),
    }
    statuses = dict(emp.document_statuses or {})
    statuses[document_key] = details
    emp.document_statuses = statuses
    history = list(emp.document_review_history or [])
    history.insert(0, _document_history_entry(document_key, status_value, 'HR', details))
    emp.document_review_history = history[:50]
    if action == 'flag':
        emp.status = 'flagged'
    emp.save()

    title = DOCUMENT_FIELD_LABELS[document_key]
    recipient = _employee_recipient_id(emp)
    email_sent = None
    if action == 'flag':
        _create_notification(
            user_id=recipient,
            title='Document Correction Required',
            message=f'{title} was flagged by HR. {details["remark"] or "Please re-upload the correct document."}',
            notification_type='warning',
            module='documents',
            reference_id=f'{emp.id}:{document_key}',
        )
        email_sent = send_hr_correction_email(
            emp.personal_email,
            f'Action Required: {title} Flagged by HR',
            _document_flag_email_html(emp, title, details),
        ) if emp.personal_email else False
    elif action == 'reject':
        _create_notification(
            user_id=recipient,
            title='Document Rejected',
            message=f'{title} was rejected by HR. Please contact HR or upload a corrected document.',
            notification_type='error',
            module='documents',
            reference_id=f'{emp.id}:{document_key}',
        )
    else:
        _create_notification(
            user_id=recipient,
            title='Document Verified',
            message=f'{title} has been verified by HR.',
            notification_type='success',
            module='documents',
            reference_id=f'{emp.id}:{document_key}',
        )

    serializer = EmployeeRegistrationSerializer(emp)
    response_message = f'{title} {status_value}.'
    if action == 'flag':
        response_message += (
            ' Correction email sent to the employee.'
            if email_sent
            else ' Document was flagged, but the correction email could not be sent.'
        )
    return Response({
        'success': True,
        'message': response_message,
        'email_sent': email_sent,
        'employee': serializer.data,
    })



def send_email(to_email, subject, html_content):
    try:
        send_transactional_email(to_email, subject, html_content)
        return True
    except Exception as e:
        print(f'Email delivery error: {e}')
        return False


def send_hr_correction_email(to_email, subject, html_content):
    try:
        send_transactional_email(
            to_email,
            subject,
            html_content,
            resend_api_key_env='HR_RESEND_API_KEY',
            from_email_env='HR_EMAIL_FROM',
        )
        return True
    except Exception as e:
        print(f'HR correction email delivery error: {e}')
        return False


def _payslip_email_html(employee_name, employee_id, month_label, net_salary, download_url=''):
    download_section = ''
    if download_url:
        download_section = f'<p style="margin-top:16px;"><a href="{download_url}" style="background:#4FACFE;color:#fff;padding:10px 22px;border-radius:6px;text-decoration:none;font-weight:bold;">Download Payslip</a></p>'
    return f"""
    <div style="font-family:Arial,sans-serif;max-width:620px;margin:auto;padding:30px;border:1px solid #e5e7eb;border-radius:10px;">
      <h2 style="margin-top:0;color:#0f75bc;">Your Payslip is Ready</h2>
      <p>Dear <b>{employee_name}</b>,</p>
      <p>Your payslip for <b>{month_label}</b> has been generated and is attached to this email.</p>
      <div style="background:#f0f9ff;padding:18px;border-radius:8px;margin:20px 0;">
        <p style="margin:0;"><b>Employee ID:</b> {employee_id}</p>
        <p style="margin:8px 0 0 0;"><b>Pay Period:</b> {month_label}</p>
        <p style="margin:8px 0 0 0;"><b>Net Salary:</b> ₹{net_salary}</p>
      </div>
      <p>The payslip PDF is attached. Please keep it for your records.</p>
      {download_section}
      <br/>
      <p>Regards,</p>
      <p><b>Bitbyte HR Team</b></p>
    </div>
    """


def _payroll_summary_email_html(month_label, total_employees, total_net_salary, generated_by):
    return f"""
    <div style="font-family:Arial,sans-serif;max-width:620px;margin:auto;padding:30px;border:1px solid #e5e7eb;border-radius:10px;">
      <h2 style="margin-top:0;color:#0f75bc;">Payroll Published – {month_label}</h2>
      <p>Payroll for <b>{month_label}</b> has been successfully generated and published.</p>
      <div style="background:#f0fff4;padding:18px;border-radius:8px;margin:20px 0;">
        <p style="margin:0;"><b>Pay Period:</b> {month_label}</p>
        <p style="margin:8px 0 0 0;"><b>Employees Processed:</b> {total_employees}</p>
        <p style="margin:8px 0 0 0;"><b>Total Net Salary:</b> ₹{total_net_salary}</p>
        <p style="margin:8px 0 0 0;"><b>Generated By:</b> {generated_by}</p>
      </div>
      <p>All employee payslips have been emailed to the respective employees.</p>
      <br/>
      <p>Regards,</p>
      <p><b>Bitbyte Payroll System</b></p>
    </div>
    """


def _send_payslip_to_employee(payslip, request=None):
    """Email the payslip PDF to the employee. Silently skips if no email or PDF found."""
    try:
        account = EmployeeAccount.objects.filter(employee_id=payslip.employee_id).select_related('registration').first()
        if not account:
            return

        to_email = account.employee_email
        if not to_email:
            return

        reg = account.registration
        employee_name = f'{reg.first_name} {reg.last_name}'.strip() or account.employee_id

        from calendar import month_name as _month_names
        month_label = f'{_month_names[payslip.month]} {payslip.year}'
        net_salary = str(payslip.net_salary)

        download_url = ''
        if payslip.pdf_file:
            try:
                url = payslip.pdf_file.url
                download_url = request.build_absolute_uri(url) if request and url.startswith('/') else url
            except Exception:
                pass

        html = _payslip_email_html(employee_name, payslip.employee_id, month_label, net_salary, download_url)

        sg = SendGridAPIClient(os.getenv('SENDGRID_API_KEY'))
        message = Mail(
            from_email=os.getenv('EMAIL_FROM', 'noreply@bitbyte.com'),
            to_emails=to_email,
            subject=f'Your Payslip – {month_label} | Bitbyte',
            html_content=html,
        )

        # Attach the PDF if the file exists on storage
        if payslip.pdf_file:
            try:
                pdf_bytes = payslip.pdf_file.read()
                encoded_pdf = base64.b64encode(pdf_bytes).decode('ascii')
                message.attachment = Attachment(
                    FileContent(encoded_pdf),
                    FileName(f'{payslip.employee_id}-{payslip.year}-{payslip.month:02d}-payslip.pdf'),
                    FileType('application/pdf'),
                    Disposition('attachment'),
                )
            except Exception as attach_err:
                print(f'Payslip PDF attach error for {payslip.employee_id}: {attach_err}')

        sg.send(message)
    except Exception as e:
        print(f'Payslip email error for {payslip.employee_id}: {e}')


def _send_payroll_summary_to_management(year, month, payslips, generated_by, request=None):
    """Email a payroll summary to HR, MD, Admin, and SuperAdmin users."""
    try:
        from calendar import month_name as _month_names
        month_label = f'{_month_names[month]} {year}'
        total_employees = len(payslips)
        total_net = sum(p.net_salary for p in payslips)
        html = _payroll_summary_email_html(month_label, total_employees, str(total_net), generated_by)

        management_roles = ['hr', 'md', 'admin', 'superadmin', 'ceo']
        recipients = list(
            User.objects.filter(role__in=management_roles, is_active=True)
            .values_list('email', flat=True)
            .distinct()
        )
        if not recipients:
            return

        sg = SendGridAPIClient(os.getenv('SENDGRID_API_KEY'))
        for email in recipients:
            try:
                message = Mail(
                    from_email=os.getenv('EMAIL_FROM', 'noreply@bitbyte.com'),
                    to_emails=email,
                    subject=f'Payroll Published – {month_label} | Bitbyte',
                    html_content=html,
                )
                sg.send(message)
            except Exception as per_email_err:
                print(f'Payroll summary email error for {email}: {per_email_err}')
    except Exception as e:
        print(f'Payroll summary email error: {e}')


def _employee_credentials_html(emp, account):
    return f"""
    <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:30px;border:1px solid #eee;border-radius:10px;">
        <h2 style="color:#4FACFE;">Welcome to Bitbyte!</h2>
        <p>Dear <b>{emp.first_name} {emp.last_name}</b>,</p>
        <p>Your employee registration has been verified successfully by HR.</p>
        <div style="background:#f0f9ff;padding:20px;border-radius:8px;margin:20px 0;">
            <h3 style="margin:0 0 10px 0;color:#2d3748;">Your Login Credentials</h3>
            <p><b>Employee ID:</b> {account.employee_id}</p>
            <p><b>Email:</b> {account.employee_email}</p>
            <p><b>One Time Credential (OTC):</b> <span style="font-size:20px;color:#4FACFE;font-weight:bold;">{account.otc}</span></p>
        </div>
        <div style="background:#f0fff4;padding:20px;border-radius:8px;margin:20px 0;">
            <h3 style="margin:0 0 10px 0;color:#2d3748;">Employment Details</h3>
            <p><b>Department:</b> {account.get_department_display()}</p>
            <p><b>Designation:</b> {account.get_designation_display()}</p>
            <p><b>Date of Joining:</b> {account.date_of_joining}</p>
            <p><b>Employment Type:</b> {account.get_employment_type_display()}</p>
            <p><b>Reporting TL:</b> {account.reporting_tl or 'N/A'}</p>
            <p><b>Work Mode:</b> {_work_mode_display(account.work_location)}</p>
        </div>
        <p>Please login with your Employee ID or registered email and the OTC above.</p>
        <p>You will be asked to change your password on first login.</p>
        <p style="color:#e53e3e;"><b>Note: This OTC is valid for first login only.</b></p>
        <br/>
        <p>Regards,</p>
        <p><b>Bitbyte HR Team</b></p>
    </div>
    """


def _work_mode_display(value):
    """Convert work_location value to display format"""
    modes = {
        'work_from_home': 'Work From Home',
        'hybrid': 'Hybrid',
        'onsite': 'OnSite',
    }
    return modes.get(value, value.replace('_', ' ').title() if value else 'N/A')


def _ensure_employee_account_and_send_otc(emp, data=None):
    data = data or {}
    account = EmployeeAccount.objects.filter(registration=emp).first()
    if account is None:
        account = EmployeeAccount(
            registration=emp,
            employee_email=data.get('employee_email') or emp.personal_email,
            department=data.get('department') or 'hr',
            designation=data.get('designation') or 'associate',
            date_of_joining=data.get('date_of_joining') or timezone.localdate(),
            employment_type=data.get('employment_type') or 'full_time',
            reporting_tl=data.get('reporting_tl', ''),
            work_location=data.get('work_location', ''),
        )
        account.save()
    else:
        updated = False
        for field in [
            'employee_email',
            'department',
            'designation',
            'date_of_joining',
            'employment_type',
            'reporting_tl',
            'work_location',
        ]:
            value = data.get(field)
            if value not in [None, ''] and getattr(account, field) != value:
                setattr(account, field, value)
                updated = True
        if updated:
            account.save()

    user = (
        User.objects.filter(user_id=account.employee_id).first()
        or User.objects.filter(email=account.employee_email).first()
    )
    if user is None:
        user = User(
            email=account.employee_email,
            role='employee',
            first_name=emp.first_name,
            last_name=emp.last_name,
            phone=emp.mobile,
        )
        user.user_id = account.employee_id
        user.set_password(account.otc)
        user.save()
    else:
        user.email = account.employee_email
        user.first_name = emp.first_name
        user.last_name = emp.last_name
        user.phone = emp.mobile
        user.save()

    html = _employee_credentials_html(emp, account)
    send_email(account.employee_email, 'Welcome to Bitbyte - Your Login Credentials', html)
    if emp.personal_email and emp.personal_email.lower() != account.employee_email.lower():
        send_email(emp.personal_email, 'Welcome to Bitbyte - Your Login Credentials', html)
    return account


@api_view(['POST'])
def verify_employee_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        emp.status = 'approved'
        emp.save()
        account = _ensure_employee_account_and_send_otc(emp, request.data)
        _create_notification(
            user_id=_employee_recipient_id(emp),
            title='Registration Verified',
            message='HR verified your registration. Login credentials have been sent to your registered email.',
            notification_type='success',
            module='documents',
            reference_id=emp.id,
        )
        return Response({
            'success': True,
            'message': 'Employee verified and OTC sent to registered email!',
            'employee_id': account.employee_id,
            'otc_sent_to': account.employee_email,
        })
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)
    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=400)


@api_view(['POST'])
def reject_employee_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        emp.status = 'rejected'
        emp.save()
        _create_notification(
            user_id=_employee_recipient_id(emp),
            title='Registration Rejected',
            message='HR rejected your employee registration. Please contact HR for details.',
            notification_type='error',
            module='documents',
            reference_id=emp.id,
        )

        # Send rejection email
        html = f"""
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:20px;border:1px solid #eee;border-radius:10px;">
            <h2 style="color:#e53e3e;">Application Update - Bitbyte</h2>
            <p>Dear <b>{emp.first_name} {emp.last_name}</b>,</p>
            <p>We regret to inform you that your employment application has been <b style="color:#e53e3e;">rejected</b>.</p>
            <p>If you have any questions, please contact our HR team.</p>
            <br/>
            <p>Regards,</p>
            <p><b>Bitbyte HR Team</b></p>
        </div>
        """
        send_email(emp.personal_email, 'Application Status - Bitbyte', html)

        return Response({'success': True, 'message': 'Employee rejected and email sent!'})
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Not found'}, status=404)


@api_view(['POST'])
def add_employee_view(request, pk):
    try:
        emp = EmployeeRegistration.objects.get(pk=pk)
        account = _ensure_employee_account_and_send_otc(emp, request.data)
        emp.status = 'approved'
        emp.save()
        _create_notification(
            user_id=_employee_recipient_id(emp),
            title='Registration Verified',
            message='HR assigned your employee details. Login credentials have been sent to your registered email.',
            notification_type='success',
            module='documents',
            reference_id=emp.id,
        )
        return Response({
            'success': True,
            'employee_id': account.employee_id,
            'otc': account.otc,
            'message': 'Employee credentials sent!'
        })

        # Create employee account
        account = EmployeeAccount(
            registration=emp,
            employee_email=request.data.get('employee_email'),
            department=request.data.get('department'),
            designation=request.data.get('designation'),
            date_of_joining=request.data.get('date_of_joining'),
            employment_type=request.data.get('employment_type'),
            reporting_tl=request.data.get('reporting_tl', ''),
            work_location=request.data.get('work_location', ''),
        )
        account.save()

        # Create User account with OTC as password
        user = User(
            email=account.employee_email,
            role='employee',
            first_name=emp.first_name,
            last_name=emp.last_name,
            phone=emp.mobile,
        )
        user.set_password(account.otc)
        user.user_id = account.employee_id
        user.save()

        # Send welcome email with OTC
        html = f"""
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:30px;border:1px solid #eee;border-radius:10px;">
            <h2 style="color:#4FACFE;">Welcome to Bitbyte! 🎉</h2>
            <p>Dear <b>{emp.first_name} {emp.last_name}</b>,</p>
            <p>Congratulations! Your employment has been confirmed.</p>
            <div style="background:#f0f9ff;padding:20px;border-radius:8px;margin:20px 0;">
                <h3 style="margin:0 0 10px 0;color:#2d3748;">Your Login Credentials</h3>
                <p><b>Employee ID:</b> {account.employee_id}</p>
                <p><b>Email:</b> {account.employee_email}</p>
                <p><b>One Time Password (OTC):</b> <span style="font-size:20px;color:#4FACFE;font-weight:bold;">{account.otc}</span></p>
            </div>
            <div style="background:#f0fff4;padding:20px;border-radius:8px;margin:20px 0;">
                <h3 style="margin:0 0 10px 0;color:#2d3748;">Employment Details</h3>
                <p><b>Department:</b> {account.department}</p>
                <p><b>Designation:</b> {account.designation}</p>
                <p><b>Date of Joining:</b> {account.date_of_joining}</p>
                <p><b>Employment Type:</b> {account.employment_type}</p>
                <p><b>Reporting TL:</b> {account.reporting_tl or 'N/A'}</p>
                <p><b>Work Mode:</b> {_work_mode_display(account.work_location)}</p>
            </div>
            <p>Please login with your Employee ID or Email and the OTC above.</p>
            <p>You will be asked to change your password on first login.</p>
            <p style="color:#e53e3e;"><b>Note: This OTC is valid for first login only.</b></p>
            <br/>
            <p>Regards,</p>
            <p><b>Bitbyte HR Team</b></p>
        </div>
        """
        send_email(account.employee_email, 'Welcome to Bitbyte - Your Login Credentials', html)
        # Also send to personal email
        send_email(emp.personal_email, 'Welcome to Bitbyte - Your Login Credentials', html)

        return Response({
            'success': True,
            'employee_id': account.employee_id,
            'otc': account.otc,
            'message': 'Employee added and credentials sent!'
        })
    except EmployeeRegistration.DoesNotExist:
        return Response({'success': False, 'message': 'Registration not found'}, status=404)
    except Exception as e:
        return Response({'success': False, 'message': str(e)}, status=400)

@api_view(['POST'])
def change_password_view(request):
    employee_id = request.data.get('employee_id')
    otc = request.data.get('otc')
    new_password = request.data.get('new_password')

    try:
        user = User.objects.get(user_id=employee_id)
        reset_key = f'password_reset:{user.user_id}'
        reset_otc = cache.get(reset_key)
        valid_current_password = user.check_password(otc)
        valid_reset_otc = bool(reset_otc) and str(reset_otc) == str(otc)
        if not valid_current_password and not valid_reset_otc:
            return Response({'success': False, 'message': 'Invalid OTC'}, status=400)
        user.set_password(new_password)
        user.save()
        if valid_reset_otc:
            cache.delete(reset_key)
            EmployeeAccount.objects.filter(
                employee_email__iexact=user.email,
            ).update(otc='')
        return Response({'success': True, 'message': 'Password changed!'})
    except User.DoesNotExist:
        return Response({'success': False, 'message': 'Employee not found'}, status=404)
