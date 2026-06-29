from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0005_remove_mdmeeting_fixed_defaults'),
    ]

    operations = [
        migrations.AlterField(
            model_name='user',
            name='role',
            field=models.CharField(
                choices=[
                    ('superadmin', 'Super Admin'),
                    ('ceo', 'CEO'),
                    ('md', 'MD'),
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
