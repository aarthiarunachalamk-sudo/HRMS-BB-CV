from datetime import timedelta
from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from .models import (
    AppNotification,
    AuditLog,
    MdMeeting,
    MeetingParticipantStatus,
    User,
)


class HrMeetingApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.hr = User.objects.create_user(
            'hr.meetings@test.local',
            'Password1!',
            role='hr',
        )
        self.tl = User.objects.create_user(
            'tl.meetings@test.local',
            'Password1!',
            role='tl',
        )
        self.employee = User.objects.create_user(
            'employee.meetings@test.local',
            'Password1!',
            role='employee',
        )

    def _future_schedule(self):
        scheduled_at = timezone.localtime() + timedelta(days=2)
        return {
            'date_label': scheduled_at.strftime('%d-%m-%Y'),
            'time_label': scheduled_at.strftime('%I:%M %p'),
        }

    @patch('hrms.push_notifications.send_mobile_push', return_value=True)
    def test_hr_schedules_and_cancels_meeting_with_notifications(self, push):
        response = self.client.post(
            '/api/hr/meetings/',
            {
                'user_id': self.hr.user_id,
                'title': 'Quarterly People Review',
                'description': 'Review goals and team priorities.',
                **self._future_schedule(),
                'duration': '45 Minutes',
                'platform': 'Google Meet',
                'meeting_link': 'https://meet.google.com/abc-defg-hij',
                'participants': [
                    {'id': self.employee.user_id},
                    {'id': self.tl.user_id},
                ],
                'agenda': ['People updates', 'Next-quarter goals'],
                'invite_email': False,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 201)
        meeting_id = response.data['meeting']['id']
        self.assertEqual(response.data['notified_to'], 2)
        self.assertEqual(
            MeetingParticipantStatus.objects.filter(
                meeting_id=meeting_id,
                status='invited',
                notification_sent=True,
            ).count(),
            2,
        )
        scheduled_notifications = AppNotification.objects.filter(
            module='meeting',
            reference_id=str(meeting_id),
            title='Meeting Scheduled',
        )
        self.assertSetEqual(
            set(scheduled_notifications.values_list('recipient_user_id', flat=True)),
            {self.employee.user_id, self.tl.user_id},
        )
        self.assertEqual(push.call_count, 2)
        self.assertTrue(
            AuditLog.objects.filter(
                action='meeting_scheduled',
                reference_id=str(meeting_id),
            ).exists()
        )

        listed = self.client.get(
            '/api/hr/meetings/',
            {'user_id': self.hr.user_id},
        )
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data['counts']['upcoming'], 1)
        self.assertEqual(len(listed.data['participants']), 2)

        cancelled = self.client.patch(
            f'/api/hr/meetings/{meeting_id}/',
            {'user_id': self.hr.user_id, 'action': 'cancel'},
            format='json',
        )
        self.assertEqual(cancelled.status_code, 200)
        self.assertEqual(cancelled.data['meeting']['status'], 'cancelled')
        self.assertEqual(
            AppNotification.objects.filter(
                module='meeting',
                reference_id=str(meeting_id),
                title='Meeting Cancelled',
            ).count(),
            2,
        )
        self.assertEqual(push.call_count, 4)

    def test_non_hr_cannot_access_hr_meeting_center(self):
        response = self.client.get(
            '/api/hr/meetings/',
            {'user_id': self.employee.user_id},
        )
        self.assertEqual(response.status_code, 403)

    def test_meeting_requires_selected_participant(self):
        response = self.client.post(
            '/api/hr/meetings/',
            {
                'user_id': self.hr.user_id,
                'title': 'Meeting without attendees',
                'description': 'This request should be rejected.',
                **self._future_schedule(),
                'participants': [],
                'invite_email': False,
            },
            format='json',
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn('Select at least one', response.data['message'])
        self.assertEqual(MdMeeting.objects.count(), 0)

    def test_in_person_meeting_requires_a_location(self):
        response = self.client.post(
            '/api/hr/meetings/',
            {
                'user_id': self.hr.user_id,
                'title': 'On-site people review',
                'description': 'Discuss the quarterly people plan.',
                **self._future_schedule(),
                'platform': 'In Person',
                'participants': [{'id': self.tl.user_id}],
                'agenda': ['People plan'],
                'invite_email': False,
            },
            format='json',
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn('location', response.data['message'].lower())
        self.assertEqual(MdMeeting.objects.count(), 0)
