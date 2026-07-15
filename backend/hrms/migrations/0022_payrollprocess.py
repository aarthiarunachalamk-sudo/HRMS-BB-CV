from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0021_user_created_by'),
    ]

    operations = [
        migrations.CreateModel(
            name='PayrollProcess',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('year', models.PositiveIntegerField()),
                ('month', models.PositiveIntegerField()),
                ('status', models.CharField(choices=[('inputs', 'Inputs'), ('validation', 'Validation'), ('calculation', 'Calculation'), ('approval', 'Approval'), ('published', 'Published')], default='inputs', max_length=20)),
                ('resolved_issues', models.JSONField(blank=True, default=list)),
                ('publishing_options', models.JSONField(blank=True, default=dict)),
                ('prepared_by', models.CharField(blank=True, max_length=80)),
                ('validated_at', models.DateTimeField(blank=True, null=True)),
                ('calculated_at', models.DateTimeField(blank=True, null=True)),
                ('approved_at', models.DateTimeField(blank=True, null=True)),
                ('published_at', models.DateTimeField(blank=True, null=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'ordering': ['-year', '-month'],
                'unique_together': {('year', 'month')},
            },
        ),
    ]
