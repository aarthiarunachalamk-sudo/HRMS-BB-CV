from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0015_employeeleaverequest_medical_certificate'),
    ]

    operations = [
        migrations.AlterField(
            model_name='employeeleaverequest',
            name='medical_certificate',
            field=models.FileField(blank=True, null=True, upload_to='leave_certificates/'),
        ),
    ]
