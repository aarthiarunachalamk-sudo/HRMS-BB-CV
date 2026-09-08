from django.db.models.signals import post_save
from django.dispatch import receiver

from .leadership_employees import EMPLOYEE_ENABLED_ROLES, ensure_leadership_employee_account
from .models import User


@receiver(post_save, sender=User)
def provision_leadership_employee(sender, instance, **kwargs):
    if instance.role in EMPLOYEE_ENABLED_ROLES:
        ensure_leadership_employee_account(instance)
