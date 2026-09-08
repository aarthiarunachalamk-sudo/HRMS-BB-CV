from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0008_employee_attendance_leave_records'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeattendancerecord',
            name='check_in_timezone_offset_minutes',
            field=models.IntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='employeeattendancerecord',
            name='check_out_timezone_offset_minutes',
            field=models.IntegerField(blank=True, null=True),
        ),
    ]
