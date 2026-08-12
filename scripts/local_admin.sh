#!/usr/bin/env bash
# Локальный запуск: БД + PHP-сервер для admin-web.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f api/databd.local.php ]]; then
  cp api/databd.local.example.php api/databd.local.php
  echo "Создан api/databd.local.php — при необходимости отредактируйте доступ к MySQL."
fi

# Все эндпоинты делают include databd.php — проксируем на local, если файла ещё нет.
if [[ ! -f api/databd.php ]]; then
  cat > api/databd.php << 'EOF'
<?php
$localPath = __DIR__ . '/databd.local.php';
if (!is_readable($localPath)) {
    throw new RuntimeException('Нужен api/databd.local.php для локального MySQL');
}
require $localPath;
EOF
  echo "Создан api/databd.php → databd.local.php"
fi

echo "→ Импорт sql/local_dev.sql (БД crg_local)..."
mysql --default-character-set=utf8mb4 -h 127.0.0.1 -u root < sql/local_dev.sql

echo ""
echo "→ Старт PHP на http://127.0.0.1:8080 (тестовый MySQL: crg_local)"
echo "   Админка:  http://127.0.0.1:8080/admin-web/login.php"
echo "   API:      http://127.0.0.1:8080/cities.php"
echo "   Логин:    admin"
echo "   Пароль:   ChangeMe_Admin1!"
echo "   Flutter:  Config.useLocalApi = true в lib/config.dart"
echo ""
cd api
exec php -S 127.0.0.1:8080
