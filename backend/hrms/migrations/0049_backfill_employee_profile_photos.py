from django.db import migrations


def backfill_employee_profile_photos(apps, schema_editor):
    User = apps.get_model('hrms', 'User')
    EmployeeAccount = apps.get_model('hrms', 'EmployeeAccount')

    accounts = EmployeeAccount.objects.select_related('registration').all()
    for account in accounts.iterator():
        registration = account.registration
        registration_photo = getattr(registration, 'doc_passport_photo', None)
        photo_name = getattr(registration_photo, 'name', '') or str(registration_photo or '')
        if not photo_name:
            continue

        users = User.objects.filter(email__iexact=account.employee_email)
        for user in users.iterator():
            current_photo = getattr(user.profile_photo, 'name', '') or str(user.profile_photo or '')
            if current_photo:
                continue
            user.profile_photo = photo_name
            user.save(update_fields=['profile_photo'])


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0048_user_notification_preferences'),
    ]

    operations = [
        migrations.RunPython(backfill_employee_profile_photos, migrations.RunPython.noop),
    ]
