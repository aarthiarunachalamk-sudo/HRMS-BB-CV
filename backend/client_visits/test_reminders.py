from datetime import datetime, timedelta, timezone as datetime_timezone
from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APITestCase

from client_visits.management.commands.send_client_visit_reminders import (
    IST,
    send_client_visit_reminders,
)
from client_visits.models import ClientVisit
from hrms.models import AppNotification, User


def _visit(*, employee_user_id, scheduled_at, status='approved'):
    return ClientVisit.objects.create(
        employee_user_id=employee_user_id,
        employee_name='Selva Perumal',
        client_name='Excel Engineering College',
        contact_person='HOD',
        address='Kumarapalayam',
        scheduled_date=scheduled_at.date(),
        scheduled_time=scheduled_at.time(),
        purpose='Student discussion',
        status=status,
    )


class ClientVisitReminderTests(TestCase):
    @patch(
        'client_visits.management.commands.send_client_visit_reminders.send_mobile_push',
        return_value=True,
    )
    def test_two_hour_and_one_hour_reminders_are_sent_once(self, push):
        now = datetime(2026, 8, 11, 9, 0, tzinfo=IST)
        two_hour_visit = _visit(
            employee_user_id='BBTL0002',
            scheduled_at=now + timedelta(hours=2),
        )
        one_hour_visit = _visit(
            employee_user_id='BBTL0003',
            scheduled_at=now + timedelta(hours=1),
        )

        self.assertEqual(send_client_visit_reminders(now), 2)
        self.assertEqual(send_client_visit_reminders(now), 0)
        self.assertEqual(push.call_count, 2)
        self.assertTrue(
            AppNotification.objects.filter(
                reference_id=f'{two_hour_visit.id}:reminder:120',
                title='Client Visit in 2 Hours',
            ).exists()
        )
        self.assertTrue(
            AppNotification.objects.filter(
                reference_id=f'{one_hour_visit.id}:reminder:60',
                title='Start to Visit in 1 Hour',
            ).exists()
        )

    @patch(
        'client_visits.management.commands.send_client_visit_reminders.send_mobile_push'
    )
    def test_non_approved_visit_does_not_receive_reminder(self, push):
        now = datetime(2026, 8, 11, 9, 0, tzinfo=IST)
        _visit(
            employee_user_id='BBTL0002',
            scheduled_at=now + timedelta(hours=1),
            status='travelling',
        )

        self.assertEqual(send_client_visit_reminders(now), 0)
        push.assert_not_called()


class ClientVisitStartTests(APITestCase):
    def setUp(self):
        self.employee = User.objects.create_user(
            'visit-start-window@example.com',
            role='employee',
        )
        self.scheduled_at = datetime(2026, 8, 12, 9, 0, tzinfo=IST)
        self.visit = _visit(
            employee_user_id=self.employee.user_id,
            scheduled_at=self.scheduled_at,
        )

    def _start(self):
        return self.client.post(
            f'/api/client-visits/{self.visit.id}/start-travel/',
            {
                'user_id': self.employee.user_id,
                'latitude': 11.6643,
                'longitude': 78.1460,
            },
            format='json',
        )

    @patch('client_visits.views.send_mobile_push', return_value=False)
    @patch('client_visits.views.timezone.now')
    def test_start_to_visit_is_allowed_before_one_hour_window(self, now, _push):
        now.return_value = self.scheduled_at.astimezone(
            datetime_timezone.utc
        ) - timedelta(hours=1, minutes=1)

        response = self._start()

        self.assertEqual(response.status_code, 200)
        self.visit.refresh_from_db()
        self.assertEqual(self.visit.status, 'travelling')

    @patch('client_visits.views.send_mobile_push', return_value=False)
    @patch('client_visits.views.timezone.now')
    def test_start_to_visit_changes_status_at_one_hour(self, now, _push):
        now.return_value = self.scheduled_at.astimezone(
            datetime_timezone.utc
        ) - timedelta(hours=1)

        response = self._start()

        self.assertEqual(response.status_code, 200)
        self.visit.refresh_from_db()
        self.assertEqual(self.visit.status, 'travelling')


class LeadershipClientVisitTests(APITestCase):
    def test_leadership_visits_skip_approver_and_are_self_approved(self):
        for index, role in enumerate(('admin', 'ceo', 'md', 'director'), 1):
            with self.subTest(role=role):
                user = User.objects.create_user(
                    f'visit-{role}@example.com',
                    role=role,
                )
                response = self.client.post(
                    '/api/client-visits/',
                    {
                        'user_id': user.user_id,
                        'client_name': f'Leadership Client {index}',
                        'contact_person': 'Manager',
                        'contact_phone': f'98765432{index:02d}',
                        'address': 'Chennai',
                        'scheduled_date': '2026-08-15',
                        'scheduled_time': '10:00',
                        'purpose': 'Leadership meeting',
                        'submit': True,
                    },
                    format='json',
                )

                self.assertEqual(response.status_code, 201, response.data)
                visit = ClientVisit.objects.get(pk=response.data['visit']['id'])
                self.assertEqual(visit.status, 'approved')
                self.assertEqual(visit.approved_by, user.user_id)
                self.assertEqual(visit.manager_user_id, '')
