#!/usr/bin/env bash
# Съёмка скриншотов на Codemagic (iOS Simulator) + ресайз под App Store / Google Play.
# Вызывается из workflow store-screenshots в codemagic.yaml.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RAW_DIR="$ROOT/store_assets/screenshots/_raw/iphone"
mkdir -p "$RAW_DIR"

echo "=== Available simulators ==="
xcrun simctl list devices available || true
echo "=== Flutter devices (before boot) ==="
flutter devices || true

# Выбираем UDID доступного iPhone (JSON от simctl — надёжнее имени).
# Предпочитаем Pro Max / Plus, иначе любой iPhone.
resolve_udid() {
  python3 - <<'PY'
import json, subprocess, sys

preferred = [
    "iPhone 16 Pro Max",
    "iPhone 17 Pro Max",
    "iPhone 15 Pro Max",
    "iPhone 16 Plus",
    "iPhone 16 Pro",
    "iPhone 17 Pro",
    "iPhone 16",
    "iPhone 15 Pro",
    "iPhone 15",
]

raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"], text=True)
data = json.loads(raw)

# name -> [(udid, runtime)]
by_name = {}
for runtime, devices in data.get("devices", {}).items():
    if "iOS" not in runtime and "iphoneos" not in runtime.lower():
        # всё равно берём — на CI runtime ключ вида com.apple.CoreSimulator.SimRuntime.iOS-18-3
        pass
    for d in devices:
        if d.get("isAvailable") is False:
            continue
        name = d.get("name") or ""
        udid = d.get("udid") or ""
        if not name.startswith("iPhone") or not udid:
            continue
        by_name.setdefault(name, []).append(udid)

# 1) точное совпадение из env
env_name = __import__("os").environ.get("IOS_PHONE_DEVICE", "").strip()
if env_name and env_name in by_name:
    print(by_name[env_name][0])
    print(env_name, file=sys.stderr)
    sys.exit(0)

# 2) предпочтительные имена
for name in preferred:
    if name in by_name:
        print(by_name[name][0])
        print(name, file=sys.stderr)
        sys.exit(0)

# 3) любой iPhone (сначала с Pro Max / Plus в имени)
ranked = sorted(
    by_name.items(),
    key=lambda kv: (
        0 if "Pro Max" in kv[0] else 1 if "Plus" in kv[0] else 2 if "Pro" in kv[0] else 3,
        kv[0],
    ),
)
if not ranked:
    sys.exit(1)
name, udids = ranked[0]
print(udids[0])
print(name, file=sys.stderr)
PY
}

set +e
UDID_AND_ERR="$(resolve_udid 2>/tmp/sim_name.txt)"
RC=$?
set -e
DEVICE_NAME="$(cat /tmp/sim_name.txt 2>/dev/null || true)"
UDID="$(echo "$UDID_AND_ERR" | head -1 | tr -d '[:space:]')"

if [[ $RC -ne 0 || -z "$UDID" ]]; then
  echo "ERROR: no available iPhone simulator found"
  xcrun simctl list devices available || true
  exit 1
fi

echo "Using simulator: ${DEVICE_NAME:-unknown} (UDID=$UDID)"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
# Flutter часто не видит симулятор, пока не открыт Simulator.app
open -a Simulator || true
sleep 3

echo "=== Flutter devices (after boot) ==="
# Важно: список устройств Flutter часто пишет в stderr — не глушим его.
flutter devices 2>&1 | tee /tmp/flutter_devices.txt || true

# Ждём появления UDID в выводе (stdout+stderr), без ложного fail.
if ! grep -qi "$UDID" /tmp/flutter_devices.txt; then
  echo "Waiting for Flutter to list simulator $UDID..."
  for i in $(seq 1 15); do
    sleep 2
    flutter devices 2>&1 | tee /tmp/flutter_devices.txt || true
    if grep -qi "$UDID" /tmp/flutter_devices.txt; then
      echo "Simulator visible after ${i}x2s"
      break
    fi
  done
fi

if ! grep -qi "$UDID" /tmp/flutter_devices.txt; then
  echo "ERROR: Flutter still cannot see simulator $UDID"
  cat /tmp/flutter_devices.txt || true
  exit 148
fi

echo "OK: Flutter sees $UDID — continuing"

flutter pub get
(
  cd ios
  export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  pod install
)

echo "=== Capture screenshots via flutter drive -d $UDID ==="
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/store_screenshots_test.dart \
  -d "$UDID"

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
