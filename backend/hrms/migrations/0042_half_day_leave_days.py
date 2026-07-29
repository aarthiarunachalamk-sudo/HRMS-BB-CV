from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0041_performance_linked_payroll'),
    ]

    operations = [
        migrations.AlterField(
            model_name='employeeleaverequest',
            name='total_days',
            field=models.DecimalField(decimal_places=2, default=1, max_digits=5),
        ),
    ]
