import json
import os
from urllib.error import HTTPError, URLError
from urllib.request import Request as UrlRequest, urlopen

from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2 import service_account


GOOGLE_MEET_CREATE_SCOPE = (
    'https://www.googleapis.com/auth/meetings.space.created'
)
GOOGLE_MEET_SPACES_URL = 'https://meet.googleapis.com/v2/spaces'


class GoogleMeetConfigurationError(RuntimeError):
    pass


class GoogleMeetCreationError(RuntimeError):
    pass


def create_google_meet_space():
    raw_credentials = os.getenv(
        'GOOGLE_MEET_SERVICE_ACCOUNT_JSON',
        '',
    ).strip()
    organizer_email = os.getenv('GOOGLE_MEET_ORGANIZER_EMAIL', '').strip()
    if not raw_credentials or not organizer_email:
        raise GoogleMeetConfigurationError(
            'Google Meet auto-generation is not configured. Set '
            'GOOGLE_MEET_SERVICE_ACCOUNT_JSON and GOOGLE_MEET_ORGANIZER_EMAIL.'
        )

    try:
        credentials_info = json.loads(raw_credentials)
    except json.JSONDecodeError as error:
        raise GoogleMeetConfigurationError(
            'GOOGLE_MEET_SERVICE_ACCOUNT_JSON is not valid JSON.'
        ) from error

    try:
        credentials = service_account.Credentials.from_service_account_info(
            credentials_info,
            scopes=[GOOGLE_MEET_CREATE_SCOPE],
        ).with_subject(organizer_email)
        credentials.refresh(GoogleAuthRequest())
    except Exception as error:
        raise GoogleMeetCreationError(
            'Google Meet authorization failed. Check API access, domain-wide '
            'delegation, organizer email, and OAuth scope.'
        ) from error

    request = UrlRequest(
        GOOGLE_MEET_SPACES_URL,
        data=b'{}',
        headers={
            'Authorization': f'Bearer {credentials.token}',
            'Content-Type': 'application/json',
        },
        method='POST',
    )
    try:
        with urlopen(request, timeout=20) as response:
            payload = json.loads(response.read().decode('utf-8'))
    except HTTPError as error:
        details = error.read().decode('utf-8', errors='replace')
        raise GoogleMeetCreationError(
            f'Google Meet rejected room creation ({error.code}): {details[:300]}'
        ) from error
    except (URLError, TimeoutError, json.JSONDecodeError) as error:
        raise GoogleMeetCreationError(
            'Google Meet room creation is temporarily unavailable.'
        ) from error

    meeting_uri = str(payload.get('meetingUri') or '').strip()
    if not meeting_uri.startswith('https://meet.google.com/'):
        raise GoogleMeetCreationError(
            'Google Meet did not return a valid attendee link.'
        )
    return {
        'meeting_uri': meeting_uri,
        'meeting_code': str(payload.get('meetingCode') or '').strip(),
        'space_name': str(payload.get('name') or '').strip(),
    }
