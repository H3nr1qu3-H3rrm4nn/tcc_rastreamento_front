#!/usr/bin/env bash
set -euo pipefail

: "${API_BASE_URL:?Missing API_BASE_URL environment variable}"
: "${GOOGLE_MAPS_API_KEY:?Missing GOOGLE_MAPS_API_KEY environment variable}"

flutter config --enable-web >/dev/null
flutter pub get >/dev/null

flutter build web --release \
  --dart-define=API_BASE_URL="${API_BASE_URL}" \
  --dart-define=GOOGLE_MAPS_API_KEY="${GOOGLE_MAPS_API_KEY}"

cd build/web
python3 -m http.server "${PORT:-8080}"
