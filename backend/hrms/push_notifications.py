import json
import os

from django.db.models import Q


def _recipient_user_ids(user_id):
    """Return every login/employee alias that can own the same mobile device."""
    normalized = str(user_id or '').strip()
    if not normalized:
        return set()

    from .models import EmployeeAccount, User

    aliases = {normalized}
    users = User.objects.filter(Q(user_id=normalized) | Q(email__iexact=normalized))
    aliases.update(users.values_list('user_id', flat=True))
    emails = set(users.exclude(email='').values_list('email', flat=True))
    aliases.update(emails)

    accounts = EmployeeAccount.objects.select_related('user').filter(
        Q(employee_id=normalized)
        | Q(employee_email__iexact=normalized)
        | Q(user__user_id=normalized)
        | Q(user__email__iexact=normalized)
    )
    if emails:
        accounts = accounts | EmployeeAccount.objects.select_related('user').filter(
            employee_email__in=emails
        )
    for account in accounts:
        aliases.add(account.employee_id)
        if account.employee_email:
            aliases.add(account.employee_email)
        if account.user_id:
            aliases.add(account.user.user_id)
            if account.user.email:
                aliases.add(account.user.email)
    aliases.discard('')
    return aliases


def _firebase_app():
    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError:
        return None

    if firebase_admin._apps:
        return firebase_admin.get_app()
    raw_credentials = os.getenv('FIREBASE_SERVICE_ACCOUNT_JSON', '').strip()
    try:
        if raw_credentials:
            credential = credentials.Certificate(json.loads(raw_credentials))
            return firebase_admin.initialize_app(credential)
        if os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
            return firebase_admin.initialize_app()
    except (ValueError, OSError):
        return None
    return None


def send_mobile_push(notification):
    app = _firebase_app()
    if app is None:
        return False

    from firebase_admin import messaging
    from .models import MobileDeviceToken

    targets = Q(is_active=True)
    if notification.recipient_user_id:
        targets &= Q(user_id__in=_recipient_user_ids(notification.recipient_user_id))
    elif notification.recipient_role:
        targets &= Q(role=notification.recipient_role)
    else:
        return False
    devices = list(MobileDeviceToken.objects.filter(targets))
    if not devices:
        return False

    message = messaging.MulticastMessage(
        tokens=[device.token for device in devices],
        notification=messaging.Notification(
            title=notification.title,
            body=notification.message,
        ),
        data={
            'module': notification.module or '',
            'reference_id': notification.reference_id or '',
            'notification_id': str(notification.id),
            'notification_type': notification.notification_type or 'info',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='hrms_updates',
                sound='default',
                tag=f'hrms-{notification.module or "general"}-{notification.id}',
            ),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound='default'),
            ),
        ),
    )
    try:
        response = messaging.send_each_for_multicast(message, app=app)
    except Exception:
        return False

    invalid_ids = [
        devices[index].id
        for index, result in enumerate(response.responses)
        if not result.success and result.exception is not None and any(
            marker in str(result.exception).lower()
            for marker in ('unregistered', 'registration-token-not-registered')
        )
    ]
    if invalid_ids:
        MobileDeviceToken.objects.filter(id__in=invalid_ids).update(is_active=False)
    return response.success_count > 0
