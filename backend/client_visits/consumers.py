from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError

from .journey_permissions import can_view_journey
from .models import ClientVisitJourney


@database_sync_to_async
def _authenticate_token(raw_token):
    if not raw_token:
        return AnonymousUser()
    authentication = JWTAuthentication()
    try:
        validated = authentication.get_validated_token(raw_token)
        return authentication.get_user(validated)
    except (InvalidToken, TokenError):
        return AnonymousUser()


@database_sync_to_async
def _authorized(user, journey_id):
    try:
        journey = ClientVisitJourney.objects.select_related(
            'employee', 'assigned_team_lead',
        ).get(pk=journey_id)
    except ClientVisitJourney.DoesNotExist:
        return False
    return can_view_journey(user, journey)


class JourneyTrackingConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        query = parse_qs(self.scope.get('query_string', b'').decode())
        token = (query.get('token') or [''])[0]
        self.scope['user'] = await _authenticate_token(token)
        self.journey_id = int(self.scope['url_route']['kwargs']['journey_id'])
        if not await _authorized(self.scope['user'], self.journey_id):
            await self.close(code=4403)
            return
        self.group_name = f'client_journey_{self.journey_id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        await self.send_json({'type': 'connected', 'journey_id': self.journey_id})

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        if content.get('type') == 'ping':
            await self.send_json({'type': 'pong'})

    async def location_update(self, event):
        await self.send_json(event['payload'])
