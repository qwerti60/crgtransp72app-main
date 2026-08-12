#!/usr/bin/env bash
# Релиз для сторов → /api/ + старая MySQL (как у уже установленных приложений).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Сборка STORE (api / старая БД)…"
MODE="${1:-apk}"
shift || true

case "$MODE" in
  apk)
    flutter build apk --release --dart-define=CRG_API_ENV=prod "$@"
    ls -lh build/app/outputs/flutter-apk/*.apk
    ;;
  aab|appbundle)
    flutter build appbundle --release --dart-define=CRG_API_ENV=prod "$@"
    ls -lh build/app/outputs/bundle/release/*.aab
    ;;
  *)
    echo "Usage: $0 [apk|aab]"
    exit 1
    ;;
esac
