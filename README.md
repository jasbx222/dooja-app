# ضوجة (DOOJA)

Flutter app + ASP.NET Core MVC dashboard/API (monorepo).

- App: Flutter sources at repo root (`lib/`)
- Dashboard + API: [`dashboard/`](dashboard/)
- Windows + Cloudflare Tunnel + Postgres setup: [`docs/WINDOWS-SETUP.ar.md`](docs/WINDOWS-SETUP.ar.md)
- Flutter API wiring: [`API_WIRING.md`](API_WIRING.md)

Public API/dashboard URL (after tunnel is up on your PC): https://dooja.cloudapps.trade

```bash
# Dashboard (dev SQLite)
export PATH="$HOME/.dotnet:$PATH"
cd dashboard && dotnet run --project src/Dooja.Web --urls http://127.0.0.1:5080

# Flutter against local API
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:5080

# Flutter against production tunnel
flutter run --dart-define=API_BASE_URL=https://dooja.cloudapps.trade
```
