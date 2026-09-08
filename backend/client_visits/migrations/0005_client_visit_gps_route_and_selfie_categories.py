from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0004_client_visit_backward_compatible_defaults'),
    ]

    operations = [
        migrations.AddField(
            model_name='clientvisit',
            name='reached_client_latitude',
            field=models.DecimalField(
                blank=True, decimal_places=7, max_digits=10, null=True,
            ),
        ),
        migrations.AddField(
            model_name='clientvisit',
            name='reached_client_longitude',
            field=models.DecimalField(
                blank=True, decimal_places=7, max_digits=10, null=True,
            ),
        ),
        migrations.AddField(
            model_name='clientvisit',
            name='travel_route',
            field=models.JSONField(blank=True, db_default=[], default=list),
        ),
        migrations.AlterField(
            model_name='visitattachment',
            name='category',
            field=models.CharField(
                choices=[
                    ('check_in', 'Check-in selfie (legacy)'),
                    ('office_checkout', 'Office check-out selfie'),
                    ('client_check_in', 'Client check-in selfie'),
                    ('checkout', 'Return / checkout selfie'),
                    ('proof', 'Visit proof'),
                    ('document', 'Document'),
                    ('signature', 'Client signature'),
                    ('expense', 'Expense receipt'),
                ],
                max_length=20,
            ),
        ),
    ]
