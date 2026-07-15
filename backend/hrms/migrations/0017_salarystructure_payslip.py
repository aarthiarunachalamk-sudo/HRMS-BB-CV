from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0016_alter_employeeleaverequest_medical_certificate'),
    ]

    operations = [
        migrations.CreateModel(
            name='SalaryStructure',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('employee_id', models.CharField(db_index=True, max_length=20, unique=True)),
                ('basic_salary', models.DecimalField(decimal_places=2, default=40000, max_digits=10)),
                ('hra', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('conveyance_allowance', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('medical_allowance', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('special_allowance', models.DecimalField(decimal_places=2, default=8000, max_digits=10)),
                ('other_allowance', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('pf_employee', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('esi_employee', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('professional_tax', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('tds', models.DecimalField(decimal_places=2, default=2000, max_digits=10)),
                ('other_deduction', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('overtime_rate_per_hour', models.DecimalField(decimal_places=2, default=150, max_digits=10)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.CreateModel(
            name='Payslip',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('employee_id', models.CharField(db_index=True, max_length=20)),
                ('year', models.PositiveIntegerField()),
                ('month', models.PositiveIntegerField()),
                ('working_days', models.PositiveIntegerField(default=0)),
                ('paid_days', models.PositiveIntegerField(default=0)),
                ('lop_days', models.PositiveIntegerField(default=0)),
                ('overtime_minutes', models.PositiveIntegerField(default=0)),
                ('gross_salary', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('total_earnings', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('total_deductions', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('net_salary', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('earnings', models.JSONField(blank=True, default=dict)),
                ('deductions', models.JSONField(blank=True, default=dict)),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('approved', 'Approved'), ('paid', 'Paid')], default='approved', max_length=20)),
                ('generated_by', models.CharField(blank=True, max_length=80)),
                ('paid_date', models.DateField(blank=True, null=True)),
                ('pdf_file', models.FileField(blank=True, null=True, upload_to='payslips/')),
                ('generated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['-year', '-month'],
                'unique_together': {('employee_id', 'year', 'month')},
            },
        ),
    ]
