#!/usr/bin/env bash
# Импорт prod-картинок (LONGBLOB в колонке image) из дампа в локальную БД.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DUMP="${1:-$ROOT/u2395188_apps.sql}"
DB="${2:-crg_local}"
MYSQL=(mysql --default-character-set=utf8mb4 -u root "$DB")

if [[ ! -f "$DUMP" ]]; then
  echo "Файл дампа не найден: $DUMP" >&2
  exit 1
fi

echo "Импорт vidt, vidg, gruzchik (BLOB image) из $DUMP → $DB"

import_table() {
  local name="$1"
  local from="$2"
  local to="$3"
  echo "  → $name (строки $from–$to)"
  "${MYSQL[@]}" -e "DROP TABLE IF EXISTS \`$name\`;"
  sed -n "${from},${to}p" "$DUMP" | "${MYSQL[@]}"
}

fix_autoincrement() {
  local name="$1"
  echo "  → AUTO_INCREMENT для $name"
  local next
  next=$("${MYSQL[@]}" -N -e "SELECT COALESCE(MAX(\`id\`), 0) + 1 FROM \`$name\`;")
  "${MYSQL[@]}" -e "
    ALTER TABLE \`$name\` ADD PRIMARY KEY (\`id\`);
    ALTER TABLE \`$name\` MODIFY \`id\` INT NOT NULL AUTO_INCREMENT;
    ALTER TABLE \`$name\` AUTO_INCREMENT = ${next};
  "
}

# CREATE + INSERT из prod-дампа (u2395188_apps.sql)
import_table gruzchik 423 437
import_table vidg 1535 1554
import_table vidt 1601 1653

fix_autoincrement gruzchik
fix_autoincrement vidg
fix_autoincrement vidt

echo "Готово. Проверка:"
"${MYSQL[@]}" -e "
SELECT 'vidt' AS tbl, COUNT(*) AS cnt, SUM(LENGTH(image)) AS bytes FROM vidt
UNION ALL SELECT 'vidg', COUNT(*), SUM(LENGTH(image)) FROM vidg
UNION ALL SELECT 'gruzchik', COUNT(*), SUM(LENGTH(image)) FROM gruzchik;
"
