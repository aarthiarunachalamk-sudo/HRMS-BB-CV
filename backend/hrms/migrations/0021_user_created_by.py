from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0020_user_department'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='created_by',
            field=models.CharField(blank=True, db_index=True, max_length=40),
        ),
    ]
