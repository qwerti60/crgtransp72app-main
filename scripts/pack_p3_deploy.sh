#!/usr/bin/env bash
# Сборка zip с серверными файлами P3 для заливки на хост.
# Flutter APK/IPA не включаются — см. docs/deploy_p3_checklist.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="${1:-$(date +%Y%m%d)}"
OUT_DIR="$ROOT/dist"
STAGE="$OUT_DIR/p3_deploy_stage_$$"
ZIP_NAME="p3_deploy_${STAMP}.zip"
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
  sql/migrate_p3_features.sql

  api/include/ad_auto_moderation.php
  api/include/subscription_invoices.php
  api/include/admin_export.php
  api/include/performer_finances.php

  api/add_ob_gp.php
  api/add_ob_vidt.php
  api/add_ob_gr.php

  api/request_subscription_invoice.php
  api/get_subscription_invoices.php
  api/getuserinfo.php

  api/admin-web/bootstrap_web.php
  api/admin-web/moderation.php
  api/admin-web/invoices.php
  api/admin-web/export.php

  docs/deploy_p3_checklist.md
  docs/deploy_admin_host.md
  docs/portfolio/feature_proposals_estimate.html
  docs/portfolio/README.md
)

for f in "${FILES[@]}"; do
  copy_one "$f"
done

cat > "$STAGE/README_DEPLOY.txt" <<EOF
P3 deploy package — Грузоперевозки72
Stamp: ${STAMP}

Предусловие: P1 и P2 уже на prod (docs/deploy_p1_checklist.md, docs/deploy_p2_checklist.md).

1) Backup production DB.
2) Apply migration (from this archive root):
   mysql --default-character-set=utf8mb4 -u USER -p DB < sql/migrate_p3_features.sql
3) Upload api/ over existing api/ (do NOT overwrite databd.php / service_account.json).
4) Follow docs/deploy_p3_checklist.md

Flutter app must be rebuilt separately:
  B2B invoice button on PaymentPage (юр. лица).
EOF

rm -f "$ZIP_PATH"
(
  cd "$STAGE"
  zip -r "$ZIP_PATH" . -x '*.DS_Store'
)

rm -rf "$STAGE"
ls -lh "$ZIP_PATH"
echo "OK: $ZIP_PATH"
