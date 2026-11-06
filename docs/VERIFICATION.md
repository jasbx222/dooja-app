# Verification — 2026-11-06

Story: an admin manages the Arabic DOOJA dashboard; the mobile API and MVC share EF Core/SQLite, so saved changes and booking lifecycle actions are reflected across both surfaces.

## Evidence

- `dotnet build`: succeeded, 0 warnings / 0 errors.
- Release build also verified.
- `scripts/smoke.py`: **PASS: 93 HTTP checks, SQLite persistence, auth boundaries and Arabic MVC rendering** on a disposable Development database.
- Production checks: places return `[]` with demo seed disabled; both OTP endpoints return **503**, never accepting the Development code; unauthenticated bookings return **401**; login page returns **200** over local HTTPS.
- Final Development DB was created separately from test databases. It contains **12 places, 7 users, 10 bookings, 6 offers, 6 reviews, 3 reels, 5 comments, 10 notifications, 3 owner services and 1 closed slot**. No HTTP-test-created records were put in this final DB.
- The clean running host returns all p1–p12 from `/api/places`; the CSS, original logo and place image all return 200.

## Boundaries exercised

- Wrong, replayed and valid OTP codes; bearer authentication; customer versus owner access; cross-customer booking isolation; cross-owner modification denied.
- Place create/hide via antiforgery-protected MVC → public API readback.
- Offer create/toggle via MVC → API; offer-priced booking → SQLite counter update.
- Booking: server calculates total, rejects overlap/closed slot, owner accepts, records arrival and completes; completed cancellation rejected.
- Review creation requires a completed own booking; duplicate review rejected; admin reply persisted.
- Favorite/follow/like toggles, reel comments, notifications, owner services and closed slots.
- Admin cookie login; every MVC list/create/edit page renders HTML; writes without antiforgery return 400.

## Limits of verification

- HTML and HTTP flows were tested; no interactive browser/screenshot verification was performed.
- The Flutter repository was not modified and the Flutter binary was not run against this host.
- Seed examples are not real production activity. SMS, payment providers, push delivery, media uploads and deployment are not configured or claimed as verified.
- Test reports are about a single local host/SQLite database, not a load, penetration or distributed-concurrency audit.
