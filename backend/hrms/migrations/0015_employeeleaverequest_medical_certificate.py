from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0014_teamtask'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeleaverequest',
            name='medical_certificate',
            field=models.CharField(blank=True, max_length=255),
        ),
    ]
