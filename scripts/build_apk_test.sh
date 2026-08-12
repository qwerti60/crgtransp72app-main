#!/usr/bin/env bash
# Новая тестовая APK → /api_test/ + новая MySQL.
# Установленные из сторов приложения продолжают ходить в /api/ + старая БД.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Сборка TEST APK (api_test / новая БД)…"
flutter build apk --release \
  --dart-define=CRG_API_ENV=prodTest \
  "$@"

OUT="build/app/outputs/flutter-apk"
echo ""
echo "Готово. Установите этот APK для проверки новой БД:"
ls -lh "$OUT"/app-*.apk 2>/dev/null || ls -lh "$OUT"/*.apk
echo ""
echo "Приложения из сторов НЕ затронуты — у них зашит /api/ (старая БД)."
