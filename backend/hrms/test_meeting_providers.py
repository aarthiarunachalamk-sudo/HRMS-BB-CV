from datetime import datetime, timezone
from unittest.mock import patch

from django.test import SimpleTestCase

from .meeting_providers import (
    create_provider_meeting,
    provider_configuration,
)


class MeetingProviderTests(SimpleTestCase):
    @patch.dict(
        'os.environ',
        {
            'GOOGLE_MEET_SERVICE_ACCOUNT_JSON': '{"type":"service_account"}',
            'GOOGLE_MEET_ORGANIZER_EMAIL': 'organizer@example.com',
            'ZOOM_ACCOUNT_ID': 'account',
            'ZOOM_CLIENT_ID': 'client',
            'ZOOM_CLIENT_SECRET': 'secret',
            'ZOOM_HOST_EMAIL': 'zoom@example.com',
            'MICROSOFT_TENANT_ID': 'tenant',
            'MICROSOFT_CLIENT_ID': 'client',
            'MICROSOFT_CLIENT_SECRET': 'secret',
            'MICROSOFT_TEAMS_ORGANIZER_USER_ID': 'organizer-id',
        },
    )
    def test_configuration_reports_all_supported_providers(self):
        self.assertEqual(
            provider_configuration(),
            {
                'Google Meet': True,
                'Zoom': True,
                'Microsoft Teams': True,
            },
        )

    @patch.dict(
        'os.environ',
        {
            'ZOOM_ACCOUNT_ID': 'account',
            'ZOOM_CLIENT_ID': 'client',
            'ZOOM_CLIENT_SECRET': 'secret',
            'ZOOM_HOST_EMAIL': 'zoom@example.com',
        },
    )
    @patch('hrms.meeting_providers._request_json')
    def test_zoom_returns_participant_join_url(self, request_json):
        request_json.side_effect = [
            {'access_token': 'token'},
            {
                'id': 123456789,
                'join_url': 'https://zoom.us/j/123456789?pwd=abc',
                'password': 'abc',
            },
        ]

        result = create_provider_meeting(
            'Zoom',
            title='Zoom review',
            description='Quarterly review',
            starts_at=datetime(2026, 8, 1, 10, tzinfo=timezone.utc),
            duration_minutes=30,
        )

        self.assertEqual(
            result['join_url'],
            'https://zoom.us/j/123456789?pwd=abc',
        )
        self.assertEqual(request_json.call_count, 2)

    @patch.dict(
        'os.environ',
        {
            'MICROSOFT_TENANT_ID': 'tenant',
            'MICROSOFT_CLIENT_ID': 'client',
            'MICROSOFT_CLIENT_SECRET': 'secret',
            'MICROSOFT_TEAMS_ORGANIZER_USER_ID': 'organizer-id',
        },
    )
    @patch('hrms.meeting_providers._request_json')
    def test_teams_returns_participant_join_url(self, request_json):
        request_json.side_effect = [
            {'access_token': 'token'},
            {
                'id': 'meeting-id',
                'joinWebUrl': (
                    'https://teams.microsoft.com/l/meetup-join/test'
                ),
            },
        ]

        result = create_provider_meeting(
            'Microsoft Teams',
            title='Teams review',
            description='Quarterly review',
            starts_at=datetime(2026, 8, 1, 10, tzinfo=timezone.utc),
            duration_minutes=45,
        )

        self.assertEqual(
            result['join_url'],
            'https://teams.microsoft.com/l/meetup-join/test',
        )
        self.assertEqual(request_json.call_count, 2)
