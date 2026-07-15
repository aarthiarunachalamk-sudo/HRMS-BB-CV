from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [('hrms', '0025_organizationdepartment')]

    operations = [
        migrations.CreateModel(
            name='RecruitmentJobOpening',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=140)),
                ('department', models.CharField(max_length=100)),
                ('location', models.CharField(blank=True, max_length=120)),
                ('openings', models.PositiveIntegerField(default=1)),
                ('status', models.CharField(choices=[('open', 'Open'), ('paused', 'Paused'), ('closed', 'Closed')], default='open', max_length=20)),
                ('created_by', models.CharField(blank=True, max_length=40)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={'ordering': ['-created_at']},
        ),
        migrations.AddField(model_name='employeeregistration', name='recruitment_stage', field=models.CharField(db_index=True, default='applied', max_length=30)),
        migrations.AddField(model_name='employeeregistration', name='interview_data', field=models.JSONField(blank=True, default=dict)),
        migrations.AddField(model_name='employeeregistration', name='offer_data', field=models.JSONField(blank=True, default=dict)),
        migrations.AddField(model_name='employeeregistration', name='onboarding_checklist', field=models.JSONField(blank=True, default=dict)),
        migrations.AddField(
            model_name='employeeregistration',
            name='applied_job',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='candidates', to='hrms.recruitmentjobopening'),
        ),
    ]
