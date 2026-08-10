from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0006_backfill_tl_visit_approval_notifications'),
    ]

    operations = [
        migrations.CreateModel(
            name='ClientVisitTrackingLink',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('token_hash', models.CharField(db_index=True, max_length=64, unique=True)),
                ('created_by', models.CharField(blank=True, max_length=20)),
                ('expires_at', models.DateTimeField(db_index=True)),
                ('revoked_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('visit', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='tracking_links', to='client_visits.clientvisit')),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
