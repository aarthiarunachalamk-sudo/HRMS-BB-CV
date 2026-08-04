from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [('client_visits', '0001_initial')]
    operations = [
        migrations.AlterField(
            model_name='clientvisit', name='status',
            field=models.CharField(
                choices=[('draft','Draft'),('pending','Pending approval'),('approved','Approved'),('travelling','Travelling'),('in_progress','In progress'),('completed','Completed'),('rejected','Rejected')],
                db_index=True, default='draft', max_length=20,
            ),
        ),
        migrations.AddField(model_name='clientvisit', name='office_check_out_at', field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name='clientvisit', name='office_check_out_latitude', field=models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
        migrations.AddField(model_name='clientvisit', name='office_check_out_longitude', field=models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
        migrations.AddField(model_name='clientvisit', name='start_odometer', field=models.DecimalField(blank=True, decimal_places=1, max_digits=10, null=True)),
        migrations.AddField(model_name='clientvisit', name='reached_client_at', field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name='clientvisit', name='attendees', field=models.JSONField(blank=True, default=list)),
        migrations.AddField(model_name='clientvisit', name='checklist', field=models.JSONField(blank=True, default=list)),
        migrations.AddField(model_name='clientvisit', name='return_mode', field=models.CharField(blank=True, max_length=24)),
        migrations.AddField(model_name='clientvisit', name='manager_verified_by', field=models.CharField(blank=True, max_length=20)),
        migrations.AddField(model_name='clientvisit', name='manager_verified_at', field=models.DateTimeField(blank=True, null=True)),
    ]
