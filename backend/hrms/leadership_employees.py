from django.db import transaction
from django.utils import timezone

from .models import EmployeeAccount, EmployeeRegistration


EMPLOYEE_ENABLED_ROLES = {'ceo', 'hr', 'admin', 'tl', 'director', 'md'}


def _account_email(user):
    """Keep the real email when available; create a stable alias on collision."""
    email = (user.email or '').strip().lower()
    existing = EmployeeAccount.objects.filter(employee_email__iexact=email).first()
    if existing is None or existing.user_id == user.pk:
        return email
    local, separator, domain = email.partition('@')
    if not separator:
        return f'{user.user_id.lower()}@employee.local'
    return f'{local}+{user.user_id.lower()}@{domain}'


@transaction.atomic
def ensure_leadership_employee_account(user):
    """Provision a separate employee identity without changing role login data."""
    if not user or user.role not in EMPLOYEE_ENABLED_ROLES:
        return None

    account = EmployeeAccount.objects.select_related('registration').filter(user=user).first()
    if account:
        return account

    # Link a legacy account for the same email before creating anything new.
    account = EmployeeAccount.objects.filter(employee_email__iexact=user.email, user__isnull=True).first()
    if account:
        account.user = user
        account.save(update_fields=['user'])
        return account

    registration = EmployeeRegistration.objects.create(
        first_name=user.first_name or user.get_role_display(),
        last_name=user.last_name or '',
        gender=user.gender or 'other',
        dob=user.dob.isoformat() if user.dob else '',
        mobile=(user.phone or '')[-10:],
        personal_email=user.email,
        marital_status='other',
        blood_group='O+',
        nationality='Indian',
        current_door=user.door_no or '',
        current_street=user.street or '',
        current_city=user.city or '',
        current_state=user.state or '',
        permanent_city=user.city or '',
        permanent_state=user.state or '',
        emergency_name='',
        emergency_relationship='',
        emergency_contact='',
        aadhar=user.aadhar or '',
        pan=user.pan or '',
        qualification='',
        college='',
        year_of_passing='',
        percentage='',
        account_holder=f'{user.first_name} {user.last_name}'.strip(),
        bank_name='',
        account_number='',
        ifsc_code='',
        branch_name='',
        status='approved',
    )
    return EmployeeAccount.objects.create(
        user=user,
        registration=registration,
        employee_email=_account_email(user),
        department=user.department or ('management' if user.role in {'ceo', 'md', 'director', 'admin'} else user.role),
        designation=user.role,
        date_of_joining=timezone.localdate(),
        employment_type='full_time',
        work_location=user.work_mode or 'onsite',
        is_active=user.is_active,
    )
