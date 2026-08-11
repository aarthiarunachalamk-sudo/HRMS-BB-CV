# Client Visit Live Journey Tracking

## What is implemented

The existing Client Visit approval and attendance workflows remain unchanged. The new module adds a consent-driven journey state machine, normalized immutable GPS points, SQLite-first offline recording, idempotent batch synchronization, backend Haversine summaries and stop detection, authenticated live WebSocket updates, employee controls, Team Lead live maps, completed-route summaries, audit records, throttling, and configurable retention.

The route is constructed only from real device coordinates ordered by `captured_at` and `sequence_number`. Missing intervals are returned as gaps and are not interpolated. Low-accuracy route sections are orange; trusted sections are blue. No highway/city-road classification is claimed.

## Database migration

Migration `client_visits/0008_clientvisitjourney_journeylocationpoint_journeystop_and_more.py` creates:

- `ClientVisitJourney`, optionally linked one-to-one to an existing `ClientVisit`.
- `JourneyLocationPoint`, with globally unique client UUIDs and journey/sequence uniqueness.
- `JourneyStop`, containing analytical stop windows and approximate centroids.
- PostgreSQL-compatible coordinate checks, active-journey uniqueness, and journey/time, journey/sequence, employee/time, TL/status and status/latest-location indexes.

Run from `backend`:

```powershell
python manage.py migrate
```

## Backend packages

New pinned packages in `backend/requirements.txt`:

- `djangorestframework-simplejwt==5.5.1`
- `channels==4.3.1`
- `channels-redis==4.3.0`
- `daphne==4.2.1`

Install with:

```powershell
python -m pip install -r requirements.txt
```

## Flutter packages

New packages in `frontend/pubspec.yaml`:

- `sqflite ^2.4.3`
- `connectivity_plus ^7.3.1`
- `web_socket_channel ^3.0.3`
- `uuid ^4.6.0`
- `flutter_foreground_task ^10.0.0`

`google_maps_flutter`, `geolocator`, and `flutter_secure_storage` were already present and are reused.

```powershell
cd frontend
flutter pub get
```

## Environment variables

Existing database and Django variables remain in use. Add or tune:

```text
REDIS_URL=redis://username:password@host:6379/0
JWT_ACCESS_MINUTES=30
JWT_REFRESH_DAYS=14
JOURNEY_LOCATION_THROTTLE=120/minute
CLIENT_JOURNEY_LOW_ACCURACY_METRES=100
CLIENT_JOURNEY_MAX_SPEED_MPS=70
CLIENT_JOURNEY_MAX_BATCH_SIZE=100
CLIENT_JOURNEY_STOP_RADIUS_METRES=50
CLIENT_JOURNEY_STOP_MIN_SECONDS=300
CLIENT_JOURNEY_GAP_SECONDS=180
CLIENT_JOURNEY_RETENTION_DAYS=365
```

Without `REDIS_URL`, development/test uses an in-memory channel layer. Do not use the in-memory layer with multiple production processes.

## ASGI, Redis and HTTPS/WSS

The Django application is configured as `backend.asgi:application`. Production must run an ASGI server, for example:

```powershell
daphne -b 0.0.0.0 -p $env:PORT backend.asgi:application
```

Render currently starts `backend.wsgi:application`; changing that production process definition requires explicit infrastructure approval. Until it is changed to ASGI, REST works but production WebSockets do not. Configure `REDIS_URL` before scaling to more than one ASGI process. The reverse proxy must terminate HTTPS and forward WebSocket upgrade headers so Flutter uses WSS.

## Authentication

Successful existing login responses now also include `access_token` and `refresh_token`. Existing response fields and role behavior are unchanged. Flutter stores these values in secure storage. Journey REST endpoints require `Authorization: Bearer <access token>`. Refresh with:

```http
POST /api/auth/token/refresh/
Content-Type: application/json

{"refresh":"<refresh token>"}
```

## REST API

All endpoints below require a bearer access token. Employee and TL identity is derived from the token, never from request IDs.

| Method | Path | Purpose |
|---|---|---|
| POST | `/api/client-journeys/` | Create the authenticated employee's journey |
| GET | `/api/client-journeys/assignees/` | Active eligible TL/manager choices |
| GET | `/api/client-journeys/` | Paginated permitted journeys |
| GET | `/api/client-journeys/{id}/` | Journey metadata and summary |
| POST | `/api/client-journeys/{id}/ready/` | `SCHEDULED → READY` |
| POST | `/api/client-journeys/{id}/start/` | `READY → IN_PROGRESS` |
| POST | `/api/client-journeys/{id}/locations/batch/` | Idempotent point batch |
| GET | `/api/client-journeys/{id}/latest-location/` | Latest point and online state |
| GET | `/api/client-journeys/{id}/route/` | Ordered points, stops, gaps and summary |
| POST | `/api/client-journeys/{id}/complete/` | Complete active journey and recalculate summary |
| POST | `/api/client-journeys/{id}/cancel/` | Cancel with required `reason` |
| GET | `/api/team/client-journeys/active/` | Assigned active journeys |
| GET | `/api/team/client-journeys/history/` | Assigned completed/cancelled history |

Create body fields are `source_visit_id` (optional existing visit database ID), `assigned_team_lead_id` (existing TL user code), `client_name`, `client_contact`, `meeting_purpose`, `destination_address`, `destination_latitude`, `destination_longitude`, and UTC `scheduled_at`.

Batch format:

```json
{
  "points": [
    {
      "client_generated_id": "6cf43c8c-68a3-4bf4-b3c6-b30952c81857",
      "latitude": 11.6643,
      "longitude": 78.146,
      "accuracy_metres": 12.4,
      "altitude": 278.0,
      "speed_metres_per_second": 8.1,
      "heading": 125.0,
      "captured_at": "2026-08-11T04:30:00Z",
      "sequence_number": 42,
      "is_mocked": false
    }
  ]
}
```

The response contains independent `accepted`, `duplicates`, and `rejected` collections. Flutter deletes accepted/duplicate queue rows only after acknowledgement and retains network/server failures for retry.

## WebSocket

Connect to:

```text
wss://<host>/ws/client-journeys/{journey_id}/tracking/?token=<access-token>
```

Only the journey employee, assigned TL, or existing management roles can connect. Send `{"type":"ping"}` for a `pong`. After connection/reconnection Flutter first fetches the latest REST point, then appends WebSocket `location_update` events. WebSocket delivery is never the storage authority.

## Android permissions and foreground service

The main manifest declares fine/coarse/background location, notification, foreground service and foreground-service-location permissions. It registers the plugin service with `foregroundServiceType="location"`. Tracking is started only from the explicit consent action and stopped immediately after completion/cancellation.

Android permission behavior:

- GPS off, denied, permanently denied, missing background permission, notification denial and battery optimization are separately explained.
- Settings are opened only after the employee confirms the explanation.
- High accuracy, a 25 m movement filter and roughly 15 s moving interval are used.
- A stationary point is attempted around every 90 s.
- Notification title: `Client journey tracking is active`.
- Notification text: `Location is being shared for: <Client Name>`.

Google Play may require a background-location declaration/review. If policy approval is unavailable, background tracking cannot be guaranteed with the screen locked.

## Google Maps key

The key is not committed. `android/app/build.gradle.kts` reads `MAPS_API_KEY` from `android/local.properties` or the build environment and passes it through a manifest placeholder.

For a developer machine, add to `frontend/android/local.properties` (never commit this file):

```text
MAPS_API_KEY=your_android_maps_key
```

For CI/release, expose `MAPS_API_KEY` as a protected environment variable. In Google Cloud enable only **Maps SDK for Android** and restrict the key to:

1. The final Android application ID (currently `com.example.hrms_mobileapp_bitbyte`; replace this placeholder before production).
2. Every authorized debug/release signing certificate SHA-1.
3. Maps SDK for Android only.

No Places, Geocoding, Routes, Roads, Navigation, Distance Matrix, Street View, or other Google web-service API is called by this module.

## Retention

Preview and apply retention from `backend`:

```powershell
python manage.py purge_expired_journey_locations --dry-run
python manage.py purge_expired_journey_locations
```

Schedule the command only after HR/legal confirms the retention period. Deletion cascades from a terminal journey to its raw points and detected stops.

## Tests and checks

```powershell
cd backend
python manage.py check --settings=backend.test_settings
python manage.py test client_visits --settings=backend.test_settings

cd ..\frontend
flutter analyze --no-pub
flutter test --no-pub
```

Focused suites:

```powershell
python manage.py test client_visits.test_journeys client_visits.test_journey_websocket --settings=backend.test_settings
flutter test --no-pub test/client_journey_core_test.dart
```

## Release APK

Configure a real release signing config first; this repository currently uses the debug signing key for the release build. Then:

```powershell
cd frontend
flutter build apk --release --dart-define=API_BASE_URL=https://your-host/api
```

## Manual checklist

1. Sign in as an employee and confirm JWT fields are stored without changing dashboard routing.
2. Create a journey, select a valid TL, and verify coordinate validation.
3. Confirm no notification/GPS capture occurs before explicit consent and **Start Journey**.
4. Deny each permission once and permanently; verify explanation precedes settings.
5. Start with precise GPS and verify persistent client-specific notification.
6. Lock the screen for five minutes and confirm ordered points continue.
7. Disable network, travel, restart the app, restore network, and verify UUID-safe queue synchronization.
8. Open as the assigned TL; verify latest marker, blue/orange route sections, update age, movement and online state.
9. Create a GPS/network gap; verify the route is visibly disconnected and no position is fabricated.
10. Attempt access as another employee and another TL; expect 403/4403.
11. Tap Reached Client; verify foreground service stops and summary is recalculated.
12. Cancel another active journey; verify a reason is mandatory and tracking stops.
13. Verify completed distance against known GPS points, not Google routing distance.
14. Test empty, one-point, low-accuracy, out-of-order, duplicate and suspicious-jump journeys.

## Known limitations

- Android OEM battery managers can still kill foreground services despite correct permissions; the queue and active-journey recovery minimize loss but cannot override vendor policy.
- Approximate-only permission can produce poor accuracy and is flagged rather than treated as misconduct.
- GPS gaps are intentionally not reconstructed.
- Stop detection is analytical and is not evidence of misconduct.
- The module visually supports road-choice review but does not classify highway versus city roads.
- Production live sockets require the approved WSGI-to-ASGI process switch and Redis for multi-process operation.
