#!/usr/bin/env bash
# Съёмка скриншотов на Codemagic (iOS Simulator) + ресайз под App Store / Google Play.
# Вызывается из workflow store-screenshots в codemagic.yaml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RAW_DIR="$ROOT/store_assets/screenshots/_raw/iphone"
mkdir -p "$RAW_DIR"

pick_simulator() {
  local preferred="${1:-}"
  if [[ -n "$preferred" ]] && xcrun simctl list devices available | grep -q "$preferred"; then
    echo "$preferred"
    return
  fi
  # Предпочитаем Pro Max / Plus (большие экраны для стора)
  local candidates=(
    "iPhone 16 Pro Max"
    "iPhone 15 Pro Max"
    "iPhone 16 Plus"
    "iPhone 16 Pro"
    "iPhone 16"
    "iPhone 15 Pro"
    "iPhone 15"
  )
  for name in "${candidates[@]}"; do
    if xcrun simctl list devices available | grep -q "$name"; then
      echo "$name"
      return
    fi
  done
  # Любой доступный iPhone
  xcrun simctl list devices available | sed -n 's/.*\(iPhone [^()]*(.*)\) (.*/\1/p' | head -1 | sed 's/ (.*//'
}

DEVICE="${IOS_PHONE_DEVICE:-}"
if [[ -z "$DEVICE" ]]; then
  DEVICE="$(pick_simulator)"
fi
if [[ -z "$DEVICE" ]]; then
  echo "ERROR: no iPhone simulator available"
  xcrun simctl list devices available || true
  exit 1
fi

echo "Using simulator: $DEVICE"
xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b

# UDID для flutter -d
UDID="$(xcrun simctl list devices booted | grep "$DEVICE" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' | head -1)"
if [[ -z "$UDID" ]]; then
  UDID="$DEVICE"
fi
echo "Flutter device: $UDID"

flutter pub get
(
  cd ios
  export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  pod install
)

echo "=== Capture screenshots via flutter drive ==="
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart \
  -d "$UDID" \
  --reporter expanded

# Fallback: если драйвер положил файлы в другое место
if ! ls "$RAW_DIR"/*.png >/dev/null 2>&1; then
  echo "Looking for screenshots under build/..."
  found="$(find "$ROOT/build" -type d -name 'integration_test_screenshots' 2>/dev/null | head -1 || true)"
  if [[ -n "$found" ]]; then
    cp -f "$found"/*.png "$RAW_DIR/" 2>/dev/null || true
  fi
fi

if ! ls "$RAW_DIR"/*.png >/dev/null 2>&1; then
  echo "ERROR: no PNG screenshots captured"
  find "$ROOT" -name '*.png' -path '*screenshot*' 2>/dev/null | head -40 || true
  exit 1
fi

echo "Raw screenshots:"
ls -la "$RAW_DIR"

echo "=== Resize for App Store / Google Play ==="
"$ROOT/scripts/generate_store_screenshots.sh" --resize-only

echo "Done. Artifacts under store_assets/screenshots/"
find "$ROOT/store_assets/screenshots" -name '*.png' | sort
