# Automatic meeting links

Credentials stay on the server and must never be bundled into the mobile
application. The HR screen checks backend configuration per provider. When a
provider isn't configured, HR can paste an existing attendee link instead.

## Google Meet

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

## Zoom

1. Create a Zoom Server-to-Server OAuth app.
2. Grant meeting creation access (`meeting:write:admin` or the corresponding
   granular meeting-write scope).
3. Configure:

   - `ZOOM_ACCOUNT_ID`
   - `ZOOM_CLIENT_ID`
   - `ZOOM_CLIENT_SECRET`
   - `ZOOM_HOST_EMAIL`

## Microsoft Teams

1. Register an application in Microsoft Entra ID.
2. Grant and admin-consent `OnlineMeetings.ReadWrite.All`.
3. Create a Teams application access policy and grant it to the organizer.
4. Configure:

   - `MICROSOFT_TENANT_ID`
   - `MICROSOFT_CLIENT_ID`
   - `MICROSOFT_CLIENT_SECRET`
   - `MICROSOFT_TEAMS_ORGANIZER_USER_ID`

If authorization fails, meeting creation returns a clear error and never saves
a fake `/new`, Zoom landing-page, or Teams landing-page URL.

Official references:

- https://developers.google.com/workspace/meet/api/guides/authenticate-authorize
- https://developers.google.com/workspace/meet/api/reference/rest/v2/spaces/create
- https://developers.zoom.us/docs/internal-apps/s2s-oauth/
- https://developers.zoom.us/docs/api/meetings/
- https://learn.microsoft.com/graph/api/application-post-onlinemeetings
- https://learn.microsoft.com/graph/cloud-communication-online-meeting-application-access-policy
