from django.db import migrations
import cloudinary.models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0018_role_id_choices'),
    ]

    operations = [
        migrations.AddField(
            model_name='employeeregistration',
            name='doc_college_noc',
            field=cloudinary.models.CloudinaryField(
                blank=True,
                max_length=255,
                null=True,
                verbose_name='image',
            ),
        ),
    ]
