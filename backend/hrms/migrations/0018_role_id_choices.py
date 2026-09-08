from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0017_salarystructure_payslip'),
    ]

    operations = [
        migrations.AlterField(
            model_name='employeeaccount',
            name='designation',
            field=models.CharField(
                choices=[
                    ('associate', 'Associate'),
                    ('intern', 'Intern'),
                    ('tl', 'TL'),
                    ('admin', 'Admin'),
                    ('hr', 'HR'),
                    ('ceo', 'CEO'),
                    ('md', 'MD'),
                    ('director', 'Director'),
                    ('manager', 'Manager'),
                ],
                max_length=50,
            ),
        ),
        migrations.AlterField(
            model_name='user',
            name='role',
            field=models.CharField(
                choices=[
                    ('superadmin', 'Super Admin'),
                    ('ceo', 'CEO'),
                    ('md', 'MD'),
                    ('director', 'Director'),
                    ('hr', 'HR'),
                    ('finance', 'Finance'),
                    ('marketing', 'Marketing Team'),
                    ('it', 'IT Team'),
                    ('admin', 'Admin'),
                    ('manager', 'Manager'),
                    ('tl', 'TL'),
                    ('employee', 'Employee'),
                ],
                default='employee',
                max_length=20,
            ),
        ),
    ]
