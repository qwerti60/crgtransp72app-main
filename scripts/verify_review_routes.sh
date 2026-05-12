#!/usr/bin/env bash
# Статическая проверка: экраны отзывов ↔ API ↔ таблицы в SQL.
# Запуск из корня репозитория: bash scripts/verify_review_routes.sh

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

err() { echo "ERROR: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

# --- Flutter: разные URL у двух экранов и нет перепутывания ---
grep -q "review_api\.php" lib/pages/review_screen.dart \
  || err "review_screen.dart должен вызывать review_api.php (отзывы о заказчике / таблица reviews)"
if grep -q "review_apiz\.php" lib/pages/review_screen.dart; then
  err "review_screen.dart не должен вызывать review_apiz.php"
fi
ok "review_screen.dart → только review_api.php"

grep -q "review_apiz\.php" lib/pages/review_screenz.dart \
  || err "review_screenz.dart должен вызывать review_apiz.php (отзывы о перевозчике / reviewsisp)"
if grep -q "review_api\.php" lib/pages/review_screenz.dart; then
  err "review_screenz.dart не должен вызывать review_api.php"
fi
ok "review_screenz.dart → только review_apiz.php"

# Формы отправки отзыва — разные endpoint'ы
grep -q "save_review\.php" lib/pages/SendReviewForm.dart \
  || err "SendReviewForm.dart должен использовать save_review.php"
grep -q "save_reviewzaka\.php" lib/pages/SendReviewFormzakaz.dart \
  || err "SendReviewFormzakaz.dart должен использовать save_reviewzaka.php"
ok "SendReviewForm* → разные save_review*.php"

# --- PHP: чтение отзывов с ожидаемых таблиц ---
grep -q "FROM reviews " api/review_api.php || grep -q "FROM reviews\$" api/review_api.php \
  || grep -q "FROM reviews\`" api/review_api.php \
  || grep -q "FROM reviews r" api/review_api.php \
  || err "review_api.php должен читать таблицу reviews"
if grep -q "reviewsisp" api/review_api.php; then
  err "review_api.php не должен ссылаться на reviewsisp"
fi
ok "review_api.php → таблица reviews"

grep -q "FROM reviewsisp" api/review_apiz.php \
  || err "review_apiz.php должен читать таблицу reviewsisp"
if grep -q "FROM reviews " api/review_apiz.php; then
  err "review_apiz.php не должен читать таблицу reviews (ожидается только reviewsisp)"
fi
ok "review_apiz.php → таблица reviewsisp"

echo ""
echo "Все проверки пройдены."
