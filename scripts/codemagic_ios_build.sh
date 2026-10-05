#!/usr/bin/env bash
# Сборка IPA для Codemagic. Версия: IOS_BUILD_* из UI/yaml, иначе pubspec.yaml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

V=$(grep '^version:' pubspec.yaml | awk '{print $2}')
PUB_NAME="${V%%+*}"
PUB_NUMBER="${V#*+}"

BUILD_NAME="${IOS_BUILD_NAME:-$PUB_NAME}"
BUILD_NUMBER="${IOS_BUILD_NUMBER:-$PUB_NUMBER}"

echo "pubspec.yaml: $V"
echo "Using BUILD_NAME=$BUILD_NAME BUILD_NUMBER=$BUILD_NUMBER"
if [ -n "${IOS_BUILD_NUMBER:-}" ]; then
  echo "(IOS_BUILD_NUMBER задан в Codemagic — переопределяет pubspec)"
fi

if [ -z "$BUILD_NUMBER" ] || ! [[ "$BUILD_NUMBER" =~ ^[0-9]+$ ]]; then
  echo "ERROR: invalid BUILD_NUMBER: '$BUILD_NUMBER'"
  exit 1
fi
if [ "$BUILD_NUMBER" -le 35 ]; then
  echo "ERROR: BUILD_NUMBER must be > 35 (уже загружен в App Store Connect)."
  echo "Задайте в Codemagic Environment variables: IOS_BUILD_NUMBER=50 (или выше)"
  echo "Либо push pubspec.yaml с version: 6.0.9+50"
  exit 1
fi

flutter build ios --config-only --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER"

echo "=== Generated.xcconfig ==="
grep -E 'FLUTTER_BUILD_(NAME|NUMBER)' ios/Flutter/Generated.xcconfig

GEN_NUM=$(grep '^FLUTTER_BUILD_NUMBER=' ios/Flutter/Generated.xcconfig | cut -d= -f2)
if [ "$GEN_NUM" != "$BUILD_NUMBER" ]; then
  echo "ERROR: Generated.xcconfig FLUTTER_BUILD_NUMBER=$GEN_NUM, expected $BUILD_NUMBER"
  exit 1
fi

EXPORT_PLIST="${1:-/Users/builder/export_options.plist}"
set -o pipefail
if ! flutter build ipa \
  --release \
  -t lib/main.dart \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist="$EXPORT_PLIST" \
  --verbose 2>&1 | tee /tmp/flutter_build_ipa.log; then
  echo "=== flutter build ipa failed (last 120 lines) ==="
  tail -120 /tmp/flutter_build_ipa.log 2>/dev/null || true
  exit 1
fi

IPA=$(find build/ios/ipa -name '*.ipa' | head -1)
if [ -z "$IPA" ]; then
  echo "ERROR: IPA not found"
  exit 1
fi

BUILT_VER=$(unzip -p "$IPA" "Payload/Runner.app/Info.plist" | plutil -extract CFBundleVersion raw -)
BUILT_NAME=$(unzip -p "$IPA" "Payload/Runner.app/Info.plist" | plutil -extract CFBundleShortVersionString raw -)
echo "IPA version: $BUILT_NAME ($BUILT_VER)"

if [ "$BUILT_VER" -le 35 ]; then
  echo "ERROR: IPA CFBundleVersion=$BUILT_VER — сборка всё ещё 35."
  echo "Codemagic, скорее всего, не использует codemagic.yaml из репозитория."
  echo "Settings → Build → выберите конфигурацию из codemagic.yaml"
  exit 1
fi

echo "OK: IPA ready for upload ($BUILT_NAME / $BUILT_VER)"
