import base64
import json
import logging
import os
from urllib import error, request


logger = logging.getLogger(__name__)


def _first_env_value(*names):
    for name in names:
        value = os.getenv(name, '').strip()
        if value:
            return value
    return ''


def email_is_configured():
    return bool(
        os.getenv('RESEND_API_KEY')
        or os.getenv('HR_RESEND_API_KEY')
        or os.getenv('SENDGRID_API_KEY')
    )


def send_email(
    to,
    subject,
    html,
    attachments=None,
    resend_api_key_env='RESEND_API_KEY',
    from_email_env='EMAIL_FROM',
    sendgrid_api_key_env='SENDGRID_API_KEY',
    fallback_resend_api_key_env='',
    fallback_from_email_env='',
    fallback_sendgrid_api_key_env='',
):
    """Send transactional email through Resend, with SendGrid as fallback."""
    recipients = [to] if isinstance(to, str) else list(to or [])
    recipients = [str(item).strip() for item in recipients if str(item).strip()]
    if not recipients:
        raise ValueError('At least one recipient email is required.')

    resend_key = _first_env_value(resend_api_key_env, fallback_resend_api_key_env)
    if resend_key:
        payload = {
            'from': _first_env_value(from_email_env, fallback_from_email_env) or 'onboarding@resend.dev',
            'to': recipients,
            'subject': subject,
            'html': html,
        }
        if attachments:
            payload['attachments'] = [
                {
                    'filename': item['filename'],
                    'content': base64.b64encode(item['content']).decode('ascii'),
                }
                for item in attachments
            ]
        api_request = request.Request(
            'https://api.resend.com/emails',
            data=json.dumps(payload).encode('utf-8'),
            headers={
                'Authorization': f'Bearer {resend_key}',
                'Content-Type': 'application/json',
                'User-Agent': 'BitByte-HRMS/1.0',
            },
            method='POST',
        )
        try:
            with request.urlopen(api_request, timeout=20) as response:
                return json.loads(response.read().decode('utf-8'))
        except error.HTTPError as exc:
            details = exc.read().decode('utf-8', errors='replace')
            logger.error('Resend rejected email (%s): %s', exc.code, details)
            raise RuntimeError(f'Resend rejected email with status {exc.code}.') from exc

    sendgrid_key = _first_env_value(sendgrid_api_key_env, fallback_sendgrid_api_key_env)
    if sendgrid_key:
        from sendgrid import SendGridAPIClient
        from sendgrid.helpers.mail import (
            Attachment, Disposition, FileContent, FileName, FileType, Mail,
        )

        message = Mail(
            from_email=_first_env_value(from_email_env, fallback_from_email_env) or 'noreply@bitbyte.com',
            to_emails=recipients,
            subject=subject,
            html_content=html,
        )
        if attachments:
            message.attachment = [
                Attachment(
                    FileContent(base64.b64encode(item['content']).decode('ascii')),
                    FileName(item['filename']),
                    FileType(item.get('content_type', 'application/octet-stream')),
                    Disposition('attachment'),
                )
                for item in attachments
            ]
        return SendGridAPIClient(sendgrid_key).send(message)

    raise RuntimeError('Email delivery is not configured.')
