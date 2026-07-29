from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [('hrms', '0039_employeeattendancerecord_work_mode')]

    operations = [
        migrations.CreateModel(
            name='CompanyLeave',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=180)),
                ('message', models.TextField(blank=True)),
                ('from_date', models.DateField(db_index=True)),
                ('to_date', models.DateField(db_index=True)),
                ('announced_by', models.CharField(blank=True, max_length=40)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('announcement', models.OneToOneField(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='company_leave', to='hrms.announcement')),
            ],
            options={'ordering': ['-from_date', '-created_at']},
        ),
    ]
