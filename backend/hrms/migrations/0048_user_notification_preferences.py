from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0047_user_profile_photo')]

    operations = [
        migrations.AddField(
            model_name='user',
            name='notification_preferences',
            field=models.JSONField(blank=True, default=dict),
        ),
    ]
