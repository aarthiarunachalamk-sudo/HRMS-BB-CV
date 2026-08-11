from datetime import datetime, timedelta, timezone as datetime_timezone
import logging

from django.core.management.base import BaseCommand
from django.utils import timezone

from client_visits.models import ClientVisit
from hrms.models import AppNotification
from hrms.push_notifications import send_mobile_push


logger = logging.getLogger(__name__)
IST = datetime_timezone(timedelta(hours=5, minutes=30))
REMINDER_WINDOW_MINUTES = 12
REMINDERS = (
    (120, 'Client Visit in 2 Hours'),
    (60, 'Start to Visit in 1 Hour'),
)


def send_client_visit_reminders(now=None):
    """Create each visit reminder once and attempt its native push."""
    local_now = (now or timezone.now()).astimezone(IST)
    last_relevant_date = (local_now + timedelta(hours=2)).date()
    visits = ClientVisit.objects.filter(
        status='approved',
        scheduled_date__gte=local_now.date(),
        scheduled_date__lte=last_relevant_date,
    ).only(
        'id',
        'visit_id',
        'employee_user_id',
        'client_name',
        'scheduled_date',
        'scheduled_time',
    )

    created_count = 0
    for visit in visits:
        scheduled_at = datetime.combine(
            visit.scheduled_date,
            visit.scheduled_time,
            tzinfo=IST,
        )
        minutes_until_visit = (scheduled_at - local_now).total_seconds() / 60
        for offset_minutes, title in REMINDERS:
            if not (
                offset_minutes - REMINDER_WINDOW_MINUTES
                < minutes_until_visit
                <= offset_minutes
            ):
                continue
            notification, created = AppNotification.objects.get_or_create(
                recipient_user_id=visit.employee_user_id,
                module='client_visit',
                reference_id=f'{visit.id}:reminder:{offset_minutes}',
                defaults={
                    'title': title,
                    'message': (
                        f'{visit.visit_id} at {visit.client_name} is scheduled '
                        f'for {scheduled_at:%d-%m-%Y %I:%M %p}. '
                        + (
                            'Start to Visit is now available.'
                            if offset_minutes == 60
                            else 'Please be ready for the visit.'
                        )
                    ),
                    'notification_type': 'warning',
                },
            )
            if not created:
                continue
            created_count += 1
            try:
                notification.push_sent = send_mobile_push(notification)
                if notification.push_sent:
                    notification.save(update_fields=['push_sent'])
            except Exception:
                logger.exception(
                    'Unable to send reminder push for client visit %s',
                    visit.pk,
                )
    return created_count


class Command(BaseCommand):
    help = 'Send assigned employees client-visit reminders two hours and one hour before.'

    def handle(self, *args, **options):
        created = send_client_visit_reminders()
        self.stdout.write(
            self.style.SUCCESS(f'Created {created} client visit reminder(s).')
        )
