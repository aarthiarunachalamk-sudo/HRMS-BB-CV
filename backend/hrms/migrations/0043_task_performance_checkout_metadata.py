from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0042_half_day_leave_days')]

    operations = [
        migrations.AddField(
            model_name='teamtask', name='completed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='teamtask', name='review_status',
            field=models.CharField(default='pending', max_length=20),
        ),
        migrations.AddField(
            model_name='teamtask', name='quality_score',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True),
        ),
        migrations.AddField(
            model_name='teamtask', name='blocked_approved',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='teamtask', name='priority',
            field=models.CharField(choices=[('Low', 'Low'), ('Medium', 'Medium'), ('High', 'High'), ('Critical', 'Critical'), ('Urgent', 'Urgent')], default='Medium', max_length=20),
        ),
        migrations.AlterField(
            model_name='teamtask', name='status',
            field=models.CharField(choices=[('pending', 'Pending'), ('in_progress', 'In Progress'), ('completed', 'Completed'), ('rejected', 'Rejected'), ('reopened', 'Reopened'), ('cancelled', 'Cancelled by Management'), ('blocked', 'Blocked')], default='pending', max_length=20),
        ),
        migrations.AddField(
            model_name='employeeperformance', name='calculated_score',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=5, null=True),
        ),
        migrations.AddField(
            model_name='employeeperformance', name='score_breakdown',
            field=models.JSONField(blank=True, default=dict),
        ),
        migrations.AddField(
            model_name='employeeperformance', name='is_provisional',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='employeeattendancerecord', name='checkout_source',
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AddField(
            model_name='employeeattendancerecord', name='is_auto_checkout',
            field=models.BooleanField(default=False),
        ),
    ]
