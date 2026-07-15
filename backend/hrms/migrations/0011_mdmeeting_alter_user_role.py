from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0010_leave_tl_hr_approval'),
    ]

    operations = [
        migrations.CreateModel(
            name='MdMeeting',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=120)),
                ('meeting_type', models.CharField(blank=True, max_length=80)),
                ('location', models.CharField(blank=True, max_length=120)),
                ('description', models.TextField(blank=True)),
                ('date_label', models.CharField(blank=True, max_length=40)),
                ('time_label', models.CharField(blank=True, max_length=60)),
                ('duration', models.CharField(blank=True, max_length=40)),
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
        migrations.AlterField(
            model_name='user',
            name='role',
            field=models.CharField(choices=[('superadmin', 'Super Admin'), ('ceo', 'CEO'), ('md', 'MD'), ('hr', 'HR'), ('finance', 'Finance'), ('marketing', 'Marketing Team'), ('it', 'IT Team'), ('admin', 'Admin'), ('manager', 'Manager'), ('tl', 'TL'), ('employee', 'Employee')], default='employee', max_length=20),
        ),
    ]
