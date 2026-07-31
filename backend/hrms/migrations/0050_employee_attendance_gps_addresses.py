from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0049_backfill_employee_profile_photos'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeattendancerecord',
            name='check_in_address',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='employeeattendancerecord',
            name='check_out_address',
            field=models.TextField(blank=True),
        ),
    ]
