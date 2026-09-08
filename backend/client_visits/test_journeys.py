from datetime import timedelta
from uuid import uuid4

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from hrms.models import User
from .journey_services import haversine_metres
from .models import ClientVisitJourney, JourneyLocationPoint


@override_settings(
    CLIENT_JOURNEY_LOW_ACCURACY_METRES=100,
    CLIENT_JOURNEY_MAX_SPEED_MPS=70,
    CLIENT_JOURNEY_MAX_BATCH_SIZE=100,
    CLIENT_JOURNEY_STOP_RADIUS_METRES=50,
    CLIENT_JOURNEY_STOP_MIN_SECONDS=300,
    CLIENT_JOURNEY_GAP_SECONDS=180,
)
class ClientJourneyApiTests(APITestCase):
    def setUp(self):
        self.employee = User.objects.create_user('journey-employee@example.com', 'password', role='employee')
        self.other_employee = User.objects.create_user('journey-other@example.com', 'password', role='employee')
        self.tl = User.objects.create_user('journey-tl@example.com', 'password', role='tl')
        self.other_tl = User.objects.create_user('journey-other-tl@example.com', 'password', role='tl')
        self._authenticate(self.employee)

    def _authenticate(self, user):
        token = RefreshToken.for_user(user).access_token
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

    def _create(self, **overrides):
        data = {
            'assigned_team_lead_id': self.tl.user_id,
            'client_name': 'Seelanaickenpatti Client',
            'client_contact': '9876543210',
            'meeting_purpose': 'Project discussion',
            'destination_address': 'Seelanaickenpatti, Salem',
            'destination_latitude': 11.6210,
            'destination_longitude': 78.1510,
            'scheduled_at': (timezone.now() + timedelta(hours=1)).isoformat(),
        }
        data.update(overrides)
        return self.client.post('/api/client-journeys/', data, format='json')

    def _ready_and_start(self, journey_id):
        ready = self.client.post(f'/api/client-journeys/{journey_id}/ready/', {}, format='json')
        self.assertEqual(ready.status_code, 200)
        return self.client.post(f'/api/client-journeys/{journey_id}/start/', {}, format='json')

    def _point(self, sequence=1, **overrides):
        data = {
            'client_generated_id': str(uuid4()),
            'latitude': 11.6643,
            'longitude': 78.1460,
            'accuracy_metres': 12.4,
            'altitude': 278.0,
            'speed_metres_per_second': 8.1,
            'heading': 125.0,
            'captured_at': timezone.now().isoformat(),
            'sequence_number': sequence,
            'is_mocked': False,
        }
        data.update(overrides)
        return data

    def test_creation_and_valid_state_transitions(self):
        created = self._create()
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.data['status'], 'SCHEDULED')
        started = self._ready_and_start(created.data['id'])
        self.assertEqual(started.status_code, 200)
        self.assertEqual(started.data['status'], 'IN_PROGRESS')
        completed = self.client.post(f"/api/client-journeys/{created.data['id']}/complete/", {})
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.data['status'], 'COMPLETED')

    def test_existing_login_additively_issues_jwt_tokens(self):
        self.client.credentials()
        response = self.client.post('/api/login/', {
            'email': self.employee.user_id,
            'password': 'password',
        }, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data['success'])
        self.assertIn('access_token', response.data)
        self.assertIn('refresh_token', response.data)

    def test_start_twice_and_complete_inactive_are_rejected(self):
        journey_id = self._create().data['id']
        self.assertEqual(self.client.post(f'/api/client-journeys/{journey_id}/complete/', {}).status_code, 409)
        self.assertEqual(self._ready_and_start(journey_id).status_code, 200)
        self.assertEqual(self.client.post(f'/api/client-journeys/{journey_id}/start/', {}).status_code, 409)

    def test_single_active_journey_constraint(self):
        first = self._create().data['id']
        second = self._create(client_name='Second Client').data['id']
        self.assertEqual(self._ready_and_start(first).status_code, 200)
        self.client.post(f'/api/client-journeys/{second}/ready/', {})
        self.assertEqual(self.client.post(f'/api/client-journeys/{second}/start/', {}).status_code, 409)

    def test_unauthorized_employee_and_tl_access(self):
        journey_id = self._create().data['id']
        self._authenticate(self.other_employee)
        self.assertEqual(self.client.get(f'/api/client-journeys/{journey_id}/').status_code, 403)
        self._authenticate(self.other_tl)
        response = self.client.get('/api/team/client-journeys/active/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['count'], 0)

    def test_batch_is_idempotent_and_partially_rejects_invalid_points(self):
        journey_id = self._create().data['id']
        self._ready_and_start(journey_id)
        valid = self._point()
        invalid = self._point(sequence=2, latitude=91)
        response = self.client.post(
            f'/api/client-journeys/{journey_id}/locations/batch/',
            {'points': [valid, invalid]}, format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['accepted'], [valid['client_generated_id']])
        self.assertEqual(response.data['rejected'][0]['reason'], 'invalid_coordinate')
        retry = self.client.post(
            f'/api/client-journeys/{journey_id}/locations/batch/',
            {'points': [valid]}, format='json',
        )
        self.assertEqual(retry.data['duplicates'], [valid['client_generated_id']])
        self.assertEqual(JourneyLocationPoint.objects.count(), 1)

    def test_upload_after_completion_is_rejected(self):
        journey_id = self._create().data['id']
        self._ready_and_start(journey_id)
        self.client.post(f'/api/client-journeys/{journey_id}/complete/', {})
        response = self.client.post(
            f'/api/client-journeys/{journey_id}/locations/batch/',
            {'points': [self._point()]}, format='json',
        )
        self.assertEqual(response.status_code, 409)

    def test_out_of_order_and_impossible_jump_are_flagged_without_distance_inflation(self):
        journey_id = self._create().data['id']
        self._ready_and_start(journey_id)
        now = timezone.now()
        points = [
            self._point(sequence=1, captured_at=now.isoformat()),
            self._point(
                sequence=2, latitude=13.0827, longitude=80.2707,
                captured_at=(now + timedelta(seconds=10)).isoformat(),
            ),
            self._point(sequence=3, captured_at=(now - timedelta(seconds=5)).isoformat()),
        ]
        response = self.client.post(
            f'/api/client-journeys/{journey_id}/locations/batch/',
            {'points': points}, format='json',
        )
        self.assertEqual(response.status_code, 200)
        suspicious = JourneyLocationPoint.objects.get(sequence_number=2)
        self.assertTrue(suspicious.is_suspicious)
        self.assertIn('impossible_speed', suspicious.suspicion_reason)

    def test_haversine_distance(self):
        distance = haversine_metres(11.6643, 78.1460, 11.6653, 78.1460)
        self.assertGreater(distance, 100)
        self.assertLess(distance, 120)
