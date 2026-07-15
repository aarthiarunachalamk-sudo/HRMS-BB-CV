from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('hrms', '0028_employeeperformance')]
    operations = [migrations.CreateModel(name='ReportSchedule', fields=[
        ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
        ('owner_user_id', models.CharField(db_index=True, max_length=40)),
        ('report_type', models.CharField(max_length=80)), ('filters', models.JSONField(blank=True, default=dict)),
        ('format', models.CharField(default='pdf', max_length=10)), ('frequency', models.CharField(default='once', max_length=30)),
        ('recipients', models.JSONField(blank=True, default=list)), ('is_active', models.BooleanField(default=True)),
        ('last_generated_at', models.DateTimeField(blank=True, null=True)), ('created_at', models.DateTimeField(auto_now_add=True)),
    ], options={'ordering':['-created_at']})]
