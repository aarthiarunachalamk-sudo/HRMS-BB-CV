from django.db import migrations, models
import django.db.models.deletion


LEADERSHIP_ROLES = {'ceo', 'hr', 'admin', 'tl', 'director', 'md'}


def _next_employee_id(EmployeeAccount):
    number = 1
    while EmployeeAccount.objects.filter(employee_id=f'BBEMP{number:05d}').exists():
        number += 1
    return f'BBEMP{number:05d}'


def provision_existing_leadership(apps, schema_editor):
    User = apps.get_model('hrms', 'User')
    EmployeeRegistration = apps.get_model('hrms', 'EmployeeRegistration')
    EmployeeAccount = apps.get_model('hrms', 'EmployeeAccount')

    for user in User.objects.filter(role__in=LEADERSHIP_ROLES).iterator():
        if EmployeeAccount.objects.filter(user_id=user.pk).exists():
            continue
        legacy = EmployeeAccount.objects.filter(
            employee_email__iexact=user.email,
            user_id__isnull=True,
        ).first()
        if legacy:
            legacy.user_id = user.pk
            legacy.save(update_fields=['user_id'])
            continue

        registration = EmployeeRegistration.objects.create(
            first_name=user.first_name or user.role.upper(),
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
            bank_name='', account_number='', ifsc_code='', branch_name='',
            status='approved',
        )
        email = (user.email or '').lower()
        if EmployeeAccount.objects.filter(employee_email__iexact=email).exists():
            local, separator, domain = email.partition('@')
            email = f'{local}+{user.user_id.lower()}@{domain}' if separator else f'{user.user_id.lower()}@employee.local'
        EmployeeAccount.objects.create(
            user_id=user.pk,
            registration_id=registration.pk,
            employee_id=_next_employee_id(EmployeeAccount),
            employee_email=email,
            department=user.department or ('management' if user.role in {'ceo', 'md', 'director', 'admin'} else user.role),
            designation=user.role,
            date_of_joining=user.last_login.date() if user.last_login else registration.submitted_at.date(),
            employment_type='full_time',
            work_location=user.work_mode or 'onsite',
            otc='',
            is_active=user.is_active,
        )


class Migration(migrations.Migration):
    dependencies = [('hrms', '0032_alter_user_email')]

    operations = [
        migrations.AddField(
            model_name='employeeaccount',
            name='user',
            field=models.OneToOneField(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='employee_account',
                to='hrms.user',
            ),
        ),
        migrations.RunPython(provision_existing_leadership, migrations.RunPython.noop),
    ]
