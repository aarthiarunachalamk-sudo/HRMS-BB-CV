from django.apps import apps
from django.core.management.base import BaseCommand, CommandError
from django.db import models, transaction
from django.db.models import Q


class Command(BaseCommand):
    help = 'Remove records explicitly marked as HRMS dummy/test seed data.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Actually delete matching data. Without this flag only counts are shown.',
        )

    def handle(self, *args, **options):
        confirmed = options['confirm']
        matches = []

        for model in apps.get_app_config('hrms').get_models():
            query = Q()
            has_query = False
            for field in model._meta.concrete_fields:
                if isinstance(field, (models.CharField, models.TextField, models.EmailField)):
                    query |= Q(**{f'{field.name}__icontains': 'dummy'})
                    has_query = True
                    if isinstance(field, models.EmailField):
                        query |= Q(**{f'{field.name}__iendswith': '@bitbyte.test'})
            if not has_query:
                continue
            count = model.objects.filter(query).count()
            if count:
                matches.append((model, query, count))
                self.stdout.write(f'{model.__name__}: {count}')

        total = sum(count for _model, _query, count in matches)
        if not total:
            self.stdout.write(self.style.SUCCESS('No explicit dummy/test records found.'))
            return
        if not confirmed:
            self.stdout.write(
                self.style.WARNING(
                    f'Dry run only: {total} direct record(s) matched. '
                    'Run again with --confirm to delete them.',
                )
            )
            return

        try:
            with transaction.atomic():
                deleted_total = 0
                for model, query, _count in reversed(matches):
                    deleted, _details = model.objects.filter(query).delete()
                    deleted_total += deleted
        except Exception as error:
            raise CommandError(f'Dummy-data cleanup failed: {error}') from error

        self.stdout.write(
            self.style.SUCCESS(
                f'Removed {deleted_total} dummy/test record(s), including cascades.',
            )
        )
