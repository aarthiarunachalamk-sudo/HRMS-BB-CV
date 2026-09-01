from django.contrib import admin
from .models import (
    ClientVisit, ClientVisitJourney, JourneyLocationPoint, JourneyStop,
    VisitAttachment, VisitExpense,
)


class VisitAttachmentInline(admin.TabularInline):
    model = VisitAttachment
    extra = 0
    readonly_fields = (
        'cloudinary_url', 'cloudinary_public_id', 'cloudinary_cloud_name',
        'storage_provider', 'created_at',
    )


class VisitExpenseInline(admin.TabularInline):
    model = VisitExpense
    extra = 0


@admin.register(ClientVisit)
class ClientVisitAdmin(admin.ModelAdmin):
    list_display = (
        'visit_id',
        'employee_user_id',
        'client_name',
        'service_type',
        'scheduled_date',
        'status',
    )
    list_filter = ('status', 'scheduled_date')
    search_fields = (
        'visit_id',
        'employee_user_id',
        'client_name',
        'contact_person',
        'service_type',
    )
    inlines = (VisitAttachmentInline, VisitExpenseInline)


@admin.register(ClientVisitJourney)
class ClientVisitJourneyAdmin(admin.ModelAdmin):
    list_display = ('id', 'employee', 'assigned_team_lead', 'client_name', 'status', 'last_location_at')
    list_filter = ('status', 'scheduled_at')
    search_fields = ('client_name', 'employee__user_id', 'assigned_team_lead__user_id')
    readonly_fields = ('started_at', 'completed_at', 'cancelled_at', 'last_location_at')


@admin.register(JourneyLocationPoint)
class JourneyLocationPointAdmin(admin.ModelAdmin):
    list_display = ('client_generated_id', 'journey', 'employee', 'captured_at', 'accuracy_metres', 'is_suspicious')
    list_filter = ('is_low_accuracy', 'is_suspicious', 'is_mocked')
    search_fields = ('client_generated_id', 'employee__user_id')


admin.site.register(JourneyStop)
