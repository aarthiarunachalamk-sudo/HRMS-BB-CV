from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0011_clientservicedetails'),
    ]

    operations = [
        migrations.AddField(
            model_name='clientservicedetails',
            name='client_gst',
            field=models.CharField(blank=True, max_length=15),
        ),
        migrations.AddField(
            model_name='clientservicedetails',
            name='client_address',
            field=models.CharField(blank=True, max_length=500),
        ),
    ]
