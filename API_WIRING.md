# ضوجة — live API wiring

## Run

Flutter SDK on this box: `/home/box/flutter/bin`.

```bash
export PATH=/home/box/flutter/bin:$PATH
flutter pub get
# Web/browser on the SAME computer as the API:
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5080
# Android emulator, ONLY if the API runs on that emulator's host computer:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5080
# Physical device / deployed API:
flutter run --dart-define=API_BASE_URL=https://dooja.cloudapps.trade
# Production builds MUST specify a real HTTPS host:
flutter build apk --dart-define=API_BASE_URL=https://dooja.cloudapps.trade
```

Debug defaults to `http://127.0.0.1:5080`. Release/profile builds have **no implicit API host**; they show a configuration error if `API_BASE_URL` is omitted. Rebuild after changing the define. Do not include `/api` in the base URL.

The API currently running on this box is bound to loopback. A phone or an emulator on a different computer **cannot reach this box via its own `127.0.0.1` or `10.0.2.2`**. Deploy/reverse-proxy the API on a reachable HTTPS host first. No public deployment or API process restart was performed. Web production needs the app's explicit CORS origin configured on the API; HTTPS pages cannot call an HTTP API. Android cleartext is allowed only in the debug manifest; release uses HTTPS. Android INTERNET permission is included.

## Auth and data

- Phone OTP request and verification go to `/api/auth/request-otp` and `/api/auth/verify`; the entered code is checked **by the server**, not a client-side `1234` comparison.
- JWT is persisted with `flutter_secure_storage`, restored at startup, added as a Bearer header, and removed on logout/401. Web secure storage needs HTTPS or localhost; do not expose tokens to logs. Android uses secure platform storage. Other platform projects are not present in this repository.
- Development API examples: customer `07700000001`, owner `07700000002`, OTP `1234` **after requesting an OTP**. Production API intentionally rejects login until real SMS is integrated.
- `Repo` collections are initially empty, API-backed response snapshots. No seed lists, generated bookings, artificial latency, fabricated counters/reviews/comments/notifications, offline fallback records or simulated successful writes remain. Refresh after mutations and tab changes; refresh buttons are available. Failures show an Arabic message and failed refreshes empty the snapshots.
- Important: the **server's Development SQLite database still contains demonstration records**. They are not verified live businesses/activity. For genuinely real data, use a fresh production DB with `Seed__Demo=false`; see the dashboard README. Removing client mocks does not turn server sample records into real activity.

## What changed

- Added `lib/api/api_client.dart`: configurable host, bounded HTTP requests, JSON/error handling, Bearer auth and secure token persistence.
- Replaced `lib/repo.dart` with async HTTP operations and JSON mappings. Stable API integer IDs drive booking/review/reel/notification/service mutations; display booking codes are not used as database IDs. Place pagination is read from the server.
- Startup restores/validates a session and loads API data. Auth, home/search/category, place/reviews/services, booking/payment/waitlist, offers, reels/comments/likes, favorites/follows, notifications, rewards balance and profile call sites now use server data.
- Booking dates are current ISO dates, times are 24-hour on the wire; availability and overlapping hours come from the API. Unknown availability is blocked, not shown as free. Price estimates match API hourly/per-person pricing and selected offer IDs are submitted. The **server decides actual price/status**. Cash only; no fake card success or ZainCash charge.
- Owner screens now select actual owned places and use owner dashboard, place CRUD, bookings/status/arrival, service CRUD, offers/toggles/counters, review replies, closed slots, and image-caption reel publishing APIs. Manual exact booking-code lookup replaces the fake camera scanner.
- Disabled the mock design gallery and replaced unsupported feature simulations with honest Arabic unavailable messages. `dsl.dart`, `common.dart`, color/font assets and RTL configuration remain unchanged.

## Intentional gaps (not simulated)

Real SMS, push (FCM/APNs), card/ZainCash payments/refunds/settlement, photo/video uploads/storage, geolocation/maps/distance measurement, camera QR scanning, staff permissions, owner onboarding/approval requests, detailed opening hours/amenities, group invites/split payments, rewards redemption/challenges, account deletion/phone changes, notification settings and production deployment need additional integrations/API routes. Interests are clearly labelled local/session-only preferences.

The current API does not provide a GET for the current user's reel-like state, saved reels, personalized review lists, full analytics histories or invitation state. Reel like toggles/counters persist on the server, but the initial heart selection cannot be restored after restart until the API exposes that state; saved reels are disabled. API list caps (e.g. bookings/reels/reviews) still apply. Services display from the server but are not extra line items in the current booking API. No payment, uploaded media, push reminder, attendance scan or group-member activity is claimed.

## Verification

```bash
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:5080
```

Tests cover token persistence/Bearer headers/401, JSON contracts and numeric IDs, empty/error responses without invented rows, availability, Iraqi phone normalization and empty RTL screen rendering. HTTP test fixtures exist **only in tests**. Live curl checks verified OTP login and persisted places; customer/owner read routes were also smoke-tested against port 5080 without killing the running API. Standard JS web build works; secure-storage's current web dependency reports a Wasm dry-run incompatibility, so Wasm is not claimed. No device installation or full live Flutter UI E2E has been performed.

No GitHub push/commit, production deployment, real charge or outside message was performed. Source is ready for the parent to copy into its Git checkout; do not copy `build/`, `.dart_tool/`, local SDK files, or credentials.
