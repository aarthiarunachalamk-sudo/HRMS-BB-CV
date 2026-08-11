from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db.models import Q
from django.utils import timezone

from client_visits.models import ClientVisitJourney


class Command(BaseCommand):
    help = 'Delete terminal client journeys older than the configured retention period.'

    def add_arguments(self, parser):
        parser.add_argument('--days', type=int, default=settings.CLIENT_JOURNEY_RETENTION_DAYS)
        parser.add_argument('--dry-run', action='store_true')

    def handle(self, *args, **options):
        days = options['days']
        if days < 1:
            raise ValueError('Retention days must be at least 1.')
        cutoff = timezone.now() - timedelta(days=days)
        queryset = ClientVisitJourney.objects.filter(
            Q(completed_at__lt=cutoff) | Q(cancelled_at__lt=cutoff),
        )
        journey_count = queryset.count()
        point_count = queryset.filter(location_points__isnull=False).values(
            'location_points__id',
        ).count()
        if options['dry_run']:
            self.stdout.write(
                f'Would delete {journey_count} journeys and {point_count} location points.',
            )
            return
        deleted, _ = queryset.delete()
        self.stdout.write(self.style.SUCCESS(f'Deleted {deleted} retained records.'))
