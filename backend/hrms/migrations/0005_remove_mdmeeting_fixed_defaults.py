# Generated for MD meeting backend-driven values.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0004_mdmeeting'),
    ]

    operations = [
        migrations.AlterField(
            model_name='mdmeeting',
            name='date_label',
            field=models.CharField(blank=True, max_length=40),
        ),
        migrations.AlterField(
            model_name='mdmeeting',
            name='duration',
            field=models.CharField(blank=True, max_length=40),
        ),
        migrations.AlterField(
            model_name='mdmeeting',
            name='meeting_type',
            field=models.CharField(blank=True, max_length=80),
        ),
        migrations.AlterField(
            model_name='mdmeeting',
            name='time_label',
            field=models.CharField(blank=True, max_length=60),
        ),
    ]
