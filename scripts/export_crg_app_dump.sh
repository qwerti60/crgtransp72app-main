#!/usr/bin/env bash
# Дамп БД приложения + админки без legacy-таблиц (catalog, news, usersadmin и т.д.)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DB="${1:-crg_local}"
OUT="${2:-$ROOT/sql/crg_app_deploy.sql}"

TABLES=(
  admin_accounts
  admin_password_reset_otp
  cities
  vidt
  vidg
  vidkuzov
  gruzchik
  gruz_info
  users
  subscriptions
  subscription_config
  add_ob_gp
  add_ob_vidt
  add_ob_gr
  orders
  orderst
  ordersg
  offer_data
  offer_dataf
  reviews
  reviewsisp
)

{
  echo "-- CRG Transp72: дамп для замены данных приложения и админки"
  echo "-- БД-источник: ${DB}"
  echo "-- Сгенерировано: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "-- Таблицы: ${TABLES[*]}"
  echo "-- Legacy-таблицы сайта (catalog, news, message_*, temp_users, usersadmin…) НЕ включены."
  echo ""
  echo "SET NAMES utf8mb4;"
  echo "SET FOREIGN_KEY_CHECKS=0;"
  echo ""
} > "$OUT"

mysqldump --default-character-set=utf8mb4 -u root \
  --single-transaction --set-gtid-purged=OFF \
  --routines=0 --triggers=0 --events=0 \
  "$DB" "${TABLES[@]}" >> "$OUT"

# MySQL 5.7 / MariaDB: совместимость с дампом с MySQL 8
_compat_sed() {
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "$1" "$OUT"
  else
    sed -i '' "$1" "$OUT"
  fi
}
_compat_sed 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g'
# DEFAULT (_utf8mb4'') для BLOB — синтаксис MySQL 8.0.13+
_compat_sed 's/ DEFAULT (_utf8mb4[^)]*)//g'
_compat_sed 's/ DEFAULT (_latin1[^)]*)//g'

{
  echo ""
  echo "-- Доп. таблицы API (структура, если ещё нет на сервере)"
  echo ""
} >> "$OUT"

cat "$ROOT/sql/crg_app_extra_tables.sql" >> "$OUT"
cat "$ROOT/sql/migrate_users_app_columns.sql" >> "$OUT"

{
  echo ""
  echo "SET FOREIGN_KEY_CHECKS=1;"
} >> "$OUT"

echo "Готово: $OUT ($(wc -c < "$OUT" | tr -d ' ') bytes)"
