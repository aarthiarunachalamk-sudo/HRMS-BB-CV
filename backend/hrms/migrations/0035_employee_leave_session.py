from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0034_employee_document_resource_types')]

    operations = [
        migrations.AddField(
            model_name='employeeleaverequest',
            name='session',
            field=models.CharField(default='Full Day', max_length=20),
        ),
    ]
