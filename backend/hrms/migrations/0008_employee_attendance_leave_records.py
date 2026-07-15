from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0007_employeeaccount_employeeregistration_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='EmployeeAttendanceRecord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('employee_id', models.CharField(db_index=True, max_length=20)),
                ('attendance_date', models.DateField(db_index=True)),
                ('status', models.CharField(default='Present', max_length=20)),
                ('check_in', models.DateTimeField(blank=True, null=True)),
                ('check_out', models.DateTimeField(blank=True, null=True)),
                ('working_hours', models.CharField(blank=True, max_length=20)),
                ('check_in_latitude', models.CharField(blank=True, max_length=40)),
                ('check_in_longitude', models.CharField(blank=True, max_length=40)),
                ('check_in_accuracy', models.CharField(blank=True, max_length=40)),
                ('check_out_latitude', models.CharField(blank=True, max_length=40)),
                ('check_out_longitude', models.CharField(blank=True, max_length=40)),
                ('check_out_accuracy', models.CharField(blank=True, max_length=40)),
                ('check_in_selfie', models.FileField(blank=True, null=True, upload_to='attendance/check_in/')),
                ('check_out_selfie', models.FileField(blank=True, null=True, upload_to='attendance/check_out/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['-attendance_date'],
                'unique_together': {('employee_id', 'attendance_date')},
            },
        ),
        migrations.CreateModel(
            name='EmployeeLeaveRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('employee_id', models.CharField(db_index=True, max_length=20)),
                ('leave_type', models.CharField(max_length=50)),
                ('from_date', models.DateField(db_index=True)),
                ('to_date', models.DateField(db_index=True)),
                ('total_days', models.PositiveIntegerField(default=1)),
                ('reason', models.TextField(blank=True)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')], default='pending', max_length=20)),
                ('approved_by', models.CharField(blank=True, max_length=100)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['-from_date'],
            },
        ),
    ]
