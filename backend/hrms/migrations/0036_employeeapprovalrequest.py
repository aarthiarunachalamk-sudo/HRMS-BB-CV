from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0035_employee_leave_session')]

    operations = [
        migrations.CreateModel(
            name='EmployeeApprovalRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('employee_id', models.CharField(db_index=True, max_length=40)),
                ('sender_role', models.CharField(default='employee', max_length=20)),
                ('department', models.CharField(blank=True, max_length=80)),
                ('assigned_tl_user_id', models.CharField(blank=True, db_index=True, max_length=40)),
                ('request_type', models.CharField(default='daily_report', max_length=50)),
                ('title', models.CharField(max_length=180)),
                ('request_date', models.DateField()),
                ('session', models.CharField(max_length=20)),
                ('task_details', models.TextField()),
                ('expected_result', models.TextField()),
                ('actual_result', models.TextField()),
                ('approvers', models.JSONField(default=list)),
                ('decisions', models.JSONField(default=list)),
                ('current_stage', models.PositiveSmallIntegerField(default=0)),
                ('status', models.CharField(choices=[('requested', 'Requested'), ('approved', 'Approved'), ('rejected', 'Rejected'), ('cancelled', 'Cancelled')], default='requested', max_length=20)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
