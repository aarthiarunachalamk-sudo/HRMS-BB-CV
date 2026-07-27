import json
import os

from django.db.models import Q


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
        targets &= Q(user_id=notification.recipient_user_id)
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
        },
        android=messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                channel_id='attendance_reminders',
                sound='default',
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
