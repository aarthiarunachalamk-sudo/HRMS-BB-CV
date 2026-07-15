from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0011_mdmeeting_alter_user_role'),
    ]

    operations = [
        migrations.CreateModel(
            name='AppNotification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('recipient_user_id', models.CharField(blank=True, db_index=True, max_length=40)),
                ('recipient_role', models.CharField(blank=True, db_index=True, max_length=30)),
                ('title', models.CharField(max_length=120)),
                ('message', models.TextField(blank=True)),
                ('notification_type', models.CharField(choices=[('info', 'Info'), ('success', 'Success'), ('warning', 'Warning'), ('error', 'Error')], default='info', max_length=20)),
                ('module', models.CharField(blank=True, max_length=40)),
                ('reference_id', models.CharField(blank=True, max_length=40)),
                ('is_read', models.BooleanField(default=False)),
                ('push_sent', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='MobileDeviceToken',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('user_id', models.CharField(db_index=True, max_length=40)),
                ('role', models.CharField(blank=True, max_length=30)),
                ('token', models.TextField(unique=True)),
                ('platform', models.CharField(blank=True, max_length=20)),
                ('is_active', models.BooleanField(default=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['-updated_at'],
            },
        ),
    ]
