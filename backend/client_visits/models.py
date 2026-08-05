from django.db import models
from django.db import transaction


class ClientVisit(models.Model):
    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending', 'Pending approval'),
        ('approved', 'Approved'),
        ('travelling', 'Travelling'),
        ('in_progress', 'In progress'),
        ('completed', 'Completed'),
        ('rejected', 'Rejected'),
    ]

    visit_id = models.CharField(max_length=24, unique=True, blank=True)
    employee_user_id = models.CharField(max_length=20, db_index=True)
    employee_name = models.CharField(max_length=120, blank=True)
    manager_user_id = models.CharField(max_length=20, blank=True, db_index=True)
    client_name = models.CharField(max_length=160)
    contact_person = models.CharField(max_length=120)
    contact_phone = models.CharField(max_length=24, blank=True)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    scheduled_date = models.DateField()
    scheduled_time = models.TimeField()
    duration_minutes = models.PositiveIntegerField(default=60)
    travel_mode = models.CharField(max_length=30, default='car')
    purpose = models.CharField(max_length=180)
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft', db_index=True)
    approval_comment = models.TextField(blank=True)
    approved_by = models.CharField(max_length=20, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    office_check_out_at = models.DateTimeField(null=True, blank=True)
    office_check_out_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    office_check_out_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    start_odometer = models.DecimalField(max_digits=10, decimal_places=1, null=True, blank=True)
    reached_client_at = models.DateTimeField(null=True, blank=True)
    check_in_at = models.DateTimeField(null=True, blank=True)
    check_in_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_in_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_out_at = models.DateTimeField(null=True, blank=True)
    check_out_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_out_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    outcome = models.TextField(blank=True)
    follow_up = models.TextField(blank=True)
    attendees = models.JSONField(default=list, blank=True, db_default=[])
    checklist = models.JSONField(default=list, blank=True, db_default=[])
    return_mode = models.CharField(max_length=24, blank=True, db_default='')
    client_signature_name = models.CharField(max_length=120, blank=True)
    manager_verified_by = models.CharField(
        max_length=20,
        blank=True,
        db_default='',
    )
    manager_verified_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-scheduled_date', '-scheduled_time']

    def save(self, *args, **kwargs):
        if not self.visit_id:
            with transaction.atomic():
                super().save(*args, **kwargs)
                self.visit_id = f'VST-{self.created_at.year}-{self.pk:05d}'
                super().save(update_fields=['visit_id'])
            return None
        return super().save(*args, **kwargs)


class VisitAttachment(models.Model):
    CATEGORY_CHOICES = [
        ('check_in', 'Check-in selfie'),
        ('proof', 'Visit proof'),
        ('document', 'Document'),
        ('signature', 'Client signature'),
        ('expense', 'Expense receipt'),
    ]
    visit = models.ForeignKey(ClientVisit, on_delete=models.CASCADE, related_name='attachments')
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    cloudinary_url = models.URLField(max_length=600)
    cloudinary_public_id = models.CharField(max_length=300)
    cloudinary_cloud_name = models.CharField(max_length=120)
    storage_provider = models.CharField(max_length=30, default='cloudinary_client_visits')
    resource_type = models.CharField(max_length=20, default='image')
    original_name = models.CharField(max_length=255, blank=True)
    uploaded_by = models.CharField(max_length=20)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']


class VisitExpense(models.Model):
    CATEGORY_CHOICES = [
        ('travel', 'Travel'), ('food', 'Food'), ('parking', 'Parking / Toll'),
        ('other', 'Other'),
    ]
    visit = models.ForeignKey(ClientVisit, on_delete=models.CASCADE, related_name='expenses')
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    note = models.CharField(max_length=240, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
