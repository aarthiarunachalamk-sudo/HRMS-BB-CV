from datetime import datetime, time, timedelta, timezone as datetime_timezone

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from hrms.employee_views import _attendance_calculation, _notify_employee_presence
from hrms.models import AuditLog, EmployeeAttendanceRecord, EmployeeLeaveRequest
from hrms.management.commands.send_checkin_reminders import send_checkin_reminders


IST = datetime_timezone(timedelta(hours=5, minutes=30))


def run_auto_checkout(now=None):
    local_now = (now or timezone.now()).astimezone(IST)
    today = local_now.date()
    updated = 0
    record_ids = EmployeeAttendanceRecord.objects.filter(
        attendance_date=today,
        check_in__isnull=False,
        check_out__isnull=True,
    ).values_list('pk', flat=True)
    for record_id in record_ids:
        with transaction.atomic():
            record = EmployeeAttendanceRecord.objects.select_for_update().get(pk=record_id)
            if record.check_out is not None:
                continue
            leave = EmployeeLeaveRequest.objects.filter(
                employee_id=record.employee_id,
                status='approved',
                hr_status='approved',
                session='Second Half',
                from_date__lte=today,
                to_date__gte=today,
            ).first()
            checkout_time = time(13, 0) if leave else time(18, 30)
            scheduled_local = datetime.combine(today, checkout_time, tzinfo=IST)
            if local_now < scheduled_local:
                continue
            checkout = scheduled_local.astimezone(datetime_timezone.utc)
            calc = _attendance_calculation(record.check_in, checkout, 330)
            record.check_out = checkout
            record.checkout_source = 'system_auto'
            record.is_auto_checkout = True
            record.check_out_timezone_offset_minutes = 330
            record.working_hours = calc['working_hours']
            record.status = 'Half Day' if leave else calc['status']
            record.save(update_fields=[
                'check_out', 'checkout_source', 'is_auto_checkout',
                'check_out_timezone_offset_minutes', 'working_hours',
                'status', 'updated_at',
            ])
            AuditLog.objects.create(
                actor_role='system',
                action='automatic_checkout',
                module='attendance',
                reference_id=str(record.pk),
                before={'check_out': None},
                after={
                    'check_out': checkout.isoformat(),
                    'checkout_source': 'system_auto',
                    'is_auto_checkout': True,
                },
            )
            _notify_employee_presence(record, 'check_out')
            updated += 1
    return updated


class Command(BaseCommand):
    help = 'Auto-check out open attendance at 1:00 PM for approved second-half leave or 6:30 PM normally.'

    def handle(self, *args, **options):
        updated = run_auto_checkout()
        reminders = send_checkin_reminders()
        self.stdout.write(self.style.SUCCESS(
            f'Auto-checked out {updated} record(s); sent {reminders} check-in reminder(s).'
        ))
