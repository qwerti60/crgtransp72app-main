#!/usr/bin/env bash
# Съёмка и ресайз скриншотов для App Store Connect и Google Play Console.
# Требования: macOS, Xcode Simulator, Flutter, sips (встроен в macOS).
#
# Использование:
#   ./scripts/generate_store_screenshots.sh              # iOS Simulator (по умолчанию)
#   ./scripts/generate_store_screenshots.sh --headless   # без сборки iOS (быстрее, но без сети)
#   ./scripts/generate_store_screenshots.sh --ios-only
#   ./scripts/generate_store_screenshots.sh --resize-only
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

IOS_PHONE_DEVICE="${IOS_PHONE_DEVICE:-iPhone 16 Pro Max}"
IOS_TABLET_DEVICE="${IOS_TABLET_DEVICE:-iPad Pro 13-inch (M4)}"
OUT_BASE="$ROOT/store_assets/screenshots"
RAW_DIR="$OUT_BASE/_raw"
IOS_OUT="$OUT_BASE/ios"
ANDROID_OUT="$OUT_BASE/google_play"

IOS_ONLY=false
RESIZE_ONLY=false
USE_SIMULATOR=false
for arg in "$@"; do
  case "$arg" in
    --ios-only) IOS_ONLY=true ;;
    --resize-only) RESIZE_ONLY=true ;;
    --simulator) USE_SIMULATOR=true ;;
    --headless) USE_SIMULATOR=false ;;
  esac
done

mkdir -p "$RAW_DIR" "$IOS_OUT" "$ANDROID_OUT"

resize_one() {
  local src="$1"
  local width="$2"
  local height="$3"
  local dest="$4"
  mkdir -p "$(dirname "$dest")"
  sips -z "$height" "$width" "$src" --out "$dest" >/dev/null
  echo "  -> $(basename "$(dirname "$dest")")/$(basename "$dest") (${width}x${height})"
}

process_screenshot_set() {
  local platform_dir="$1"
  local src_file="$2"
  local base_name="$3"

  if [[ ! -f "$src_file" ]]; then
    echo "  пропуск (нет файла): $src_file"
    return
  fi

  echo "Ресайз: $base_name"

  # --- App Store (iOS) ---
  resize_one "$src_file" 1320 2868 "$IOS_OUT/iphone-69/$base_name.png"
  resize_one "$src_file" 1290 2796 "$IOS_OUT/iphone-67/$base_name.png"
  resize_one "$src_file" 1284 2778 "$IOS_OUT/iphone-65/$base_name.png"
  resize_one "$src_file" 1242 2208 "$IOS_OUT/iphone-55/$base_name.png"
  resize_one "$src_file" 2048 2732 "$IOS_OUT/ipad-129/$base_name.png"
  resize_one "$src_file" 1668 2388 "$IOS_OUT/ipad-11/$base_name.png"

  # --- Google Play ---
  resize_one "$src_file" 1080 1920 "$ANDROID_OUT/phone/$base_name.png"
  resize_one "$src_file" 1440 2560 "$ANDROID_OUT/phone-xxhdpi/$base_name.png"
  resize_one "$src_file" 1200 1920 "$ANDROID_OUT/tablet-7/$base_name.png"
  resize_one "$src_file" 1600 2560 "$ANDROID_OUT/tablet-10/$base_name.png"
}

collect_from_build() {
  local device_label="$1"
  local dest_subdir="$2"
  local build_glob="$ROOT/build"

  local found=""
  while IFS= read -r -d '' dir; do
    found="$dir"
  done < <(find "$build_glob" -type d -name 'integration_test_screenshots' -print0 2>/dev/null | head -z -n 1)

  if [[ -z "$found" && -d "$build_glob/integration_test_screenshots" ]]; then
    found="$build_glob/integration_test_screenshots"
  fi

  if [[ -z "$found" ]]; then
    found="$(find "$build_glob" -type d -name 'integration_test_screenshots' 2>/dev/null | head -1 || true)"
  fi

  if [[ -z "$found" || ! -d "$found" ]]; then
    echo "Не найден каталог integration_test_screenshots после прогона на $device_label"
    return 1
  fi

  echo "Копирование из $found -> $RAW_DIR/$dest_subdir"
  mkdir -p "$RAW_DIR/$dest_subdir"
  cp -f "$found"/*.png "$RAW_DIR/$dest_subdir/" 2>/dev/null || true
}

run_on_simulator() {
  local device="$1"
  local tag="$2"

  echo ""
  echo "=== Simulator: $device ($tag) ==="
  xcrun simctl boot "$device" 2>/dev/null || true
  xcrun simctl bootstatus "$device" -b

  flutter test integration_test/store_screenshots_test.dart \
    -d "$device" \
    --reporter expanded

  collect_from_build "$device" "$tag" || true

  # Flutter 3.x: скриншоты могут лежать рядом с device id
  local alt_dir
  alt_dir="$(find "$ROOT/build" -path '*integration_test_screenshots*' -type d 2>/dev/null | head -1 || true)"
  if [[ -n "$alt_dir" && -d "$alt_dir" ]]; then
    mkdir -p "$RAW_DIR/$tag"
    cp -f "$alt_dir"/*.png "$RAW_DIR/$tag/" 2>/dev/null || true
  fi
}

run_headless() {
  echo ""
  echo "=== Headless render (ImageMagick) ==="
  python3 "$ROOT/scripts/render_store_screenshots.py"
}

if [[ "$RESIZE_ONLY" == false ]]; then
  echo "flutter pub get..."
  export TMPDIR="${TMPDIR:-$ROOT/android/.tmp}"
  mkdir -p "$TMPDIR"
  flutter pub get

  if [[ "$USE_SIMULATOR" == true ]]; then
    run_on_simulator "$IOS_PHONE_DEVICE" "iphone"
    if [[ "$IOS_ONLY" == false ]]; then
      run_on_simulator "$IOS_TABLET_DEVICE" "ipad"
    fi
  else
    run_headless
  fi
fi

echo ""
echo "=== Ресайз под все размеры магазинов ==="

shopt -s nullglob
for src in "$RAW_DIR"/iphone/*.png; do
  base="$(basename "$src" .png)"
  process_screenshot_set "iphone" "$src" "$base"
done

# Если есть отдельные iPad-исходники — используем их для iPad-папок (лучше качество)
for src in "$RAW_DIR"/ipad/*.png; do
  base="$(basename "$src" .png)"
  if [[ -f "$src" ]]; then
    echo "iPad master: $base"
    resize_one "$src" 2048 2732 "$IOS_OUT/ipad-129/$base.png"
    resize_one "$src" 1668 2388 "$IOS_OUT/ipad-11/$base.png"
    resize_one "$src" 1200 1920 "$ANDROID_OUT/tablet-7/$base.png"
    resize_one "$src" 1600 2560 "$ANDROID_OUT/tablet-10/$base.png"
  fi
done

echo ""
echo "Готово. Файлы:"
echo "  iOS (App Store):     $IOS_OUT"
echo "  Android (Play):      $ANDROID_OUT"
echo "  Исходники симулятора: $RAW_DIR"
echo ""
echo "Документация: docs/store_screenshots_ru.md"
