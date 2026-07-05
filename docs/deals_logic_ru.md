# Логика сделок, изоляция данных и план правок

**Версия:** 1.2  
**Дата:** 5 июля 2026  
**Статус:** реализовано (см. §12–14, [app_scenarios_ru.md](./app_scenarios_ru.md))  
**Связанные документы:** [search_logic_ru.md](./search_logic_ru.md), [chat_logic_ru.md](./chat_logic_ru.md), **[app_scenarios_ru.md](./app_scenarios_ru.md)** — свод всех сценариев по запросам

---

## 1. Роли и принцип изоляции

Один пользователь (`users.idusers`) может одновременно быть **заказчиком** и **исполнителем**. Роль в конкретной операции определяется не полем профиля, а **контекстом сделки**:

| Контекст | Кто заказчик | Кто исполнитель |
|----------|--------------|-----------------|
| Сценарий 1 | владелец заявки (`orders` / `orderst` / `ordersg`) | автор отклика в `offer_data` |
| Сценарий 2 | автор заявки в `offer_dataf` | владелец объявления (`add_ob_*`) |

**Ключ изоляции:** `(таблица оффера, bd, iduser, iduserp)` + `ordersglobal(user_id, order_id, user_idok)`.

> **Важно:** числовой `id` объявления может совпадать в разных таблицах (например, `orders.id = 6` и `add_ob_gp.id = 6`). Всегда используется пара **`(bd, id)`**, а не только `id`.

---

## 2. Два сценария сделки

### 2.1. Сценарий 1 — исполнитель предлагает услугу на заявку заказчика

```
Исполнитель → «Предложить услуги» (OfferScreen)
    → add_offer.php → offer_data

Заказчик → «Предложения исполнителей» (list_predloj_na_obj_isp)
    → принимает одного исполнителя (isp = 1 в offer_data)

Исполнитель → «Начать выполнение»
    → check_order_status.php (source=customer_order)
    → ordersglobal (order_id = id заявки заказчика)

Завершение → отзывы обеих сторон → история
```

| Поле | Значение |
|------|----------|
| Таблица | `offer_data` |
| `iduserp` | id **исполнителя** |
| `iduser` | id **заявки** заказчика |
| `bd` | 1=`orders`, 2=`orderst`, 3=`ordersg` |
| `isp` | 0 — ожидает, 1 — принято заказчиком |
| `status` | 0 — активный отклик, 1 — сделка начата/завершена, **2 — заказчик отказался** (отклик сохраняется, повтор невозможен) |

**Ожидаемое поведение после принятия:** заявка заказчика **скрывается** от других исполнителей (и от принявшего исполнителя в поиске — по вашему описанию). При отказе — снова видна.

---

### 2.2. Сценарий 2 — заказчик предлагает заказ на объявление исполнителя

```
Заказчик → «Предложить заказ» (OfferScreen2)
    → add_offerzakaz.php → offer_dataf

Исполнитель → «Заявки на моё объявление» (list_predloj_na_zayavki)
    → принимает заявку заказчика (isp = 1 в offer_dataf)

Исполнитель → «Начать выполнение»
    → check_order_status.php (source=performer_ad)
    → ordersglobal (order_id = id объявления исполнителя)

Завершение → отзывы → история
```

| Поле | Значение |
|------|----------|
| Таблица | `offer_dataf` |
| `iduserp` | id **заказчика** |
| `iduser` | id **объявления** исполнителя |
| `bd` | 1=`add_ob_gp`, 2=`add_ob_vidt`, 3=`add_ob_gr` |
| `isp` | 0 — ожидает, 1 — принято исполнителем |

**Ожидаемое поведение после принятия:** объявление исполнителя **скрывается** от этого заказчика в поиске. При отказе — снова доступно.

---

## 3. Общие правила (по вашему описанию)

| Правило | Где должно работать |
|---------|---------------------|
| Свои объявления не показываются в поиске | `get_ads2_new.php`, `getads3.php`, `search_services_core.php` |
| Объявление исполнителя на модерации (`flag = 0`) не видно заказчику | `get_ads2_new.php`, `search_services_core.php` |
| Один принятый отклик на заявку/объявление | UI блокирует остальные кнопки «Принять» |
| Таймер у обеих сторон после «Начать выполнение» | `ordersglobal.start_time`, экраны `OrderExecutionScreen*` |
| Отзывы после завершения (новый или изменение существующего) | `reviews`, `reviewsisp`, формы на экранах выполнения |
| Выполненный заказ помечен в «Мои объявления» заказчика | `zak_get_ads.php` + `ordersglobal` |
| Завершённые/отменённые сделки в истории обеих сторон | `list_history_zak.php`, `list_history_isp.php` |

---

## 4. Карта файлов (текущая реализация)

### 4.1. Создание откликов

| Действие | Flutter | API | Таблица |
|----------|---------|-----|---------|
| Исполнитель → заявка | `OfferScreen.dart` | `add_offer.php` | `offer_data` |
| Заказчик → объявление | `OfferScreen2.dart` | `add_offerzakaz.php` | `offer_dataf` |

### 4.2. Списки предложений

| Экран | Flutter | API списка | Таблица |
|-------|---------|------------|---------|
| Предложения исполнителей на **заявку** | `list_predloj_na_obj_isp.dart` | `list_predloj_na_obj_isp_new.php` | `offer_data` |
| Заявки заказчиков на **объявление** | `list_predloj_na_zayavki.dart` | `list_predloj_na_zayavki_new.php` | `offer_dataf` |

### 4.3. Принятие / отказ (isp)

| Экран | API | Таблица в коде |
|-------|-----|----------------|
| `list_predloj_na_obj_isp` (сценарий 1) | `updatePriemZak.php` | **`offer_dataf`** ⚠ |
| `list_predloj_na_zayavki` (сценарий 2) | `updatePriemZak.php` | `offer_dataf` ✓ |

Проверка «принято ли»: оба экрана → `check_isp.php` → **`offer_dataf`** ⚠ для сценария 1.

### 4.4. Старт и статус сделки

| API | Сценарий |
|-----|----------|
| `check_order_status.php` | `source=customer_order` → `offer_data.isp=1`; `source=performer_ad` → `offer_dataf.isp=1` |
| `check_order_status1.php` / `isp.php` / `isp2.php` | активная сделка исполнителя / заказчика |
| `update_order_status.php` | завершение / отмена |
| `get_order_global_info.php` | данные для таймера |

### 4.5. История

| Роль | Flutter | API | Охват |
|------|---------|-----|-------|
| Заказчик | `history_zak.dart` | `list_history_zak.php` | только `offer_data` |
| Исполнитель | `history_isp.dart` | `list_history_isp.php` | только `offer_data` |

Клиентская фильтрация dual-role: в `history_zak.dart` отсекаются записи с `iduserp == я`; в `history_isp.dart` — с `iduser == я`.

### 4.6. Поиск и «Мои объявления»

| Направление | API |
|-------------|-----|
| Заказчик ищет исполнителей | `get_ads2_new.php`, `search_services.php` |
| Исполнитель ищет заказы | `getads3.php`, `search_services.php` |
| Мои объявления исполнителя | `get_adstest.php` (счётчик `offer_dataf`) |
| Мои объявления заказчика | `zak_get_ads.php` (счётчик `offer_data`, статус `ordersglobal`) |

---

## 5. Что уже работает корректно

- **Самоисключение в поиске:** `a.iduser != текущий_user` во всех основных API.
- **Модерация объявлений исполнителя:** `(flag IS NULL OR flag = 1)` в `get_ads2_new.php`, `search_services_core.php`.
- **Запись в offer_data / offer_dataf:** поля `iduserp` / `iduser` в `add_offer.php` и `add_offerzakaz.php` не перепутаны.
- **Сценарий 2 целиком:** список (`list_predloj_na_zayavki_new`), принятие (`updatePriemZak` + `check_isp`), старт (`check_order_status` + `source=performer_ad`), проверка сделки (`check_offer_zakaz.php`).
- **Сценарий 2 — счётчик «Заказов»** в «Мои объявления» исполнителя: `get_adstest.php` → `offer_dataf`.
- **Разделение старта сделки** в `check_order_status.php` по параметру `source`.
- **Отзывы и чат** привязаны к `ordersglobal` и id оффера.

---

## 6. Найденные проблемы (подробно)

### 6.1. 🔴 Критично — принятие на сценарии 1 пишет не в ту таблицу

**Симптом:** заказчик на экране «Предложения исполнителей» нажимает «Принять», но обновляется `offer_dataf`, а не `offer_data`.

**Код:**

`updatePriemZak.php` всегда выполняет:

```sql
UPDATE offer_dataf SET isp = ...
WHERE iduser = :idusers AND iduserp = :iduserp AND bd = :bd
```

Экран `list_predloj_na_obj_isp.dart` передаёт:

- `idusers` = id **заявки заказчика** (`widget.nameImg`)
- `iduserp` = id **исполнителя**

Для `offer_data` ожидается:

```sql
UPDATE offer_data SET isp = ...
WHERE iduser = :order_id AND iduserp = :performer_id AND bd = :bd
```

**Почему это опасно при многих пользователях:**  
если случайно существует строка `offer_dataf` с `iduser = <id заявки>` и `iduserp = <id исполнителя>` (коллизия id между таблицами заявок и объявлений), может переключиться **чужая** сделка сценария 2. В остальных случаях `isp` в `offer_data` **не меняется**, и `check_order_status.php` (сценарий 1) отвечает «Предложение не принято заказчиком».

**Тот же баг в `check_isp.php`:** для сценария 1 нужно читать `offer_data`, а не `offer_dataf`.

**Уточнение перед правкой:**  
вы писали, что экран «работает». Нужно подтвердить на проде после «Принять»:

```sql
-- должна измениться isp у нужной строки:
SELECT id, iduserp, iduser, bd, isp, status FROM offer_data
WHERE iduser = <id_заявки> AND iduserp = <id_исполнителя>;

-- эта строка НЕ должна меняться для сценария 1:
SELECT id, iduserp, iduser, bd, isp FROM offer_dataf
WHERE iduser = <id_заявки> AND iduserp = <id_исполнителя>;
```

---

### 6.2. 🟠 Средне — скрытие «занятых» объявлений в поиске не работает

**Симптом:** принятая сделка не скрывает объявление из выдачи.

**Причина:** во всех поисковых API join некорректен:

```sql
LEFT JOIN offer_data od ON od.id = a.id AND od.isp = 1
...
AND od.id IS NULL
```

`od.id` — это **PK строки** в `offer_data`, а `a.id` — **id объявления**. Совпадение случайно и крайне редко.

**Как должно быть:**

| Поиск | Таблица объявлений `a` | Проверка «занято» |
|-------|------------------------|-------------------|
| Заказчик → исполнители | `add_ob_*` | `offer_dataf` WHERE `iduser = a.id AND bd = … AND isp = 1` |
| Исполнитель → заказы | `orders*` | `offer_data` WHERE `iduser = a.id AND bd = … AND isp = 1` |

Дополнительно имеет смысл исключать объявления с активной/завершённой сделкой в `ordersglobal` (частично есть в `search_services_core.php` через `dealExclude`, но только для сценария 1 и только через `offer_data`).

**Затронутые файлы:**  
`get_ads2_new.php`, `getads3.php`, `get_ads2.php`, `q.php`, `get_citiesisp.php`, `api/include/search_services_core.php`, `api_new/get_ads2_new.php`.

---

### 6.3. 🟠 Средне — история только по сценарию 1

**Симптом:** сделки сценария 2 (`offer_dataf`) не попадают в «Историю заказов».

**Код:** `list_history_zak.php` и `list_history_isp.php` делают `JOIN` только с `offer_data`.

**Как должно быть (по вашему описанию):**  
оба сценария после статуса `выполнен` / `отменен` видны:

- заказчику — контрагент-исполнитель;
- исполнителю — контрагент-заказчик.

**Дополнительно:** `list_history_isp_new.php` содержит ошибочный join `offer_data.iduser = add_ob_*.id` (в `offer_data.iduser` хранится id **заявки заказчика**, не объявления исполнителя). Файл не используется Flutter напрямую, но опасен при подключении.

---

### 6.4. 🟠 Средне — `ordersglobal.order_id` без типа сделки

**Симптом:** одно поле хранит и id заявки заказчика (сценарий 1), и id объявления исполнителя (сценарий 2).

**Риск:** при совпадении числовых id в разных таблицах запрос без `user_idok` / `source` может вернуть чужую сделку.

**Смягчение уже есть:** `check_order_status.php` (сценарий 2) всегда фильтрует по `user_idok`; Flutter передаёт `source`.

**Надёжное решение:** колонка `deal_source ENUM('customer_order','performer_ad')` + `bd` в `ordersglobal`, миграция существующих строк по join с `offer_data` / `offer_dataf`.

---

### 6.5. 🟡 Низко — нет серверной защиты от самопредложения

Поиск скрывает свои карточки, но прямой POST на `add_offer.php` / `add_offerzakaz.php` теоретически создаст отклик самому себе.

---

### 6.6. 🟡 Низко — legacy API

`q.php`, `th.php`, `get_ads2.php` — слабые фильтры, SQL-инъекции, тот же битый join. Flutter их не вызывает; рекомендуется отключить на сервере или привести к `get_ads2_new.php`.

---

## 7. Предлагаемые правки (по приоритету)

> **Принцип:** точечные изменения, без ломки рабочего сценария 2. Перед деплоем — проверка на staging / одной тестовой паре пользователей.

---

### Правка A — принятие и проверка isp для обоих сценариев

**Цель:** сценарий 1 пишет/читает `offer_data`; сценарий 2 — `offer_dataf`.

**Вариант A1 (рекомендуется): один endpoint с параметром `source`**

`updatePriemZak.php`:

```php
// POST: source = customer_order | performer_ad
// customer_order: UPDATE offer_data SET isp = CASE... WHERE iduser=:ad_id AND iduserp=:performer AND bd=:bd
// performer_ad:   UPDATE offer_dataf SET isp = CASE... WHERE iduser=:ad_id AND iduserp=:customer AND bd=:bd
```

`check_isp.php` — аналогично по `source`.

**Flutter:**

- `list_predloj_na_obj_isp.dart` → `source: customer_order`
- `list_predloj_na_zayavki.dart` → `source: performer_ad`

**Вариант A2:** отдельные файлы `updatePriemIsp.php` + `check_isp_order.php` (меньше риска сломать сценарий 2, больше файлов).

**Дополнительно при принятии сценария 1:**

- сбрасывать `isp = 0` у **остальных** `offer_data` с тем же `iduser` + `bd` (только одно принятое предложение);
- опционально: не toggle, а явные `accept=1` / `accept=0` вместо `CASE WHEN isp=0 THEN 1 ELSE 0`.

**Вопрос к вам:** при «Отказаться от предложения» заказчиком (сценарий 1) — достаточно `isp=0` у одного исполнителя, или нужно уведомлять исполнителя и удалять отклик?

---

### Правка B — скрытие занятых объявлений в поиске

**Цель:** после `isp = 1` объявление не показывается в выдаче (с учётом пары bd + id).

**Заменить** битый `LEFT JOIN offer_data od ON od.id = a.id` на:

**Для `get_ads2_new.php` / supply в search (объявления исполнителя):**

```sql
AND NOT EXISTS (
    SELECT 1 FROM offer_dataf odf
    WHERE odf.iduser = a.id AND odf.bd = :bd AND odf.isp = 1
)
```

**Для `getads3.php` / demand в search (заявки заказчика):**

```sql
AND NOT EXISTS (
    SELECT 1 FROM offer_data od
    WHERE od.iduser = a.id AND od.bd = :bd AND od.isp = 1
)
```

**Скрытие для сценария 1 (подтверждено):** после `isp = 1` заявка **не показывается ни одному исполнителю** в поиске (`getads3.php`, demand в search).

**Скрытие для сценария 2 (подтверждено):** объявление исполнителя **остаётся в общей выдаче** для всех заказчиков. Ограничения только на время **активной** сделки (`ordersglobal.status = 'выполняется'`) — не показывать **этому** заказчику повторно то же объявление / не давать дублирующий оффер. После **выполнения** — повторное «Предложить заказ» от того же заказчика **разрешено**.

```sql
-- get_ads2_new: НЕ скрывать глобально по isp=1.
-- Опционально для текущего usersid — скрыть только при активной сделке:
AND NOT EXISTS (
    SELECT 1 FROM ordersglobal og
    INNER JOIN offer_dataf odf ON odf.id = og.idoffer
    WHERE CAST(og.order_id AS CHAR) = CAST(a.id AS CHAR)
      AND og.user_idok = :current_user
      AND og.status = 'выполняется'
      AND odf.bd = :bd
)
```

---

### Правка C — история для обоих сценариев

**Цель:** `list_history_zak.php` и `list_history_isp.php` возвращают UNION двух веток.

**Ветка 1 (как сейчас):** `offer_data` + `ordersglobal` + `user_idok` / `user_id`.

**Ветка 2 (новая):** `offer_dataf` + `ordersglobal` где `order_id = id объявления`, `user_id = исполнитель`, `user_idok = заказчик`.

Добавить в JSON поле `deal_source: customer_order | performer_ad` для корректного UI.

**Flutter:** фильтры dual-role в `history_*.dart` оставить; при необходимости расширить по `deal_source`.

---

### Правка D — `ordersglobal.deal_source` + `bd` (миграция)

```sql
ALTER TABLE ordersglobal
  ADD COLUMN deal_source ENUM('customer_order','performer_ad') NULL AFTER order_id,
  ADD COLUMN bd TINYINT NULL AFTER deal_source;

-- backfill:
-- customer_order: JOIN offer_data ON idoffer = offer_data.id
-- performer_ad:   JOIN offer_dataf ON idoffer = offer_dataf.id
```

Обновить `check_order_status.php`, `update_order_status.php`, `get_order_global_info.php` — везде передавать/фильтровать `deal_source` + `bd`.

**Вопрос к вам:** готовы к миграции БД на проде, или ограничиться усилением фильтров `user_idok` без новых колонок?

---

### Правка E — серверная валидация откликов

В `add_offer.php`:

```php
// iduser = order_id → SELECT iduser FROM orders* WHERE id = ? → не равен iduserp
```

В `add_offerzakaz.php`:

```php
// iduser = ad_id → SELECT iduser FROM add_ob_* WHERE id = ? → не равен iduserp (заказчик)
```

---

### Правка F — legacy API

- Закрыть `q.php`, `th.php`, `get_ads2.php` на nginx / `.htaccess`, **или**
- Перенаправить на `_new` версии с теми же правками, что в B.

---

## 8. Порядок внедрения (рекомендация)

| Этап | Правки | Риск | Проверка |
|------|--------|------|----------|
| 1 | A (isp для сценария 1) | средний | Принять на заявке → `offer_data.isp=1` → таймер |
| 2 | B (скрытие в поиске) | низкий | Принятая заявка/объявление не в выдаче |
| 3 | C (история) | низкий | Завершённая сделка сценария 2 в истории |
| 4 | E (самопредложение) | минимальный | POST с чужими id → 403 |
| 5 | D (deal_source) | средний | миграция + регрессия таймеров |
| 6 | F (legacy) | минимальный | старые URL недоступны |

**Не трогать без отдельного согласования:** логику чата, FCM, admin-web, экраны отзывов (если не требуется для C).

---

## 9. Чек-лист регрессии (два тестовых пользователя)

Создать UserA (заказчик) и UserB (исполнитель); optionally UserC как третий исполнитель.

### Сценарий 1

- [ ] B видит заявку A в поиске; A не видит свою заявку
- [ ] B отправляет предложение (`offer_data`)
- [ ] A видит B в «Предложения исполнителей»
- [ ] A принимает → `offer_data.isp=1`, другим «Принять» недоступно
- [ ] B нажимает «Начать выполнение» → `ordersglobal`, таймер у обоих
- [ ] Заявка скрыта из поиска (после правки B)
- [ ] B завершает → отзывы → заявка в «Мои объявления» A = выполнена
- [ ] Запись в истории A и B

### Сценарий 2

- [ ] A видит объявление B; объявление на модерации (`flag=0`) не видно
- [ ] A отправляет «Предложить заказ» (`offer_dataf`)
- [ ] B принимает → `offer_dataf.isp=1`
- [ ] B начинает выполнение → таймер
- [ ] Объявление скрыто от A (после правки B)
- [ ] B отказывает → объявление снова доступно A
- [ ] Завершение → история обоих

### Dual-role

- [ ] Один UserD = заказчик + исполнитель: данные A/B не смешиваются в истории и «Мои объявления»

---

## 10. Ответы заказчика (4 июля 2026)

| Вопрос | Ответ |
|--------|-------|
| Сценарий 1 на проде | Таймер у **заказчика** запустился **с опозданием**; кнопка **«Чат по заказу»** — **нет меню** ни у клиента, ни у заказчика (отдельный UI-баг, не только API) |
| Скрытие заявки (сценарий 1) | **От всех исполнителей** — заявка «занята» после принятия |
| Скрытие объявления (сценарий 2) | **Видят все**; после **выполнения** заказа тот же заказчик может **снова предложить** заказ на то же объявление |
| Миграция `ordersglobal` | **Да** — добавить `deal_source` + `bd` |
| Старт правок | **Выполнено** — см. §12 и [app_scenarios_ru.md](./app_scenarios_ru.md) |

### 10.1. Уточнение логики скрытия (сценарий 2)

По ответу заказчика:

- объявление исполнителя **не скрывается глобально** от других заказчиков;
- после **завершения** сделки повторное предложение от того же заказчика **разрешено**;
- на время **активной** сделки (`ordersglobal.status = 'выполняется'`) имеет смысл скрывать объявление **только от участников этой сделки** (или блокировать повторный оффер через `check_offer_zakaz.php`), но **не** убирать из общей выдачи.

**Правка B (раздел 7)** для `get_ads2_new.php` должна учитывать это: не `isp = 1` глобально, а комбинация «активная сделка» + опционально «уже есть незавершённый оффер от этого usersid».

### 10.2. Открытые вопросы — закрыты (4 июля 2026)

| Вопрос | Решение |
|--------|---------|
| Отказ от принятого (сценарий 1) | `offer_data.status = 2`, строку **не** удалять |
| Таймер с опозданием | нормализация `start_time` MySQL + fallback в Flutter |
| Чат без меню | `rootNavigator`, `showBottomNav: false` |
| Код | правки A–F внедрены — см. §12 |

### 10.3. Согласованный порядок правок

Выполнено: A → B (с учётом 10.1) → C → D → E → F; параллельно — таймер, чат, UI (см. [app_scenarios_ru.md](./app_scenarios_ru.md)).

---

## 11. Связь с `bd`

Справочник mapping в Flutter: `lib/customer_ad_category.dart`.

| bd | Заявка заказчика (`offer_data.iduser`) | Объявление исполнителя (`offer_dataf.iduser`) |
|----|----------------------------------------|-----------------------------------------------|
| 1 | `orders` | `add_ob_gp` |
| 2 | `orderst` | `add_ob_vidt` |
| 3 | `ordersg` | `add_ob_gr` |

При любых правках **обязательно** передавать `bd` в паре с id — иначе при dual-role и совпадающих id данные перепутаются.

---

## 12. Реализовано (4 июля 2026)

Свод всех сценариев и UI-правил: **[app_scenarios_ru.md](./app_scenarios_ru.md)**.

| Область | Реализация |
|---------|------------|
| A — `updatePriemZak` + `check_isp` по `source` | ✓ `customer_order` / `performer_ad` |
| B — скрытие в поиске | ✓ `getads3.php`, `search_services_core.php`, `customer_order_deal.php` |
| C — история UNION | ✓ `list_history_zak.php`, `list_history_isp.php` |
| D — `deal_source` + `bd` | ✓ миграция + API |
| E — самопредложение | ✓ `add_offer.php`, `add_offerzakaz.php` |
| Отказ заказчика | ✓ `status=2`, UI исполнителя, без DELETE |
| Таймер + `start_time` MySQL | ✓ `datetime_mysql.php`, `OrderExecutionScreen*` |
| Чат без меню с таймера | ✓ `rootNavigator`, `showBottomNav: false` |
| «Мои объявления» выполнено | ✓ `zak_get_ads.php`, `ads2.dart` |
| «Исполнитель уже выбран» | ✓ `getofferusern_new.php`, `zprofil_zayavki`, `list_predloj_na_obj_isp` |
| Навигация заказчика на счётчик | ✓ `customer_orders_hub_nav.dart` |
| Удаление объявления + история | ✓ `delete_zakaz.php` |
| Города / bd коллизия id | ✓ фильтры с `bd` |
| Блокировка нового старта (исполнитель) | ✓ §13 |
| Отзывы заказчика (`reviewsisp`, `needs_review`) | ✓ §14 |
| Dual-role: скрытие своих supply у заказчика | ✓ `viewer_user.php`, API + Flutter |

---

## 13. Блокировка нового старта (исполнитель) — 5 июля 2026

### 13.1. Бизнес-правило

Исполнитель не может **начать выполнение новой** сделки, пока:

1. Уже есть другая сделка со статусом `выполняется` в `ordersglobal` (для этого `user_idok` = исполнитель).
2. Есть **завершённая** сделка без отзыва о заказчике в `reviews` (`user_id` = исполнитель, `target_user_id` = заказчик).

**Исключение:** возобновление **той же** сделки (тот же `order_id` + пара участников) — не считается «новым» стартом.

### 13.2. Реализация

| Слой | Файл |
|------|------|
| PHP | `api/include/performer_order_gate.php` — `crg_performer_may_start_new_deal()`, `crg_json_performer_start_blocked()` |
| Старт сделки | `api/check_order_status.php` — проверка перед INSERT в `ordersglobal` |
| Flutter API | `lib/services/performer_order_gate.dart` — `fetchPerformerStartGate()` |
| UI | `zprofil_zayavki.dart`, `list_predloj_na_zayavki.dart` — баннер, серая кнопка |
| Ошибка с сервера | `OrderExecutionScreen.dart` — текст «Нельзя начать выполнение» |

### 13.3. Сценарии проверки

| # | Состояние | «Начать выполнение» на другом заказе |
|---|-----------|--------------------------------------|
| 1 | Нет активных сделок, все отзывы есть | Разрешено |
| 2 | Сделка A `выполняется` | Заблокировано |
| 3 | Сделка B `выполнен`, нет отзыва в `reviews` | Заблокировано |
| 4 | Тот же заказ A, продолжение таймера | Разрешено |

Свод UI: [app_scenarios_ru.md](./app_scenarios_ru.md) §3.5.

---

## 14. Отзывы заказчика об исполнителе — 5 июля 2026

### 14.1. Схема `reviewsisp`

| Поле | Значение |
|------|----------|
| `user_id` | id **исполнителя** (о ком отзыв) |
| `target_user_id` | id **заказчика** (автор отзыва) |

Запись / обновление: `save_reviewzaka.php`. Чтение пары: `get_review_between.php`.

### 14.2. Навигация и `needs_review`

`api/check_order_statusisp.php` возвращает:

| Поле | Смысл |
|------|-------|
| `status` | `выполняется` / `выполнен` / … |
| `needs_review` | `true`, если заказ завершён и в `reviewsisp` нет записи |
| `has_review` | отзыв уже есть |
| `deal_source`, `bd` | контекст сделки для экрана выполнения |

**Поведение заказчика:**

- Вкладка «Заказы» → экран таймера при `выполняется` **или** `needs_review` (`zakaz_screen1.dart`, `customer_orders_hub_nav.dart`).
- После «Завершить заказ» — диалог «Оставить отзыв» / «Позже» (`OrderExecutionScreenzak.dart`).
- Кнопка «Оставьте отзыв» / «Изменить отзыв о исполнителе» на экране выполнения.
- После сохранения в `SendReviewFormzakaz.dart` — `Navigator.pop` (не уход на «Услуги»).

Симметрия с исполнителем (`reviews`, `SendReviewForm.dart`, `check_order_status.php`) — [app_scenarios_ru.md](./app_scenarios_ru.md) §3.4.

### 14.3. Чеклист

- [ ] Завершить заказ как заказчик → появляется запрос отзыва
- [ ] «Позже» → вкладка «Заказы» всё ещё ведёт на экран выполнения (`needs_review`)
- [ ] Повторная работа с тем же исполнителем → «Изменить отзыв»
- [ ] После отзыва — подсветка вкладки «Заказы» гаснет, открывается поиск

---
