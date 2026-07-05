# Поиск и счётчики — план будущих доработок

**Версия:** 1.1  
**Дата:** 5 июля 2026  
**Статус:** частично внедрено (см. §9)
**Связанные документы:** [search_logic_ru.md](./search_logic_ru.md), [app_scenarios_ru.md](./app_scenarios_ru.md), [deals_logic_ru.md](./deals_logic_ru.md)

Документ составлен по итогам отладки сценария **Винзили + Грузчики** (июль 2026): расхождение счётчиков supply/demand, путаница ролей заказчик ↔ исполнитель.

---

## 1. Урок из продакшена (не баг, а UX)

| Роль | Что считается | Таблица | Пример Винзили |
|------|---------------|---------|----------------|
| **Заказчик** ищет исполнителей | Объявления **supply** | `add_ob_gr` | Грузчики **(1)** — исполнитель *предлагает* услугу |
| **Исполнитель** ищет заявки | Заявки **demand** | `ordersg` | Грузчики **(0)** — нет заявки «нужны грузчики» |
| **Исполнитель** | Заявки demand | `orderst` | Экскаваторы **(1)** — есть заявка заказчика |

**Счётчик города `(N)`** у исполнителя — сумма по **всем** типам (`orders` + `orderst` + `ordersg`), а не по выбранной услуге.

**Вывод:** пользователю нужно явно показывать, что город и услуга считаются по-разному, и какие услуги дают `(N) > 0`.

---

## 2. PHP — новые функции и рефакторинг

### 2.1. Единый слой разрешения категории (приоритет: высокий)

Сейчас логика размазана между `search_resolve_supply_category`, `search_resolve_demand_category`, `search_resolve_getads3_table`, `search_resolve_get_ads2_table`.

**Внедрить:**

```php
// api/include/search_category_resolver.php

/** @return array{bd:int,side_table:string,category_field:?string,source:string}|null */
function crg_resolve_search_category(mysqli $conn, string $nameImg, string $side): ?array;
// $side = 'supply' | 'demand'

function crg_bd_config(int $bd): ?array;

function crg_is_gruzchik_service(mysqli $conn, string $nameImg): bool;
```

**Правила (как в legacy API):**

| Сторона | Порядок проверки | Fallback bd=3 |
|---------|------------------|---------------|
| demand | `getads3`: vidt → vidg → gruzchik | есть строки в `ordersg` |
| supply | `get_ads2_new`: add_ob_gp → add_ob_vidt → gruzchik | есть строки в `add_ob_gr` |

После внедрения — убрать дубли из `search_services_core.php`, оставить тонкие обёртки.

---

### 2.2. Единый SQL-блок фильтров (приоритет: высокий)

**Внедрить:**

```php
// api/include/search_visibility_sql.php

function crg_sql_demand_base_filters(int $bd, string $orderAlias = 'a'): string;
function crg_sql_supply_base_filters(int $bd, string $adAlias = 'a'): string;
function crg_sql_hide_active_deal_customer_order(int $bd, string $orderAlias = 'a'): string;
function crg_sql_hide_active_deal_performer_ad(int $bd, string $adAlias = 'a'): string;
```

**Цель:** один и тот же фрагмент WHERE в:

- `search_services_core.php` (выдача + счётчики);
- `getads3.php`, `get_ads2_new.php` (legacy fallback);
- `get_citiesisp.php`, `get_cities.php` (города с объявлениями).

**Обязательно:** везде учёт **`bd`** при join с `ordersglobal` (см. `order_visibility.php`, инцидент id=6 в `orders` и `ordersg`).

---

### 2.3. Счётчики — новые функции API (приоритет: средний)

```php
/** Город → разбивка по услугам (для подсказки в UI) */
function search_demand_breakdown_by_city(mysqli $conn, string $useId, string $city): array;
// ['Экскаваторы' => 1, 'Грузчики' => 0, ...]

/** Одна услуга — один запрос (уже есть, довести до resolver) */
function search_demand_count_for_service(...): int;
function search_supply_count_for_service(...): int;

/** Версия / хэш логики для отладки деплоя */
function search_core_version(): string;
```

**Расширение `search_order_counts.php`:**

```json
{
  "success": true,
  "role": "performer",
  "core_version": "2026-07-05",
  "cities": { "Винзили": 1 },
  "services": { "Экскаваторы": 1, "Грузчики": 0 },
  "city_breakdown": { "Винзили": { "Экскаваторы": 1 } }
}
```

Поле `city_breakdown` — опционально (`?breakdown=1`), чтобы не грузить ответ при каждом открытии формы.

---

### 2.4. Диагностический endpoint (приоритет: средний)

**Файл:** `api/admin-web/search_debug.php` (только для админов) или `api/search_debug.php` с секретным ключом.

**Параметры:** `role`, `useId`, `city`, `nameImg`.

**Ответ:** почему счётчик N, какая таблица, сколько строк до/после каждого фильтра (`iduser`, `enddatez`, `offer_data`, `ordersglobal`, `users`).

Ускорит разбор кейсов вроде «город (1), услуга (0)».

---

### 2.5. Нормализация имён (приоритет: средний)

```php
function search_normalize_service_key(string $name): string;
function search_build_counts_map(array $rawCounts, array $catalogNames): array;
```

**Проблема:** `getsearsh.php` отдаёт `name` как в БД, `search_load_all_category_names()` — с `trim()`. Расхождение пробелов → `(0)` в UI при ненулевом API.

**Правило:** trim на записи в API **и** на клиенте при lookup в `_serviceCounts[name]`.

---

### 2.6. Кэш счётчиков (приоритет: низкий)

```php
function search_counts_cache_get(string $key): ?array;
function search_counts_cache_set(string $key, array $payload, int $ttlSec = 60): void;
```

Ключ: `role:useId:city`. TTL 30–60 с — снизить нагрузку при открытии формы (сотни категорий × несколько SQL).

---

### 2.7. Защита от самопредложения (приоритет: низкий, из deals_logic)

Серверная проверка в `add_offer.php` / `add_offerzakaz.php`:

```php
function crg_forbid_self_offer(int $viewerId, int $adOwnerId): void;
```

Поиск уже скрывает свои карточки; POST без проверки — дыра.

---

## 3. Flutter — логика и UI

### 3.1. Подсказка при выборе города (приоритет: высокий)

После выбора города, если `cityCount > 0` и ни одна услуга не `> 0` у выбранной категории — **не путать с багом**.

**Варианты:**

- Текст под полем «Услуга»: *«В этом городе 1 заявка в других категориях — смотрите услуги с (1)»*.
- Сортировка выпадающего списка услуг: сначала с `count > 0`, затем остальные.
- Подсветка `(N)` зелёным при `N > 0`.

**Файлы:** `performer_search_screen.dart`, `customer_search_screen.dart`.

---

### 3.2. Trim ключей счётчиков (приоритет: средний)

```dart
int countForService(String name) =>
    _serviceCounts[name.trim()] ?? _serviceCounts[name] ?? 0;
```

То же для городов.

---

### 3.3. Онбординг supply vs demand (приоритет: низкий)

Краткий tooltip при первом входе в поиск:

- Заказчик: *«Ищете объявления исполнителей»*.
- Исполнитель: *«Ищете заявки заказчиков»*.

---

### 3.4. Единый клиент поиска (приоритет: низкий)

Вынести в `lib/search/search_counts_client.dart`:

- загрузка `search_order_counts.php`;
- парсинг `cities` / `services` / `city_breakdown`;
- retry при 500 / таймауте.

Сейчас дублируется в `CustomerSearchScreen` и `PerformerSearchScreen`.

---

## 4. База данных и сделки

| Задача | Файл миграции | Зачем |
|--------|---------------|-------|
| `ordersglobal.deal_source` + `bd` | `sql/migrate_ordersglobal_deal_source.sql` | однозначная связь сделки с типом объявления |
| Индекс `(city, enddatez)` на `orders*` | отдельная миграция | ускорение счётчиков по городам |
| Индекс `offer_data (iduser, bd, isp, status)` | отдельная миграция | фильтр «занятых» заявок |

См. [deals_logic_ru.md](./deals_logic_ru.md) §6.4, §7.

---

## 5. Тесты и регрессия

### 5.1. Чеклист ручной регрессии (после каждого деплоя `search_services_core.php`)

| # | Сценарий | Ожидание |
|---|----------|----------|
| 1 | Заказчик: Винзили + Грузчики, `useId` заказчика | счётчик = выдача `search_services` = `get_ads2_new` |
| 2 | Исполнитель: Винзили + Экскаваторы | счётчик = выдача = `getads3` |
| 3 | Исполнитель: Винзили + Грузчики | **(0)**, если нет `ordersg` в городе |
| 4 | Dual-role: свой `add_ob_*` не в supply; свой `orders*` не в demand | |
| 5 | Меню: «Найти заявки» из «Мои объявления» — одно нижнее меню | |
| 6 | Пустая выдача → fallback legacy API | |

### 5.2. Автотесты (будущее)

- PHP: fixture БД (`sql/local_dev.sql`) + assert на `search_demand_counts_by_service_in_city`.
- Интеграция: curl-скрипт в `scripts/smoke_search_counts.sh` против staging.

---

## 6. Legacy и техдолг

| Элемент | Действие |
|---------|----------|
| `q.php`, `get_ads2.php`, `th.php` | отключить на сервере или проксировать на `get_ads2_new` / `search_services` |
| Дубли `api_new/*` | сверить с `api/*`, один канон |
| `search_sql_demand_user_exists()` vs `INNER JOIN users` | выбрать один способ в `crg_sql_demand_base_filters` |
| Статический cache в `search_load_all_category_names` | сброс при изменении справочников (админка vidg/vidt/gruzchik) |

---

## 7. Приоритеты внедрения

```mermaid
flowchart LR
  subgraph high [Высокий]
    A[Единый resolver категорий]
    B[Единый SQL visibility]
    C[UI: сортировка услуг с N больше 0]
  end
  subgraph medium [Средний]
    D[city_breakdown в API]
    E[search_debug endpoint]
    F[normalize имён]
  end
  subgraph low [Низкий]
    G[Кэш счётчиков]
    H[deal_source миграция]
    I[Самопредложение на POST]
  end
  high --> medium --> low
```

**Рекомендуемый порядок:**

1. UI: сортировка и подсказка «заявки в других категориях» (быстрый эффект для пользователей).
2. `crg_resolve_search_category` + `crg_sql_*_base_filters` (меньше расхождений legacy / новый поиск).
3. `city_breakdown` + admin `search_debug.php`.
4. Миграция `ordersglobal`, кэш, автотесты.

---

## 8. Уже реализовано (база для будущего)

Не дублировать при разработке — опираться на существующее:

| Функция / файл | Назначение |
|----------------|------------|
| `search_resolve_supply_category()` | supply, как `get_ads2_new` |
| `search_resolve_demand_category()` | demand, как `getads3` + fallback `ordersg` |
| `search_fetch_supply_get_ads2()` | fallback выдачи заказчика |
| `search_fetch_demand_getads3()` | fallback выдачи исполнителя |
| `search_apply_gruzchik_demand_counts()` | bd=3 → счётчик на имена из `gruzchik` |
| `search_order_counts.php` | `role=customer` \| `performer`, обязательный `useId` |
| `api/include/viewer_user.php` | `crg_viewer_user_id_from_request()` |
| `embedInPerformerShell` / `embedInCustomerShell` | одно нижнее меню на результатах |

---

## 9. Внедрено (5 июля 2026)

| Пункт плана | Файлы | Статус |
|-------------|-------|--------|
| §2.1 Единый resolver | `api/include/search_category_resolver.php` | ✓ обёртки `crg_*` |
| §2.2 SQL visibility | `api/include/search_visibility_sql.php` | ✓ подключено в core |
| §2.3 `core_version`, `city_breakdown` | `search_order_counts.php`, `search_services_core.php` | ✓ `?breakdown=1` |
| §2.4 Диагностика | `api/admin-web/search_debug.php` | ✓ только админ |
| §2.5 Нормализация имён | `search_normalize_service_key`, `search_build_counts_map` | ✓ |
| §3.1 UI подсказка, сортировка, зелёный (N) | `performer_search_screen.dart`, `customer_search_screen.dart`, `SearchServiceCountLabel` | ✓ |
| §3.2 Trim ключей | `search_counts_helpers.dart` | ✓ |
| §3.4 Единый клиент | `lib/search/search_counts_client.dart` | ✓ |
| §5.2 Smoke | `scripts/smoke_search_counts.sh` | ✓ |
| §2.7 Самопредложение | `crg_forbid_self_offer` в `viewer_user.php` | ✓ (дублирует `add_offer.php`) |

**Остаётся:** кэш счётчиков (§2.6), миграция `ordersglobal` (§4), полная замена legacy API (§6), автотесты PHP на fixture.

---

*При добавлении пунктов обновляйте версию и дату в шапке. Крупные реализации — краткая отсылка в [search_logic_ru.md](./search_logic_ru.md) §18.*
