from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0009_attendance_mobile_timezone'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeleaverequest',
            name='hr_approved_by',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='employeeleaverequest',
            name='hr_reviewed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='employeeleaverequest',
            name='hr_status',
            field=models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')], default='pending', max_length=20),
        ),
        migrations.AddField(
            model_name='employeeleaverequest',
            name='tl_approved_by',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='employeeleaverequest',
            name='tl_reviewed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='employeeleaverequest',
            name='tl_status',
            field=models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')], default='pending', max_length=20),
        ),
    ]
