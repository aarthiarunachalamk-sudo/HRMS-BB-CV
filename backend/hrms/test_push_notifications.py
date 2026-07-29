from django.test import TestCase
from rest_framework.test import APIClient

from .models import AppNotification, TeamTask, User
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

    def test_admin_task_assignment_keeps_employee_identity_and_notifies(self):
        response = APIClient().post(
            '/api/admin/tasks/',
            {
                'title': 'Verify payroll report',
                'assignee_id': self.employee.user_id,
                'assignee_email': self.employee.email,
                'assignee_name': 'Push Employee',
                'created_by': 'admin-user',
            },
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        task = TeamTask.objects.get(title='Verify payroll report')
        self.assertEqual(task.assignee_id, self.employee.user_id)
        self.assertEqual(task.assignee_email, self.employee.email)
        self.assertTrue(
            AppNotification.objects.filter(
                recipient_user_id=self.employee.user_id,
                module='tasks',
                reference_id=str(task.id),
            ).exists()
        )
