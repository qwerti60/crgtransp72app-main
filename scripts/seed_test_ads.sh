#!/usr/bin/env bash
# Схема users/ads + тестовые объявления с фото и документами в BLOB.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mysql --default-character-set=utf8mb4 -u root < "$ROOT/sql/migrate_admin_users_ads.sql"
php "$ROOT/scripts/seed_test_ads.php"

echo ""
echo "Тестовые данные загружены в crg_local."
echo "Админка: http://127.0.0.1:8080/admin-web/performer_ads.php?type=gp"
