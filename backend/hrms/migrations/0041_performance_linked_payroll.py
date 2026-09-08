from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0040_companyleave')]

    operations = [
        migrations.AddField(
            model_name='salarystructure',
            name='performance_incentive_percent',
            field=models.DecimalField(decimal_places=2, default=10, max_digits=5),
        ),
        migrations.AlterField(
            model_name='payslip',
            name='paid_days',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=5),
        ),
        migrations.AlterField(
            model_name='payslip',
            name='lop_days',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=5),
        ),
        migrations.AddField(
            model_name='payslip',
            name='performance_score',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=3),
        ),
        migrations.AddField(
            model_name='payslip',
            name='performance_incentive',
            field=models.DecimalField(decimal_places=2, default=0, max_digits=10),
        ),
    ]
