# Google Meet automatic links

The backend creates one Google Meet space per HR meeting by calling
`POST https://meet.googleapis.com/v2/spaces`. Credentials stay on the server
and must never be bundled into the mobile application.

## Google Workspace setup

1. Enable the Google Meet REST API in the deployment's Google Cloud project.
2. Create a service account and enable domain-wide delegation.
3. In Google Workspace Admin Console, authorize the service account client ID
   for this OAuth scope:

   `https://www.googleapis.com/auth/meetings.space.created`

4. Choose an active Google Workspace user who will own the rooms.
5. Configure these backend environment variables:

   - `GOOGLE_MEET_SERVICE_ACCOUNT_JSON`: complete service-account JSON,
     serialized on one line.
   - `GOOGLE_MEET_ORGANIZER_EMAIL`: the Workspace organizer email impersonated
     through domain-wide delegation.

6. Restart the backend after setting the environment variables.

If configuration or Google authorization fails, meeting creation returns a
clear error and does not save a fake or unusable link.

Official references:

- https://developers.google.com/workspace/meet/api/guides/authenticate-authorize
- https://developers.google.com/workspace/meet/api/reference/rest/v2/spaces/create
