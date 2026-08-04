from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('client_visits', '0002_visit_journey_and_verification')]
    operations = [
        migrations.AddField(
            model_name='visitattachment',
            name='cloudinary_cloud_name',
            field=models.CharField(default='legacy-client-visit-storage', max_length=120),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='visitattachment',
            name='storage_provider',
            field=models.CharField(default='cloudinary_client_visits', max_length=30),
        ),
    ]
