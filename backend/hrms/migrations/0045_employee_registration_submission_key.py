from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0044_expand_employee_blood_groups')]

    operations = [
        migrations.AddField(
            model_name='employeeregistration',
            name='submission_key',
            field=models.CharField(
                blank=True,
                editable=False,
                max_length=80,
                null=True,
                unique=True,
            ),
        ),
    ]
