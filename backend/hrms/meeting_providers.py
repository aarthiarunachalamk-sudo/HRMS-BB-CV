import base64
import json
import os
from datetime import timedelta
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen

from .google_meet import (
    GoogleMeetConfigurationError,
    GoogleMeetCreationError,
    create_google_meet_space,
)


class MeetingProviderConfigurationError(RuntimeError):
    pass


class MeetingProviderCreationError(RuntimeError):
    pass


def provider_configuration():
    return {
        'Google Meet': all(
            os.getenv(name, '').strip()
            for name in (
                'GOOGLE_MEET_SERVICE_ACCOUNT_JSON',
                'GOOGLE_MEET_ORGANIZER_EMAIL',
            )
        ),
        'Zoom': all(
            os.getenv(name, '').strip()
            for name in (
                'ZOOM_ACCOUNT_ID',
                'ZOOM_CLIENT_ID',
                'ZOOM_CLIENT_SECRET',
                'ZOOM_HOST_EMAIL',
            )
        ),
        'Microsoft Teams': all(
            os.getenv(name, '').strip()
            for name in (
                'MICROSOFT_TENANT_ID',
                'MICROSOFT_CLIENT_ID',
                'MICROSOFT_CLIENT_SECRET',
                'MICROSOFT_TEAMS_ORGANIZER_USER_ID',
            )
        ),
    }


def create_provider_meeting(
    platform,
    *,
    title,
    description,
    starts_at,
    duration_minutes,
):
    if platform == 'Google Meet':
        try:
            generated = create_google_meet_space()
        except GoogleMeetConfigurationError as error:
            raise MeetingProviderConfigurationError(str(error)) from error
        except GoogleMeetCreationError as error:
            raise MeetingProviderCreationError(str(error)) from error
        return {
            'join_url': generated['meeting_uri'],
            'provider_id': generated['space_name'],
            'meeting_code': generated['meeting_code'],
        }
    if platform == 'Zoom':
        return _create_zoom_meeting(
            title=title,
            description=description,
            starts_at=starts_at,
            duration_minutes=duration_minutes,
        )
    if platform == 'Microsoft Teams':
        return _create_teams_meeting(
            title=title,
            starts_at=starts_at,
            duration_minutes=duration_minutes,
        )
    raise MeetingProviderConfigurationError(
        f'Automatic meeting creation is not supported for {platform}.'
    )


def _request_json(url, *, method='GET', headers=None, body=None, timeout=20):
    request = Request(
        url,
        data=body,
        headers=headers or {},
        method=method,
    )
    try:
        with urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode('utf-8'))
    except HTTPError as error:
        details = error.read().decode('utf-8', errors='replace')
        raise MeetingProviderCreationError(
            f'Meeting provider rejected the request ({error.code}): '
            f'{details[:300]}'
        ) from error
    except (URLError, TimeoutError, json.JSONDecodeError) as error:
        raise MeetingProviderCreationError(
            'The meeting provider is temporarily unavailable.'
        ) from error


def _create_zoom_meeting(*, title, description, starts_at, duration_minutes):
    account_id = os.getenv('ZOOM_ACCOUNT_ID', '').strip()
    client_id = os.getenv('ZOOM_CLIENT_ID', '').strip()
    client_secret = os.getenv('ZOOM_CLIENT_SECRET', '').strip()
    host_email = os.getenv('ZOOM_HOST_EMAIL', '').strip()
    if not all((account_id, client_id, client_secret, host_email)):
        raise MeetingProviderConfigurationError(
            'Zoom auto-generation is not configured.'
        )

    basic_token = base64.b64encode(
        f'{client_id}:{client_secret}'.encode('utf-8')
    ).decode('ascii')
    token_payload = urlencode({
        'grant_type': 'account_credentials',
        'account_id': account_id,
    }).encode('utf-8')
    token = _request_json(
        'https://zoom.us/oauth/token',
        method='POST',
        headers={
            'Authorization': f'Basic {basic_token}',
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body=token_payload,
    ).get('access_token')
    if not token:
        raise MeetingProviderCreationError(
            'Zoom did not return an access token.'
        )

    payload = json.dumps({
        'topic': title,
        'type': 2,
        'start_time': starts_at.isoformat(),
        'duration': duration_minutes,
        'agenda': description,
        'settings': {
            'join_before_host': True,
            'waiting_room': False,
        },
    }).encode('utf-8')
    meeting = _request_json(
        f'https://api.zoom.us/v2/users/{quote(host_email, safe="")}/meetings',
        method='POST',
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
        },
        body=payload,
    )
    join_url = str(meeting.get('join_url') or '').strip()
    if not join_url.startswith('https://'):
        raise MeetingProviderCreationError(
            'Zoom did not return a valid attendee link.'
        )
    return {
        'join_url': join_url,
        'provider_id': str(meeting.get('id') or ''),
        'meeting_code': str(meeting.get('password') or ''),
    }


def _create_teams_meeting(*, title, starts_at, duration_minutes):
    tenant_id = os.getenv('MICROSOFT_TENANT_ID', '').strip()
    client_id = os.getenv('MICROSOFT_CLIENT_ID', '').strip()
    client_secret = os.getenv('MICROSOFT_CLIENT_SECRET', '').strip()
    organizer_id = os.getenv(
        'MICROSOFT_TEAMS_ORGANIZER_USER_ID',
        '',
    ).strip()
    if not all((tenant_id, client_id, client_secret, organizer_id)):
        raise MeetingProviderConfigurationError(
            'Microsoft Teams auto-generation is not configured.'
        )

    token_payload = urlencode({
        'client_id': client_id,
        'client_secret': client_secret,
        'scope': 'https://graph.microsoft.com/.default',
        'grant_type': 'client_credentials',
    }).encode('utf-8')
    token = _request_json(
        f'https://login.microsoftonline.com/{quote(tenant_id, safe="")}'
        '/oauth2/v2.0/token',
        method='POST',
        headers={'Content-Type': 'application/x-www-form-urlencoded'},
        body=token_payload,
    ).get('access_token')
    if not token:
        raise MeetingProviderCreationError(
            'Microsoft Entra did not return an access token.'
        )

    ends_at = starts_at + timedelta(minutes=duration_minutes)
    payload = json.dumps({
        'startDateTime': starts_at.isoformat(),
        'endDateTime': ends_at.isoformat(),
        'subject': title,
    }).encode('utf-8')
    meeting = _request_json(
        'https://graph.microsoft.com/v1.0/users/'
        f'{quote(organizer_id, safe="")}/onlineMeetings',
        method='POST',
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
        },
        body=payload,
    )
    join_url = str(meeting.get('joinWebUrl') or '').strip()
    if not join_url.startswith('https://'):
        raise MeetingProviderCreationError(
            'Microsoft Teams did not return a valid attendee link.'
        )
    return {
        'join_url': join_url,
        'provider_id': str(meeting.get('id') or ''),
        'meeting_code': str(
            (meeting.get('joinMeetingIdSettings') or {}).get('joinMeetingId')
            or ''
        ),
    }
