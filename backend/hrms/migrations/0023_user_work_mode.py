from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0022_payrollprocess'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='work_mode',
            field=models.CharField(
                choices=[
                    ('work_from_home', 'Work From Home'),
                    ('hybrid', 'Hybrid'),
                    ('onsite', 'OnSite'),
                ],
                default='onsite',
                max_length=20,
            ),
        ),
    ]
