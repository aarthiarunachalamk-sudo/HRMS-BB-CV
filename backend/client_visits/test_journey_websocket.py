from datetime import timedelta

from asgiref.sync import sync_to_async
from channels.layers import get_channel_layer
from channels.testing import WebsocketCommunicator
from django.test import TransactionTestCase
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken

from backend.asgi import application
from hrms.models import User
from .models import ClientVisitJourney


class JourneyWebSocketTests(TransactionTestCase):
    async def _setup_journey(self):
        employee = await sync_to_async(User.objects.create_user)(
            'ws-employee@example.com', 'password', role='employee',
        )
        team_lead = await sync_to_async(User.objects.create_user)(
            'ws-tl@example.com', 'password', role='tl',
        )
        outsider = await sync_to_async(User.objects.create_user)(
            'ws-outsider@example.com', 'password', role='employee',
        )
        journey = await sync_to_async(ClientVisitJourney.objects.create)(
            employee=employee,
            assigned_team_lead=team_lead,
            client_name='WebSocket Client',
            meeting_purpose='Live tracking test',
            destination_latitude=11.62,
            destination_longitude=78.15,
            scheduled_at=timezone.now() + timedelta(hours=1),
            status=ClientVisitJourney.Status.IN_PROGRESS,
            started_at=timezone.now(),
        )
        return employee, team_lead, outsider, journey

    async def test_employee_and_assigned_tl_are_authorized_and_receive_updates(self):
        employee, team_lead, _, journey = await self._setup_journey()
        for user in (employee, team_lead):
            token = await sync_to_async(lambda: str(RefreshToken.for_user(user).access_token))()
            communicator = WebsocketCommunicator(
                application,
                f'/ws/client-journeys/{journey.pk}/tracking/?token={token}',
            )
            connected, _ = await communicator.connect()
            self.assertTrue(connected)
            self.assertEqual((await communicator.receive_json_from())['type'], 'connected')
            await get_channel_layer().group_send(
                f'client_journey_{journey.pk}',
                {
                    'type': 'location_update',
                    'payload': {
                        'type': 'location_update',
                        'journey_id': journey.pk,
                        'employee_id': employee.user_id,
                        'latitude': 11.6643,
                        'longitude': 78.1460,
                        'sequence_number': 42,
                    },
                },
            )
            payload = await communicator.receive_json_from()
            self.assertEqual(payload['sequence_number'], 42)
            await communicator.disconnect()

    async def test_unauthorized_user_is_rejected(self):
        _, _, outsider, journey = await self._setup_journey()
        token = await sync_to_async(lambda: str(RefreshToken.for_user(outsider).access_token))()
        communicator = WebsocketCommunicator(
            application,
            f'/ws/client-journeys/{journey.pk}/tracking/?token={token}',
        )
        connected, close_code = await communicator.connect()
        self.assertFalse(connected)
        self.assertEqual(close_code, 4403)
