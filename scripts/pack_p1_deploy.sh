#!/usr/bin/env bash
# Сборка zip с серверными файлами P1 для заливки на хост.
# Flutter APK/IPA не включаются — см. docs/deploy_p1_checklist.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="${1:-$(date +%Y%m%d)}"
OUT_DIR="$ROOT/dist"
STAGE="$OUT_DIR/p1_deploy_stage_$$"
ZIP_NAME="p1_deploy_${STAMP}.zip"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"

mkdir -p "$OUT_DIR"
rm -rf "$STAGE"
mkdir -p "$STAGE"

copy_one() {
  local rel="$1"
  local src="$ROOT/$rel"
  if [[ ! -e "$src" ]]; then
    echo "WARN: missing $rel" >&2
    return 0
  fi
  mkdir -p "$STAGE/$(dirname "$rel")"
  cp -a "$src" "$STAGE/$rel"
}

FILES=(
  # SQL
  sql/migrate_city_geo.sql
  sql/migrate_subscription_packages.sql

  # Include
  api/include/search_services_core.php
  api/include/admin_cities.php
  api/include/admin_support.php
  api/include/chat_core.php
  api/include/deal_push.php
  api/include/subscription_packages.php
  api/include/performer_finances.php
  api/include/fcm_push.php

  # API
  api/add_offer.php
  api/add_offerzakaz.php
  api/updatePriemZak.php
  api/update_subscription.php
  api/get_subscription_config.php
  api/get_subscription_packages.php
  api/validate_promo.php
  api/search_services.php
  api/cron/subscription_reminders.php

  # Admin-web
  api/admin-web/bootstrap_web.php
  api/admin-web/cities.php
  api/admin-web/city_edit.php
  api/admin-web/city_new.php
  api/admin-web/support_queue.php
  api/admin-web/support_view.php
  api/admin-web/deal_chat_view.php
  api/admin-web/packages.php
  api/admin-web/promo_codes.php

  # Docs
  docs/deploy_p1_checklist.md
  docs/deploy_admin_host.md
  docs/search_logic_ru.md
  docs/chat_logic_ru.md
  docs/portfolio/feature_proposals_estimate.html
)

for f in "${FILES[@]}"; do
  copy_one "$f"
done

cat > "$STAGE/README_DEPLOY.txt" <<EOF
P1 deploy package — Грузоперевозки72
Stamp: ${STAMP}

1) Backup production DB.
2) Apply migrations (from this archive root):
   mysql ... < sql/migrate_city_geo.sql
   mysql ... < sql/migrate_subscription_packages.sql
3) Upload api/ over existing api/ (do NOT overwrite databd.php / service_account.json).
4) Configure cron for api/cron/subscription_reminders.php
5) Follow docs/deploy_p1_checklist.md

Flutter app must be rebuilt separately (geolocator + UI changes).
EOF

rm -f "$ZIP_PATH"
(
  cd "$STAGE"
  zip -r "$ZIP_PATH" . -x '*.DS_Store'
)

rm -rf "$STAGE"
ls -lh "$ZIP_PATH"
echo "OK: $ZIP_PATH"
