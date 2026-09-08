from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0012_appnotification_mobiledevicetoken'),
    ]

    operations = [
        migrations.AlterField(
            model_name='employeeregistration',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('approved', 'Approved'),
                    ('rejected', 'Rejected'),
                    ('flagged', 'Flagged'),
                ],
                default='pending',
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='employeeregistration',
            name='percentage',
            field=models.CharField(max_length=30),
        ),
        migrations.AddField(
            model_name='employeeregistration',
            name='document_statuses',
            field=models.JSONField(blank=True, default=dict),
        ),
        migrations.AddField(
            model_name='employeeregistration',
            name='document_review_history',
            field=models.JSONField(blank=True, default=list),
        ),
    ]
