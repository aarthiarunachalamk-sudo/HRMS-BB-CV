from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0010_clientvisit_service_type'),
    ]

    operations = [
        migrations.CreateModel(
            name='ClientServiceDetails',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_by_user_id', models.CharField(db_index=True, max_length=20)),
                ('client_name', models.CharField(max_length=160)),
                ('client_email', models.EmailField(max_length=254)),
                ('client_mobile', models.CharField(max_length=20)),
                ('client_details', models.TextField()),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'Client details',
                'verbose_name_plural': 'Client details',
                'ordering': ['-created_at', '-id'],
            },
        ),
    ]
