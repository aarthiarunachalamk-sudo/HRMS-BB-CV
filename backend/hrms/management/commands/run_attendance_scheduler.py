import time

from django.core.management.base import BaseCommand
from django.db import close_old_connections

from hrms.management.commands.auto_checkout_attendance import run_auto_checkout
from hrms.management.commands.send_checkin_reminders import send_checkin_reminders


def run_scheduled_attendance_tasks():
    close_old_connections()
    checked_out = run_auto_checkout()
    reminders = send_checkin_reminders()
    close_old_connections()
    return checked_out, reminders


class Command(BaseCommand):
    help = 'Continuously run attendance auto-checkout and check-in reminders.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--once',
            action='store_true',
            help='Run one scheduler cycle and exit.',
        )
        parser.add_argument(
            '--interval',
            type=int,
            default=60,
            help='Seconds between scheduler cycles (default: 60).',
        )

    def handle(self, *args, **options):
        interval = max(int(options['interval']), 15)
        while True:
            try:
                checked_out, reminders = run_scheduled_attendance_tasks()
                if checked_out or reminders:
                    self.stdout.write(self.style.SUCCESS(
                        f'Auto-checked out {checked_out}; sent {reminders} reminder(s).'
                    ))
            except Exception as error:
                close_old_connections()
                self.stderr.write(self.style.ERROR(
                    f'Attendance scheduler cycle failed: {error}'
                ))
            if options['once']:
                break
            time.sleep(interval)
