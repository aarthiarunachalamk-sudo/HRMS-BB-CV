from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('hrms', '0013_employee_document_review_state'),
    ]

    operations = [
        migrations.CreateModel(
            name='TeamTask',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=160)),
                ('project', models.CharField(blank=True, max_length=120)),
                ('assignee_id', models.CharField(blank=True, db_index=True, max_length=20)),
                ('assignee_name', models.CharField(blank=True, max_length=120)),
                ('assignee_email', models.EmailField(blank=True, max_length=254)),
                ('priority', models.CharField(choices=[('Low', 'Low'), ('Medium', 'Medium'), ('High', 'High'), ('Urgent', 'Urgent')], default='Medium', max_length=20)),
                ('due_date', models.CharField(blank=True, max_length=40)),
                ('description', models.TextField(blank=True)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('in_progress', 'In Progress'), ('completed', 'Completed')], default='pending', max_length=20)),
                ('created_by', models.CharField(blank=True, max_length=80)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
