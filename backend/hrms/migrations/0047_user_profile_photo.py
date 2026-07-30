from django.db import migrations
import cloudinary.models


class Migration(migrations.Migration):
    dependencies = [
        ('hrms', '0046_employeeleaverequest_approver_comments'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='profile_photo',
            field=cloudinary.models.CloudinaryField(
                blank=True,
                max_length=255,
                null=True,
                verbose_name='image',
            ),
        ),
    ]
