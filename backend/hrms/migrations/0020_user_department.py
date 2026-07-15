from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0019_employee_registration_college_noc'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='department',
            field=models.CharField(blank=True, max_length=50),
        ),
    ]
