from django.contrib import admin
from .models import ClientVisit, VisitAttachment, VisitExpense


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
    list_display = ('visit_id', 'employee_user_id', 'client_name', 'scheduled_date', 'status')
    list_filter = ('status', 'scheduled_date')
    search_fields = ('visit_id', 'employee_user_id', 'client_name', 'contact_person')
    inlines = (VisitAttachmentInline, VisitExpenseInline)
