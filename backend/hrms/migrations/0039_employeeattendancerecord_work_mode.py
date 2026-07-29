from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0038_employeeapprovalrequest_leave_end_date_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeattendancerecord',
            name='work_mode',
            field=models.CharField(
                choices=[
                    ('office', 'Office'),
                    ('work_from_home', 'Work From Home'),
                    ('hybrid', 'Hybrid'),
                ],
                default='office',
                max_length=20,
            ),
        ),
    ]
