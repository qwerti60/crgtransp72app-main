#!/usr/bin/env bash
# Локальный запуск: БД + PHP-сервер для admin-web.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f api/databd.local.php ]]; then
  cp api/databd.local.example.php api/databd.local.php
  echo "Создан api/databd.local.php — при необходимости отредактируйте доступ к MySQL."
fi

echo "→ Импорт sql/local_dev.sql (БД crg_local)..."
mysql --default-character-set=utf8mb4 -u root < sql/local_dev.sql

echo ""
echo "→ Старт PHP на http://127.0.0.1:8080"
echo "   Админка:  http://127.0.0.1:8080/admin-web/login.php"
echo "   API:      http://127.0.0.1:8080/cities.php"
echo "   Логин:    admin"
echo "   Пароль:   ChangeMe_Admin1!"
echo ""
cd api
exec php -S 127.0.0.1:8080
