from django.apps import AppConfig


class HrmsConfig(AppConfig):
    name = 'hrms'

    def ready(self):
        # Register additive employee-account provisioning for leadership users.
        from . import signals  # noqa: F401
