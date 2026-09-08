from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0043_task_performance_checkout_metadata')]

    operations = [
        migrations.AlterField(
            model_name='employeeregistration',
            name='blood_group',
            field=models.CharField(
                choices=[
                    ('A+', 'A+'), ('A−', 'A−'), ('A1+', 'A1+'), ('A1−', 'A1−'),
                    ('A2+', 'A2+'), ('A2−', 'A2−'), ('B+', 'B+'), ('B−', 'B−'),
                    ('AB+', 'AB+'), ('AB−', 'AB−'), ('A1B+', 'A1B+'),
                    ('A1B−', 'A1B−'), ('A2B+', 'A2B+'), ('A2B−', 'A2B−'),
                    ('O+', 'O+'), ('O−', 'O−'),
                    ('Bombay phenotype (Oh/hh)', 'Bombay phenotype (Oh/hh)'),
                    ('Para-Bombay phenotype', 'Para-Bombay phenotype'),
                    ('Unknown', 'Unknown'),
                ],
                max_length=30,
            ),
        ),
    ]
