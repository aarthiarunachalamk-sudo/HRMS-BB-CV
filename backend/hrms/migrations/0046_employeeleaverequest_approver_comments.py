from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0045_employee_registration_submission_key'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeleaverequest',
            name='approver_comments',
            field=models.TextField(blank=True),
        ),
    ]
