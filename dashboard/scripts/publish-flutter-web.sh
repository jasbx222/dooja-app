#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
flutter build web --release --base-href /app/ --dart-define=API_BASE_URL=https://dooja.cloudapps.trade
DEST="$ROOT/dashboard/src/Dooja.Web/wwwroot/app"
rm -rf "$DEST"
mkdir -p "$DEST"
cp -a build/web/. "$DEST/"
echo "Published Flutter web → $DEST"
