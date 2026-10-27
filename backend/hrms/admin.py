from django.contrib import admin
from .models import AccountDeletionRequest, EmployeeAccount, MobileDeviceToken


@admin.register(AccountDeletionRequest)
class AccountDeletionRequestAdmin(admin.ModelAdmin):
    list_display = (
        'request_id',
        'user_id_code',
        'employee_id',
        'employee_name',
        'email',
        'status',
        'requested_at',
        'reviewed_by',
    )
    list_filter = ('status', 'requested_at', 'reason')
    search_fields = ('request_id', 'user_id_code', 'employee_id', 'employee_name', 'email')
    readonly_fields = ('request_id', 'requested_at', 'updated_at')
    actions = ['mark_under_review', 'mark_approved', 'mark_rejected', 'mark_completed']

    @admin.action(description='Mark selected requests as UNDER_REVIEW')
    def mark_under_review(self, request, queryset):
        queryset.update(status='UNDER_REVIEW', reviewed_by=request.user)

    @admin.action(description='Mark selected requests as APPROVED')
    def mark_approved(self, request, queryset):
        queryset.update(status='APPROVED', reviewed_by=request.user)

    @admin.action(description='Mark selected requests as REJECTED')
    def mark_rejected(self, request, queryset):
        queryset.update(status='REJECTED', reviewed_by=request.user)

    @admin.action(description='Mark selected requests as COMPLETED (Deactivate login)')
    def mark_completed(self, request, queryset):
        for req in queryset:
            req.status = 'COMPLETED'
            req.reviewed_by = request.user
            req.save()
            if req.user:
                req.user.is_active = False
                req.user.save(update_fields=['is_active'])
                EmployeeAccount.objects.filter(user=req.user).update(is_active=False)
                MobileDeviceToken.objects.filter(user_id=req.user.user_id).delete()
