from rest_framework.permissions import BasePermission


MANAGEMENT_ROLES = {'hr', 'admin', 'superadmin', 'ceo', 'md', 'director'}


def can_view_journey(user, journey):
    if not user or not user.is_authenticated or not user.is_active:
        return False
    return (
        journey.employee_id == user.id
        or journey.assigned_team_lead_id == user.id
        or user.role in MANAGEMENT_ROLES
    )


class CanAccessJourney(BasePermission):
    def has_object_permission(self, request, view, obj):
        return can_view_journey(request.user, obj)
