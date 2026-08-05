from django.db import migrations


def backfill_tl_approval_notifications(apps, schema_editor):
    ClientVisit = apps.get_model('client_visits', 'ClientVisit')
    AppNotification = apps.get_model('hrms', 'AppNotification')
    User = apps.get_model('hrms', 'User')

    visits = ClientVisit.objects.exclude(approved_by='').exclude(
        status__in=['draft', 'pending'],
    )
    requester_ids = set(visits.values_list('employee_user_id', flat=True))
    requester_roles = dict(
        User.objects.filter(user_id__in=requester_ids).values_list(
            'user_id', 'role',
        ),
    )
    approver_ids = set(visits.values_list('approved_by', flat=True))
    approver_roles = dict(
        User.objects.filter(user_id__in=approver_ids).values_list(
            'user_id', 'role',
        ),
    )
    role_labels = {
        'hr': 'HR', 'ceo': 'CEO', 'tl': 'TL', 'manager': 'Manager',
        'admin': 'Admin', 'superadmin': 'Super Admin',
    }

    for visit in visits.iterator():
        if requester_roles.get(visit.employee_user_id) != 'tl':
            continue
        reference_id = str(visit.id)
        if AppNotification.objects.filter(
            recipient_user_id=visit.employee_user_id,
            module='client_visit',
            reference_id=reference_id,
        ).exists():
            continue
        approver_label = role_labels.get(
            approver_roles.get(visit.approved_by, ''),
            'Approver',
        )
        approved = visit.status != 'rejected'
        AppNotification.objects.create(
            recipient_user_id=visit.employee_user_id,
            title=(
                f'{approver_label} Approved Client Visit'
                if approved
                else f'{approver_label} Requested Client Visit Changes'
            ),
            message=(
                f'{visit.visit_id} for {visit.client_name}: '
                f'{"Visit approved" if approved else "Visit returned for changes"} '
                f'by {approver_label}. {visit.approval_comment}'
            ).strip(),
            notification_type='success' if approved else 'warning',
            module='client_visit',
            reference_id=reference_id,
        )


class Migration(migrations.Migration):
    dependencies = [
        ('client_visits', '0005_client_visit_gps_route_and_selfie_categories'),
        ('hrms', '0012_appnotification_mobiledevicetoken'),
    ]

    operations = [
        migrations.RunPython(
            backfill_tl_approval_notifications,
            migrations.RunPython.noop,
        ),
    ]
