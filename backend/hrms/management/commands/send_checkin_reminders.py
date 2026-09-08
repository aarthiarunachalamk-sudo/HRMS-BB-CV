from datetime import timedelta, timezone as datetime_timezone

from django.core.management.base import BaseCommand
from django.utils import timezone

from hrms.models import (
    AppNotification,
    EmployeeAccount,
    EmployeeAttendanceRecord,
)
from hrms.push_notifications import send_mobile_push


IST = datetime_timezone(timedelta(hours=5, minutes=30))
def send_checkin_reminders(now=None):
    local_now = (now or timezone.now()).astimezone(IST)
    # Hosted schedulers can start a few minutes late. Map each invocation to
    # its preceding ten-minute reminder slot and deduplicate it in the DB.
    if local_now.hour != 9 or local_now.minute >= 40:
        return 0

    slot_minute = min((local_now.minute // 10) * 10, 30)
    reminder_time = local_now.replace(
        minute=slot_minute,
        second=0,
        microsecond=0,
    )

    today = local_now.date()
    checked_in = set(
        EmployeeAttendanceRecord.objects.filter(
            attendance_date=today,
            check_in__isnull=False,
        ).values_list('employee_id', flat=True)
    )
    employee_ids = EmployeeAccount.objects.filter(is_active=True).values_list(
        'employee_id',
        flat=True,
    )
    reminder_key = f'{today.isoformat()}-{reminder_time:%H%M}'
    sent = 0
    for employee_id in employee_ids:
        if employee_id in checked_in:
            continue
        notification, created = AppNotification.objects.get_or_create(
            recipient_user_id=employee_id,
            module='attendance_checkin_reminder',
            reference_id=reminder_key,
            defaults={
                'title': 'Check-In Reminder',
                'message': (
                    'Please complete your HRMS attendance check-in now. '
                    'Check-in reminders continue until 9:30 AM.'
                ),
                'notification_type': 'warning',
            },
        )
        if not created:
            continue
        notification.push_sent = send_mobile_push(notification)
        if notification.push_sent:
            notification.save(update_fields=['push_sent'])
            sent += 1
    return sent


class Command(BaseCommand):
    help = 'Send native mobile check-in reminders at 9:00, 9:10, 9:20, and 9:30 AM IST.'

    def handle(self, *args, **options):
        sent = send_checkin_reminders()
        self.stdout.write(self.style.SUCCESS(f'Sent {sent} check-in reminder(s).'))
