from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0003_attachment_storage_isolation'),
    ]

    operations = [
        migrations.AlterField(
            model_name='clientvisit',
            name='attendees',
            field=models.JSONField(blank=True, db_default=[], default=list),
        ),
        migrations.AlterField(
            model_name='clientvisit',
            name='checklist',
            field=models.JSONField(blank=True, db_default=[], default=list),
        ),
        migrations.AlterField(
            model_name='clientvisit',
            name='return_mode',
            field=models.CharField(blank=True, db_default='', max_length=24),
        ),
        migrations.AlterField(
            model_name='clientvisit',
            name='manager_verified_by',
            field=models.CharField(blank=True, db_default='', max_length=20),
        ),
    ]
