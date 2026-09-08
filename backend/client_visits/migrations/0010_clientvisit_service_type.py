from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0009_clientvisit_tl_approval'),
    ]

    operations = [
        migrations.AddField(
            model_name='clientvisit',
            name='service_type',
            field=models.CharField(
                blank=True,
                choices=[
                    ('web_app_development', 'Web App Development'),
                    ('personal_branding', 'Personal Branding'),
                    ('digital_marketing', 'Digital Marketing'),
                    ('business_analytics', 'Business Analytics'),
                    ('imagination_to_reality', 'Imagination to Reality'),
                    (
                        'real_time_sales_data_driven_solutions',
                        'Real-Time Sales Data Driven Solutions',
                    ),
                ],
                default='',
                max_length=50,
            ),
        ),
    ]
