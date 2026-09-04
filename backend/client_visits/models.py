import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.db import transaction
from django.db.models import Q


class ClientVisit(models.Model):
    SERVICE_CHOICES = [
        ('web_app_development', 'Web App Development'),
        ('personal_branding', 'Personal Branding'),
        ('digital_marketing', 'Digital Marketing'),
        ('business_analytics', 'Business Analytics'),
        ('imagination_to_reality', 'Imagination to Reality'),
        (
            'real_time_sales_data_driven_solutions',
            'Real-Time Sales Data Driven Solutions',
        ),
    ]

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
    service_type = models.CharField(
        max_length=50,
        choices=SERVICE_CHOICES,
        blank=True,
        default='',
    )
    purpose = models.CharField(max_length=180)
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft', db_index=True)
    approval_comment = models.TextField(blank=True)
    approved_by = models.CharField(max_length=20, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    tl_approval_comment = models.TextField(blank=True)
    tl_approved_by = models.CharField(max_length=20, blank=True, db_index=True)
    tl_approved_at = models.DateTimeField(null=True, blank=True)
    office_check_out_at = models.DateTimeField(null=True, blank=True)
    office_check_out_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    office_check_out_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    start_odometer = models.DecimalField(max_digits=10, decimal_places=1, null=True, blank=True)
    reached_client_at = models.DateTimeField(null=True, blank=True)
    reached_client_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    reached_client_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    travel_route = models.JSONField(default=list, blank=True, db_default=[])
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


class ClientServiceDetails(models.Model):
    created_by_user_id = models.CharField(max_length=20, db_index=True)
    client_name = models.CharField(max_length=160)
    client_email = models.EmailField(max_length=254)
    client_mobile = models.CharField(max_length=20)
    client_details = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at', '-id']
        verbose_name = 'Client details'
        verbose_name_plural = 'Client details'

    def __str__(self):
        return f'{self.client_name} ({self.client_mobile})'


class VisitAttachment(models.Model):
    CATEGORY_CHOICES = [
        ('check_in', 'Check-in selfie (legacy)'),
        ('office_checkout', 'Office check-out selfie'),
        ('client_check_in', 'Client check-in selfie'),
        ('checkout', 'Return / checkout selfie'),
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


class ClientVisitTrackingLink(models.Model):
    """Revocable, time-limited public access to one visit's live position."""

    visit = models.ForeignKey(
        ClientVisit,
        on_delete=models.CASCADE,
        related_name='tracking_links',
    )
    token_hash = models.CharField(max_length=64, unique=True, db_index=True)
    created_by = models.CharField(max_length=20, blank=True)
    expires_at = models.DateTimeField(db_index=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class ClientVisitJourney(models.Model):
    class Status(models.TextChoices):
        SCHEDULED = 'SCHEDULED', 'Scheduled'
        READY = 'READY', 'Ready'
        IN_PROGRESS = 'IN_PROGRESS', 'In progress'
        PAUSED = 'PAUSED', 'Paused'
        COMPLETED = 'COMPLETED', 'Completed'
        CANCELLED = 'CANCELLED', 'Cancelled'

    ACTIVE_STATUSES = (Status.IN_PROGRESS, Status.PAUSED)
    VALID_TRANSITIONS = {
        Status.SCHEDULED: {Status.READY, Status.CANCELLED},
        Status.READY: {Status.IN_PROGRESS, Status.CANCELLED},
        Status.IN_PROGRESS: {Status.PAUSED, Status.COMPLETED, Status.CANCELLED},
        Status.PAUSED: {Status.IN_PROGRESS, Status.COMPLETED, Status.CANCELLED},
        Status.COMPLETED: set(),
        Status.CANCELLED: set(),
    }

    source_visit = models.OneToOneField(
        ClientVisit,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='live_journey',
    )
    employee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='client_visit_journeys',
    )
    assigned_team_lead = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='assigned_client_visit_journeys',
    )
    client_name = models.CharField(max_length=160)
    client_contact = models.CharField(max_length=120, blank=True)
    meeting_purpose = models.CharField(max_length=240)
    destination_address = models.TextField(blank=True)
    destination_latitude = models.DecimalField(
        max_digits=10, decimal_places=7,
        validators=[MinValueValidator(-90), MaxValueValidator(90)],
    )
    destination_longitude = models.DecimalField(
        max_digits=10, decimal_places=7,
        validators=[MinValueValidator(-180), MaxValueValidator(180)],
    )
    scheduled_at = models.DateTimeField(db_index=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.SCHEDULED,
        db_index=True,
    )
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancel_reason = models.TextField(blank=True)
    start_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    start_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    end_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    end_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    total_distance_metres = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    total_duration_seconds = models.PositiveBigIntegerField(default=0)
    moving_duration_seconds = models.PositiveBigIntegerField(default=0)
    stationary_duration_seconds = models.PositiveBigIntegerField(default=0)
    last_location_at = models.DateTimeField(null=True, blank=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-scheduled_at', '-id']
        indexes = [
            models.Index(fields=['status', 'last_location_at'], name='cvj_status_last_idx'),
            models.Index(fields=['assigned_team_lead', 'status'], name='cvj_tl_status_idx'),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['employee'],
                condition=Q(status__in=['IN_PROGRESS', 'PAUSED']),
                name='one_active_client_journey_per_employee',
            ),
            models.CheckConstraint(
                condition=Q(destination_latitude__gte=-90, destination_latitude__lte=90),
                name='cvj_destination_latitude_valid',
            ),
            models.CheckConstraint(
                condition=Q(destination_longitude__gte=-180, destination_longitude__lte=180),
                name='cvj_destination_longitude_valid',
            ),
        ]

    def can_transition_to(self, target):
        return target in self.VALID_TRANSITIONS.get(self.status, set())


class JourneyLocationPoint(models.Model):
    client_generated_id = models.UUIDField(default=uuid.uuid4, unique=True)
    journey = models.ForeignKey(
        ClientVisitJourney,
        on_delete=models.CASCADE,
        related_name='location_points',
    )
    employee = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name='journey_location_points',
    )
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    accuracy_metres = models.DecimalField(max_digits=8, decimal_places=2)
    altitude = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    speed_metres_per_second = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    heading = models.DecimalField(max_digits=7, decimal_places=2, null=True, blank=True)
    captured_at = models.DateTimeField()
    received_at = models.DateTimeField()
    sequence_number = models.PositiveBigIntegerField()
    is_mocked = models.BooleanField(null=True, blank=True)
    battery_percentage = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    is_low_accuracy = models.BooleanField(default=False)
    is_suspicious = models.BooleanField(default=False)
    suspicion_reason = models.CharField(max_length=240, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['captured_at', 'sequence_number', 'id']
        indexes = [
            models.Index(fields=['journey', 'captured_at'], name='jlp_journey_time_idx'),
            models.Index(fields=['journey', 'sequence_number'], name='jlp_journey_seq_idx'),
            models.Index(fields=['employee', 'captured_at'], name='jlp_employee_time_idx'),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['journey', 'sequence_number'],
                name='unique_journey_sequence_number',
            ),
            models.CheckConstraint(
                condition=Q(latitude__gte=-90, latitude__lte=90),
                name='jlp_latitude_valid',
            ),
            models.CheckConstraint(
                condition=Q(longitude__gte=-180, longitude__lte=180),
                name='jlp_longitude_valid',
            ),
            models.CheckConstraint(
                condition=Q(accuracy_metres__gte=0),
                name='jlp_accuracy_non_negative',
            ),
        ]


class JourneyStop(models.Model):
    journey = models.ForeignKey(
        ClientVisitJourney,
        on_delete=models.CASCADE,
        related_name='stops',
    )
    started_at = models.DateTimeField()
    ended_at = models.DateTimeField()
    duration_seconds = models.PositiveBigIntegerField()
    latitude = models.DecimalField(max_digits=10, decimal_places=7)
    longitude = models.DecimalField(max_digits=10, decimal_places=7)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['started_at']
        indexes = [models.Index(fields=['journey', 'started_at'], name='jstop_journey_time_idx')]
