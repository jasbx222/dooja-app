# Dooja production readiness report

Date: 2026-11-12

## Overall status

**READY WITH EXTERNAL REQUIREMENTS**

The supported customer and admin flows are in place. Launch still needs a new empty production database, `Jwt__Key`, `Admin__Password`, `Seed__Demo=false`, and a deploy of this build. The live tunnel was not changed.

SMS OTP, online payments, and Reels are intentionally disabled. They are not launch blockers and they were not implemented in this pass.

## Component status

| Component | Status | What was checked |
| --- | --- | --- |
| Flutter application | Supported screens are wired to the API | `dart analyze` clean. `flutter test` passed, 6 tests. Release web opens on the intro, then login. |
| Admin dashboard | Ready | Playwright opened `/Auth/Login`: Arabic, RTL, phone and password fields, no demo number in the placeholder. Earlier smoke on a disposable database covered places, bookings, offers, users, and reviews. That smoke was not repeated this pass. |
| Backend API | Ready for supported actions | `dotnet build` succeeded, 0 warnings. Price, availability, booking status, and pay method stay on the server. |
| Database | Ready for a new empty database | `EnsureCreated` builds the schema on first start. Demo rows are inserted only in Development. There is no EF migration history. Do not point Production at the development file. |
| Security | Suitable for the supported surface | Production OTP returns 503 and does not accept `1234`. Demo phones `07700000000`–`07700000006` are rejected outside Development. Admin cookie is `Secure` outside Development. Auth is rate-limited. No new critical issue was found. A full dependency and penetration test was not run. |
| Booking system | Cash bookings are enforced on the server | Only `كاش بالمكان` is accepted. Card and Zain Cash return 400. Overlap uses a serializable transaction. A new customer cannot reach booking while phone verification is paused. |
| Flutter web | Current in this repository | Release build copied to `dashboard/src/Dooja.Web/wwwroot/app` with `<base href="/app/">` and `https://dooja.cloudapps.trade`. |
| Deployment | Not performed | Domain, tunnel, and the running host were left unchanged. |

## Disabled services

| Service | Status |
| --- | --- |
| SMS OTP | Intentionally disabled. The release app does not request a code. Production returns 503. Development can still request `1234` from the login screen for local work. |
| Online payments | Intentionally disabled. Cash at the venue is the only accepted method. |
| Reels | Intentionally disabled. The app shows «قريباً». Production reads return an empty list and writes return 503. |

## Create account

After the intro, the customer reaches **إنشاء حساب**. The page asks for a name and an Iraqi mobile number. Submitting it does not create a user and does not send a code. It explains that phone verification is temporarily paused.

The login screen in the release build says **تسجيل الدخول بالرمز متوقف مؤقتاً** and links to **ما عندك حساب؟ أنشئ حساب**. Apple and Google remain «قريباً».

The admin dashboard can still create a user record from المستخدمون. That record cannot sign in to the app until phone verification returns.

## Remaining blockers

These affect supported operations:

1. Deploy this build, including `wwwroot/app`. The copy in the repository is current. The live host was not updated.
2. Use a new empty production database. Do not copy the development SQLite file.
3. Set `ASPNETCORE_ENVIRONMENT=Production`, a `Jwt__Key` of at least 32 bytes, `Admin__Password`, and `Seed__Demo=false` before the first production start.
4. Keep a backup of the host database before the switch. There is no automated backup job in the repository.

Not blockers: SMS OTP, card payments, Zain Cash, and Reels.

`EnsureCreated` is enough for a new database. Adding EF migrations now would risk an existing database that was created without a migration history, so migrations were not introduced.

## Verification

| Check | Result |
| --- | --- |
| `dart analyze lib/screens/auth.dart test/empty_screens_test.dart` | Passed. |
| `flutter test` through the Windows short path | Passed. All 6 tests, including the create-account screen. |
| `flutter test` on the normal `C:\Users\Acer 5` path | Blocked by the `objective_c` hook, which splits the path on the space. |
| `flutter build web --release --base-href /app/ --dart-define=API_BASE_URL=https://dooja.cloudapps.trade` | Passed. Copied into `wwwroot/app`. The script contains `cloudapps.trade`. |
| `dotnet build` | Passed. 0 warnings, 0 errors. |
| `dotnet test` | No test project exists. |
| `npm` lint and build | Not applicable. The dashboard is Razor. |
| Playwright, `http://127.0.0.1:5093/app/` | The release app opened. Intro screen rendered in Arabic. Login showed the paused-code message and the create-account link. Flutter controls are not normal HTML buttons, so the form itself was confirmed by the widget test rather than by a second browser tap. |
| Playwright, `/Auth/Login` | Arabic RTL admin login rendered. Placeholder is `07xxxxxxxxx`. |
| Browser console on the local app | Two CORS errors. The release build calls `https://dooja.cloudapps.trade`, and that host does not allow `http://127.0.0.1:5093`. Same-origin use on `https://dooja.cloudapps.trade/app/` is the production case. |
| Full API smoke and a parallel double-booking test | Not repeated this pass. The previous disposable-database smoke passed 93 checks, and a card payment returned 400. |
| Live tunnel, device, and store upload | Not executed. |

## Final decision

1. **Can real customers open the application?** Yes. The release web app opens to the intro and then account or login.
2. **Can customers browse real places and offers?** The catalog comes from the API. A new customer stops on the account page while phone verification is paused, so they do not reach the home feed yet.
3. **Can customers create cash bookings?** The server accepts cash bookings for an authenticated customer and rejects other payment methods. A new customer cannot sign in while verification is paused.
4. **Can administrators manage supported operations?** Yes. Admin login is separate from SMS, and the management pages persist to the database.
5. **Is the backend secure enough for production?** Yes for the supported surface: no production OTP bypass, ownership checks on customer and owner data, server-side price and payment rules, and an admin-only dashboard.
6. **Is the database ready for real customer data?** Yes when Production starts on a new empty database. The development file is not ready to reuse.
7. **Is the Flutter web version in this repository current?** Yes. The live host was not updated.
8. **Are there remaining critical or high-severity issues in supported functionality?** No code defect at that level. The remaining work is the empty database, production secrets, backup, and deploying this build.
