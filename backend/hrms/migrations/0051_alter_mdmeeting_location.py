from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0050_employee_attendance_gps_addresses'),
    ]

    operations = [
        migrations.AlterField(
            model_name='mdmeeting',
            name='location',
            field=models.CharField(blank=True, max_length=1000),
        ),
    ]
