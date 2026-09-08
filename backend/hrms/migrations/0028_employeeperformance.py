from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0027_project')]
    operations = [
        migrations.CreateModel(
            name='EmployeePerformance',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('employee_id', models.CharField(db_index=True, max_length=20)),
                ('period', models.CharField(db_index=True, max_length=40)),
                ('goals', models.JSONField(blank=True, default=list)),
                ('kpis', models.JSONField(blank=True, default=dict)),
                ('potential_score', models.DecimalField(decimal_places=2, default=0, max_digits=3)),
                ('performance_score', models.DecimalField(decimal_places=2, default=0, max_digits=3)),
                ('competency_scores', models.JSONField(blank=True, default=dict)),
                ('reviewer_comments', models.TextField(blank=True)),
                ('status', models.CharField(default='draft', max_length=20)),
                ('reviewed_by', models.CharField(blank=True, max_length=40)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={'ordering': ['-updated_at'], 'unique_together': {('employee_id', 'period')}},
        ),
    ]
