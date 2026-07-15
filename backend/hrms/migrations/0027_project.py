from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0026_recruitment_pipeline')]
    operations = [
        migrations.CreateModel(
            name='Project',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=160)),
                ('code', models.CharField(max_length=40, unique=True)),
                ('department', models.CharField(blank=True, max_length=120)),
                ('description', models.TextField(blank=True)),
                ('status', models.CharField(choices=[('not_started', 'Not Started'), ('in_progress', 'In Progress'), ('on_hold', 'On Hold'), ('at_risk', 'At Risk'), ('completed', 'Completed')], default='not_started', max_length=30)),
                ('start_date', models.DateField(blank=True, null=True)),
                ('end_date', models.DateField(blank=True, null=True)),
                ('budget', models.DecimalField(decimal_places=2, default=0, max_digits=14)),
                ('spent', models.DecimalField(decimal_places=2, default=0, max_digits=14)),
                ('progress', models.PositiveIntegerField(default=0)),
                ('manager_id', models.CharField(blank=True, max_length=40)),
                ('manager_name', models.CharField(blank=True, max_length=120)),
                ('manager_email', models.EmailField(blank=True, max_length=254)),
                ('team', models.JSONField(blank=True, default=list)),
                ('milestones', models.JSONField(blank=True, default=list)),
                ('progress_history', models.JSONField(blank=True, default=list)),
                ('created_by', models.CharField(blank=True, max_length=40)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={'ordering': ['-updated_at']},
        ),
    ]
