# Login and attendance flow review — 10 September 2026

## Validation

39 local Django tests passed: attendance duration, checkout policy, profile/login,
and authenticated client journeys. These use SQLite and a fast test password
hasher; their run time is not a production login benchmark. No live attendance
was submitted and no authenticated device timing was measured.

## Login loading

The app starts backend warmup at launch. Sign In waits for authentication before
navigating. Token persistence, remembered credentials and push registration do
not block navigation. The transition takes 250 ms. Public login requests have a
65-second timeout; server errors can trigger a retry after 700 ms. This is a
timeout ceiling, not an intentional 65-second delay.

Login reports total API time, Server-Timing (server/database duration), and the
dashboard frame time. The dashboard separately fetches its data and may request
attendance history when check-in is missing. The greeting requires dismissal.

A live health probe connected in 0.080 seconds but timed out at 30.003 seconds
without receiving a response. This probe cannot identify cold start, queuing or
upstream failure as the cause. A two-second authenticated login is not verified.
A second health probe returned HTTP 200 in 29.249 seconds (connection: 0.042
seconds), confirming slow responses across both probes from this environment.

## Check-in and checkout loading

Camera initialization overlaps location acquisition. A recent GPS fix may be
reused for up to 45 seconds; obtaining a fresh fix can take up to 12 seconds.
Reverse geocoding runs in the background with an eight-second timeout. The
selfie is watermarked before upload. Its capture timestamp, rather than upload
completion time, becomes the submitted attendance time.

Attendance upload currently has no explicit application timeout. The backend
saves the photo and creates notifications before returning success. Push sends
are synchronous and run for multiple management recipients, making them a
potential response-time bottleneck. These stages require device/server timings
before claiming any fixed completion time.

## Working hours and attendance policy

- Displayed working hours are elapsed checkout minus check-in, including seconds.
- Lunch is not deducted from displayed hours. Overtime uses credited time after
  actual overlap with the 13:00–14:00 lunch period, above eight hours.
- Shift starts at 09:00 with ten minutes of grace. Late minutes count from 09:10.
- Early checkout before 17:30 requires approval, with an approved second-half
  leave exception from 13:00. A pending request does not record checkout.
- Automatic checkout is scheduled for 18:30; approved second-half leave uses
  13:00. Execution depends on the attendance scheduler running.
- Open attendance gets elapsed duration on refresh; old unclosed dates do not
  accumulate indefinitely. Completed records retain their finished duration.
- Saved offsets preserve displayed mobile check-in/check-out time zones.

Examples verified by tests:

| Check-in | Checkout | Displayed duration | Overtime |
|---|---|---|---|
| 09:00 | 17:30 | 08h 30m 00s | 0 min |
| 09:00 | 18:00 | 09h 00m 00s | 0 min |
| 09:00 | 18:30 | 09h 30m 00s | 30 min |
| 12:39 | 13:17 | 00h 38m 00s | 0 min |

The duration helper handles midnight crossings, but the checkout endpoint looks
up the current local date. This flow implements a daily shift, not general
overnight shifts. Attendance timestamps currently trust the submitted device
clock, so device-clock accuracy remains a dependency.

## Fix made

Repeated check-in previously overwrote the original proof, work mode and status,
including after checkout. It now returns the saved attendance without changing
those fields or resending presence notifications. Regression tests cover open
and completed attendance. This backend change requires deployment; it does not
change the already-built version 1.42 APK.
