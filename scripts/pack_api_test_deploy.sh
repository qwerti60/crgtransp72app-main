#!/usr/bin/env bash
# Сборка каталога api_test для выкладки рядом с prod /api/ на хостинге.
# Отдельная папка + отдельная MySQL (см. docs/deploy_api_test.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="${1:-$(date +%Y%m%d)}"
OUT_DIR="$ROOT/dist"
STAGE="$OUT_DIR/api_test_deploy_stage_$$"
ZIP_NAME="api_test_deploy_${STAMP}.zip"
ZIP_PATH="$OUT_DIR/$ZIP_NAME"

mkdir -p "$OUT_DIR"
rm -rf "$STAGE"
mkdir -p "$STAGE/api_test"

echo "→ Копирую api/ → api_test/ (без секретов)…"
rsync -a \
  --exclude '.DS_Store' \
  --exclude '.tmp' \
  --exclude 'databd.php' \
  --exclude 'databd.local.php' \
  --exclude 'databd.prod.php' \
  --exclude 'mail.local.php' \
  --exclude 'payment.local.php' \
  --exclude 'service_account.json' \
  --exclude 'cron/cron_key.php' \
  --exclude 'uploads/' \
  "$ROOT/api/" "$STAGE/api_test/"

# Шаблон БД для стенда
cp "$ROOT/api/databd.test.example.php" "$STAGE/api_test/databd.php.example"

# Явный префикс (на случай нестандартного пути на хосте)
cat > "$STAGE/api_test/api_prefix.local.php" << 'EOF'
<?php
return '/api_test';
EOF

cat > "$STAGE/README_DEPLOY_API_TEST.txt" << 'EOF'
Стенд api_test — отдельная папка API + отдельная MySQL
======================================================

URL приложения (тест):
  http://gruzoperevozki72.ru/api_test/
Админка теста:
  http://gruzoperevozki72.ru/api_test/admin-web/login.php

Prod НЕ трогаем:
  /api/  +  БД u2395188_apps

Шаги на хостинге
----------------
1) В панели MySQL создайте БД и пользователя, например:
     БД:   u2395188_apps_test
     USER: u2395188_apps_test
     (или свои имена)

2) Импорт схемы/данных в ТЕСТОВУЮ БД (не в prod!):
     - чистая: sql/local_dev.sql + нужные migrate_*.sql
     - или копия с prod (mysqldump prod → import в test)

3) Распакуйте архив в корень сайта (рядом с папкой api/):
     unzip api_test_deploy_YYYYMMDD.zip
     → появится папка api_test/

4) Создайте api_test/databd.php из databd.php.example:
     cp api_test/databd.php.example api_test/databd.php
     # пропишите host/user/password/dbname тестовой БД

5) Скопируйте FCM (если нужны push на стенде):
     cp api/service_account.json api_test/service_account.json

6) Почта для регистрации / сброса пароля:
     # либо свой файл:
     cp api/mail.local.php api_test/mail.local.php
     # либо достаточно боевого api/mail.local.php рядом —
     # api_test подхватит его автоматически (mail_config.php)

6b) Оплата / отмена подписки (payment-proxy):
     # секреты банка:
     cp api/payment.local.php api_test/payment.local.php
     # если на prod старый монолитный proxy без payment.local.php:
     cp api/payment-proxy.php api_test/payment-proxy.php
     # проверка: POST на …/api_test/payment-proxy.php не должен давать HTML 404

7) В приложении Flutter:
     lib/config.dart → ApiEnv.prodTest / ./scripts/build_apk_test.sh
     пересоберите APK

Проверка
--------
  curl -sS "http://gruzoperevozki72.ru/api_test/cities.php" | head
  curl -sS "http://gruzoperevozki72.ru/api/cities.php" | head   # prod без изменений
EOF

# Полезные SQL рядом
mkdir -p "$STAGE/sql"
for f in local_dev.sql migrate_admin_accounts.sql migrate_admin_password_reset.sql \
         migrate_subscription_payment_log.sql migrate_p1_features.sql \
         migrate_p2_features.sql migrate_p3_features.sql \
         migrate_city_geo.sql migrate_subscription_packages.sql; do
  if [[ -f "$ROOT/sql/$f" ]]; then
    cp "$ROOT/sql/$f" "$STAGE/sql/"
  fi
done
cp "$ROOT/docs/deploy_api_test.md" "$STAGE/" 2>/dev/null || true

rm -f "$ZIP_PATH"
(
  cd "$STAGE"
  zip -r "$ZIP_PATH" . -x '*.DS_Store'
)
rm -rf "$STAGE"

echo ""
echo "Готово: $ZIP_PATH"
ls -lh "$ZIP_PATH"
