#!/usr/bin/env bash
# Smoke-тест search_order_counts.php (см. docs/search_future_ru.md §5.2)
set -euo pipefail

BASE_URL="${1:-http://gruzoperevozki72.ru}"
USE_ID="${2:-2}"
CITY="${3:-Винзили}"

echo "=== search_order_counts performer ${CITY} useId=${USE_ID} ==="
curl -sS -G "${BASE_URL}/api/search_order_counts.php" \
  --data-urlencode "role=performer" \
  --data-urlencode "useId=${USE_ID}" \
  --data-urlencode "city=${CITY}" \
  --data-urlencode "breakdown=1" \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d.get('success'), d
print('core_version:', d.get('core_version'))
print('city total:', d.get('cities', {}).get('${CITY}'))
print('services sample:', {k:v for k,v in list((d.get('services') or {}).items())[:5]})
bd = (d.get('city_breakdown') or {}).get('${CITY}', {})
print('breakdown:', bd)
nz = [k for k,v in (d.get('services') or {}).items() if v > 0]
print('non-zero services:', nz)
"

echo "OK"
