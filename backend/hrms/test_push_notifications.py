from django.test import TestCase

from .models import User
from .push_notifications import _recipient_user_ids


class PushNotificationRecipientTests(TestCase):
    def setUp(self):
        self.employee = User.objects.create_user(
            'push.employee@bitbyte.test',
            'Test@1234',
            role='employee',
        )

    def test_login_id_resolves_email_alias_for_registered_device(self):
        aliases = _recipient_user_ids(self.employee.user_id)
        self.assertIn(self.employee.user_id, aliases)
        self.assertIn(self.employee.email, aliases)

    def test_email_resolves_login_id_alias_for_registered_device(self):
        aliases = _recipient_user_ids(self.employee.email)
        self.assertIn(self.employee.email, aliases)
        self.assertIn(self.employee.user_id, aliases)
