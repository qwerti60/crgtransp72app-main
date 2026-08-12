#!/usr/bin/env bash
# Сборка zip с серверными файлами P2 для заливки на хост.
# Flutter APK/IPA не включаются — см. docs/deploy_p2_checklist.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="${1:-$(date +%Y%m%d)}"
OUT_DIR="$ROOT/dist"
STAGE="$OUT_DIR/p2_deploy_stage_$$"
ZIP_NAME="p2_deploy_${STAMP}.zip"
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
  sql/migrate_p2_features.sql

  api/include/ad_boost.php
  api/include/search_services_core.php
  api/include/admin_stats.php
  api/include/admin_users.php
  api/include/deal_push.php

  api/get_boost_tariffs.php
  api/apply_ad_boost.php
  api/get_customer_ad_templates.php
  api/duplicate_customer_ad.php
  api/update_order_transit.php
  api/getuserinfo.php
  api/get_order_global_info.php
  api/update_order_status.php

  api/admin-web/boost_tariffs.php
  api/admin-web/bootstrap_web.php
  api/admin-web/stats.php
  api/admin-web/user_edit.php

  docs/deploy_p2_checklist.md
  docs/deploy_admin_host.md
  docs/portfolio/feature_proposals_estimate.html
  docs/portfolio/README.md
)

for f in "${FILES[@]}"; do
  copy_one "$f"
done

cat > "$STAGE/README_DEPLOY.txt" <<EOF
P2 deploy package — Грузоперевозки72
Stamp: ${STAMP}

Предусловие: P1 уже на prod (docs/deploy_p1_checklist.md).

1) Backup production DB.
2) Apply migration (from this archive root):
   mysql --default-character-set=utf8mb4 -u USER -p DB < sql/migrate_p2_features.sql
3) Upload api/ over existing api/ (do NOT overwrite databd.php / service_account.json).
4) Follow docs/deploy_p2_checklist.md

Flutter app must be rebuilt separately:
  onboarding, ad boost, ad templates, in-transit UI.
EOF

rm -f "$ZIP_PATH"
(
  cd "$STAGE"
  zip -r "$ZIP_PATH" . -x '*.DS_Store'
)

rm -rf "$STAGE"
ls -lh "$ZIP_PATH"
echo "OK: $ZIP_PATH"
