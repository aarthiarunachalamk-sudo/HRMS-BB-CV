# Generated for MD dashboard meeting scheduling.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0003_alter_user_role'),
    ]

    operations = [
        migrations.CreateModel(
            name='MdMeeting',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=120)),
                ('meeting_type', models.CharField(default='Board Meeting', max_length=80)),
                ('location', models.CharField(blank=True, max_length=120)),
                ('description', models.TextField(blank=True)),
                ('date_label', models.CharField(default='Tue, 21 May 2024', max_length=40)),
                ('time_label', models.CharField(default='10:00 AM - 11:00 AM', max_length=60)),
                ('duration', models.CharField(default='1 Hour', max_length=40)),
                ('status', models.CharField(choices=[('upcoming', 'Upcoming'), ('past', 'Past'), ('cancelled', 'Cancelled')], default='upcoming', max_length=20)),
                ('participants', models.JSONField(blank=True, default=list)),
                ('agenda', models.JSONField(blank=True, default=list)),
                ('created_by', models.CharField(blank=True, max_length=40)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
