from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    initial = True
    dependencies = []
    operations = [
        migrations.CreateModel(name='ClientVisit', fields=[
            ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ('visit_id', models.CharField(blank=True, max_length=24, unique=True)),
            ('employee_user_id', models.CharField(db_index=True, max_length=20)),
            ('employee_name', models.CharField(blank=True, max_length=120)),
            ('manager_user_id', models.CharField(blank=True, db_index=True, max_length=20)),
            ('client_name', models.CharField(max_length=160)), ('contact_person', models.CharField(max_length=120)),
            ('contact_phone', models.CharField(blank=True, max_length=24)), ('address', models.TextField()),
            ('latitude', models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
            ('longitude', models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
            ('scheduled_date', models.DateField()), ('scheduled_time', models.TimeField()),
            ('duration_minutes', models.PositiveIntegerField(default=60)), ('travel_mode', models.CharField(default='car', max_length=30)),
            ('purpose', models.CharField(max_length=180)), ('notes', models.TextField(blank=True)),
            ('status', models.CharField(choices=[('draft','Draft'),('pending','Pending approval'),('approved','Approved'),('in_progress','In progress'),('completed','Completed'),('rejected','Rejected')], db_index=True, default='draft', max_length=20)),
            ('approval_comment', models.TextField(blank=True)), ('approved_by', models.CharField(blank=True, max_length=20)),
            ('approved_at', models.DateTimeField(blank=True, null=True)), ('check_in_at', models.DateTimeField(blank=True, null=True)),
            ('check_in_latitude', models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
            ('check_in_longitude', models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
            ('check_out_at', models.DateTimeField(blank=True, null=True)),
            ('check_out_latitude', models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
            ('check_out_longitude', models.DecimalField(blank=True, decimal_places=7, max_digits=10, null=True)),
            ('outcome', models.TextField(blank=True)), ('follow_up', models.TextField(blank=True)),
            ('client_signature_name', models.CharField(blank=True, max_length=120)),
            ('created_at', models.DateTimeField(auto_now_add=True)), ('updated_at', models.DateTimeField(auto_now=True)),
        ], options={'ordering': ['-scheduled_date', '-scheduled_time']}),
        migrations.CreateModel(name='VisitExpense', fields=[
            ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ('category', models.CharField(choices=[('travel','Travel'),('food','Food'),('parking','Parking / Toll'),('other','Other')], max_length=20)),
            ('amount', models.DecimalField(decimal_places=2, max_digits=12)), ('note', models.CharField(blank=True, max_length=240)),
            ('created_at', models.DateTimeField(auto_now_add=True)),
            ('visit', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='expenses', to='client_visits.clientvisit')),
        ]),
        migrations.CreateModel(name='VisitAttachment', fields=[
            ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
            ('category', models.CharField(choices=[('check_in','Check-in selfie'),('proof','Visit proof'),('document','Document'),('signature','Client signature'),('expense','Expense receipt')], max_length=20)),
            ('cloudinary_url', models.URLField(max_length=600)), ('cloudinary_public_id', models.CharField(max_length=300)),
            ('resource_type', models.CharField(default='image', max_length=20)), ('original_name', models.CharField(blank=True, max_length=255)),
            ('uploaded_by', models.CharField(max_length=20)), ('created_at', models.DateTimeField(auto_now_add=True)),
            ('visit', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='attachments', to='client_visits.clientvisit')),
        ], options={'ordering': ['created_at']}),
    ]
