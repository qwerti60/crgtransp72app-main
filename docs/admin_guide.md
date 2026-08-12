# Руководство по веб-админке CRG Transp72

Браузерный интерфейс для модерации пользователей и объявлений, справочников и просмотра откликов, предложений и отзывов.

**Свод сценариев приложения (сделки, поиск, чаты):** [app_scenarios_ru.md](./app_scenarios_ru.md)

---

## 1. Запуск локально

```bash
cd /path/to/crgtransp72app-main

# База и справочники
mysql --default-character-set=utf8mb4 -u root < sql/local_dev.sql

# Учётка админа (если local_dev.sql уже был без admin_accounts)
mysql --default-character-set=utf8mb4 -u root crg_local < sql/migrate_admin_accounts.sql

# Пользователи, объявления, отклики, отзывы (тестовые данные)
mysql --default-character-set=utf8mb4 -u root crg_local < sql/migrate_admin_users_ads.sql
./scripts/seed_test_ads.sh

# Конфиг БД (если ещё нет)
cp api/databd.local.example.php api/databd.local.php

# Сброс пароля админа по e-mail (таблица OTP)
mysql --default-character-set=utf8mb4 -u root crg_local < sql/migrate_admin_password_reset.sql

# Журнал оплат подписки (выручка в статистике и финансы исполнителя)
mysql --default-character-set=utf8mb4 -u root crg_local < sql/migrate_subscription_payment_log.sql

# Сервер
cd api && php -S 127.0.0.1:8080
```

**Адреса:**

| Страница | URL (локально) |
|----------|----------------|
| Статистика | http://127.0.0.1:8080/admin-web/stats.php |
| Вход | http://127.0.0.1:8080/admin-web/login.php |
| Сброс пароля | http://127.0.0.1:8080/admin-web/login_reset.php |
| Настройки | http://127.0.0.1:8080/admin-web/settings.php (после входа) |

**Вход по умолчанию:** логин `admin`, пароль `ChangeMe_Admin1!`  
После входа: **Статистика** → **Настройки** → e-mail → сменить пароль. Сброс без входа: `login_reset.php` (см. §5).

Файл `api/databd.local.php` имеет приоритет над `databd.php` — используется и админкой, и API приложения.

---

## 2. Разделы меню

| Раздел | Назначение |
|--------|------------|
| **Статистика** | Сводка KPI, **выручка подписок**, GMV сделок, аналитика подписок |
| **Города** | Справочник `cities` для фильтров в приложении |
| **Вид техники** | Таблица `vidt` (+ картинки) |
| **Грузоподъёмность** | Таблица `vidg` |
| **Вид кузова** | Таблица `vidkuzov` |
| **Пользователи** | Регистрации приложения, модерация `flag` |
| **Объявления исполнителей** | `add_ob_gp`, `add_ob_vidt`, `add_ob_gr` |
| **Заявки заказчиков** | `orders`, `orderst`, `ordersg` |
| **Рассылка** | Массовая отправка e-mail и/или FCM push |
| **Пакеты** | `subscription_packages` — тарифы P1 |
| **Промокоды** | `promo_codes`, `promo_redemptions` |
| **Поднятие** | `ad_boost_tariffs`, `ad_boosts` — P2 |
| **Поддержка** | `support_tickets`, deal-чат readonly — P1 |
| **Счета B2B** | `subscription_invoice_requests` — P3 |
| **Автомодерация** | `moderation_stop_words`, `moderation_log` — P3 |
| **Экспорт CSV** | `admin_export.php` — P3 |
| **Настройки** | Legacy `subscription_config`, e-mail и пароль администратора |

Красная точка: **Объявления исполнителей** (`flag=0`), **Поддержка** (новые тикеты), **Счета B2B** (статусы `requested`/`issued`).

После входа открывается **Статистика** (`stats.php`).

---

## 3. Статистика

**Страница:** `stats.php` · **Логика:** `api/include/admin_stats.php`, `api/include/performer_finances.php`

Сводка без графических библиотек: KPI-карточки, таблицы, горизонтальные полоски. Отсутствующие таблицы в БД пропускаются без ошибки.

### Параметры периода (GET)

| Параметр | Значения | Назначение |
|----------|----------|------------|
| `period` | `day`, `week`, `month`, `all`, `custom` | Период для выручки и аналитики подписок (по умолчанию `month`) |
| `from`, `to` | `YYYY-MM-DD` | Для `period=custom` |

Пример: `stats.php?period=week` · `stats.php?period=custom&from=2026-06-01&to=2026-06-30`

### Функции бэкенда

| Функция | Файл | Назначение |
|---------|------|------------|
| `crg_admin_stats_dashboard($pdo, $opts)` | `admin_stats.php` | Полная сводка; `$opts`: `period`, `from`, `to` |
| `crg_admin_stats_subscription_analytics()` | `admin_stats.php` | Метрики подписок за период и all-time |
| `crg_admin_stats_platform_finances()` | `admin_stats.php` | Выручка подписок + GMV сделок |
| `crg_finances_resolve_period()` | `performer_finances.php` | Границы дат для day/week/month/custom |
| `crg_finances_fetch_platform_income()` | `performer_finances.php` | Сумма выполненных сделок по платформе |

### Блоки на странице

| Блок | Источник данных |
|------|-----------------|
| **Выручка и оборот** | `subscription_payment_log` (SUM `amount_rub`), `ordersglobal` + `offer_data` / `offer_dataf` (GMV) |
| **Подписки за период** | `subscription_payment_log` — count, new vs renewal (подзапрос `prior_cnt`) |
| **Срез подписок** | `subscriptions` (latest row per `iduser`), `users.rollNum IN (2,3,4)` |
| Пользователи | `users` — total, `rollNum`, `city`, `created_at`, `fcm_token`, `flag` |
| Объявления исполнителей | `add_ob_gp`, `add_ob_vidt`, `add_ob_gr` — `flag`, loop через `crg_admin_performer_ad_types()` |
| Заявки заказчиков | `orders`, `orderst`, `ordersg` — active: `enddatez >= CURDATE()` |
| Отклики | `offer_data` — `bd`, `status`, `cena`, `timestamp` |
| Предложения | `offer_dataf` — `bd`, `cena` |
| Отзывы | `reviewsisp`, `reviews` — rating distribution |
| Сделки | `ordersglobal` — `status` |

### Метрики подписок (детально)

| KPI | SQL / логика |
|-----|----------------|
| `revenue_rub` | `SUM(amount_rub)` из `subscription_payment_log` за период |
| `new_subscriptions` | Платёж, у которого нет более ранних записей того же `iduser` |
| `renewals` | Платёж с `prior_cnt > 0` |
| `not_renewed` | Latest `subscriptions.date < CURDATE()` AND `count >= 1` |
| `never_subscribed` | Исполнители без строки в `subscriptions` |
| `est_revenue_rub` / MRR | `active × subscription_config.price_rub` (оценка, не факт) |
| `expired_in_period` | Latest `subscriptions.date` между `from` и `to` |

Без таблицы `subscription_payment_log` блок выручки пустой; срез по `subscriptions` всё равно работает.

**Оплаты по дням:** `crg_admin_stats_payments_by_day()` — GROUP BY `DATE(paid_at)`.

**Последние оплаты:** `crg_admin_stats_recent_payments()` — JOIN `users`, флаг `is_renewal`.

**Воронка (P2):** `crg_admin_stats_funnel()` в `admin_stats.php` — блок на `stats.php`: регистрации → объявления → отклики → сделки → оплаты подписки.

---

## 4. Пользователи

**Список** (`users.php`): поиск по имени, e-mail, телефону, городу; фильтры по роли и статусу проверки.

**Роли (`rollNum`):**

| Значение | Роль |
|----------|------|
| 1 | Заказчик |
| 2 | Грузоперевозчик |
| 3 | Спецтехника |
| 4 | Грузчики |

**Статус проверки (`flag`):**

| Значение | Смысл |
|----------|--------|
| 0 | На проверке — пользователь не одобрен |
| 1 | Одобрен — доступ в приложении |

На карточке пользователя:

- редактирование профиля и пароля;
- счётчики объявлений со ссылками;
- **Отзывы об исполнителе** (таблица `reviewsisp`, если роль исполнителя);
- **Отзывы о заказчике** (таблица `reviews`, если роль заказчика).

Удаление пользователя удаляет и его объявления.

### Подписка исполнителя

Только для ролей **исполнитель** (грузоперевозчик, спецтехника, грузчики). Заказчикам подписка не нужна.

| Таблица | Назначение |
|---------|------------|
| `subscriptions` | Подписка пользователя: `iduser`, `date` (окончание), `payment` (ID платежа), `count` (число оплат) |
| `subscription_config` | Тариф: `days`, `price_rub`, `is_active` — редактируется в админке (**Настройки**) |
| `subscription_payment_log` | История оплат (миграция `sql/migrate_subscription_payment_log.sql`) |

**Статус** (как в `check_subscription.php`):

| Условие | Статус |
|---------|--------|
| Нет строки в `subscriptions` | Не оформлена |
| `date` ≥ сегодня | Активна |
| `date` < сегодня | Истекла |

Оплата в приложении: `PaymentPage` → `payment-proxy.php` → `update_subscription.php` (продление на `days` из конфига). Тариф читается через `get_subscription_config.php`. Без активной подписки исполнитель видит экран оформления подписки.

В админке: колонка **Подписка** в списке пользователей; на карточке исполнителя — блок с датой окончания, ID платежа и числом оплат; ссылка **Финансы**; **Настройки** — изменение цены и срока тарифа.

### Финансы исполнителя (карточка пользователя)

**Рендер:** `api/include/admin_finances.php` → `crg_admin_render_performer_finances()`  
**Логика:** `api/include/performer_finances.php`  
**Мобильное API:** `api/get_performer_finances.php`

| Таблица | Назначение |
|---------|------------|
| `subscription_payment_log` | Журнал оплат: `iduser`, `order_id`, `amount_rub`, `days_added`, `paid_at`, `subscription_until` |
| `ordersglobal` + `offer_data` / `offer_dataf` | Доход по **выполненным** сделкам (`status = 'выполнен'`) |

Запись в журнал при оплате: `update_subscription.php` → `crg_finances_log_subscription_payment()`.

GET-параметры на `user_edit.php?id=…`:

| Параметр | Значения |
|----------|----------|
| `fin_period` | `day`, `week`, `month`, `custom` |
| `fin_from`, `fin_to` | Даты для `custom` |

Якорь: `#user-finances`.

---

## 5. Настройки и авторизация

**Страница настроек:** `settings.php`

### Авторизация администратора

| Таблица / файл | Назначение |
|----------------|------------|
| `admin_accounts` | `login`, `email`, `password_hash`, `token` (сессия) |
| `admin_login_verify.php` | Проверка логина/пароля, выдача `token` в сессию |
| `admin_auth.php` | Проверка `token` на каждой странице |
| `admin_password_reset_otp` | OTP-коды сброса: `login`, `code`, `expires_at` |

Сессия веб-админки: `$_SESSION['admin_web_token']` = `admin_accounts.token`. Logout обнуляет token в БД.

**Миграции:** `sql/migrate_admin_accounts.sql`, `sql/migrate_admin_password_reset.sql`.

### Учётная запись администратора (`settings.php`)

| Поле / действие | БД / файлы |
|-----------------|------------|
| E-mail | `admin_accounts.email` — нужен для кода сброса пароля |
| Смена пароля (знаю текущий) | `admin_password_service.php` → `tp_admin_password_change_with_old` |
| Сброс по коду (в настройках) | `tp_admin_password_request_reset_otp` + `tp_admin_password_reset_logged_in_with_code` |
| Сброс без входа | `login_reset.php` → `tp_admin_password_complete_reset` |

Письма: `admin_mail.php` (`crg_admin_send_plain_mail`, отправитель `CRG_MAIL_FROM` или `crg_site_mail_from()` из `include/site_config.php`).

Минимальная длина нового пароля — **10** символов (`TP_ADMIN_PASSWORD_MIN_LEN`). После смены пароля `token` сбрасывается — нужен повторный вход.

**Сброс без входа (`login_reset.php`):**

1. POST `action=request` — логин → 6-значный код на e-mail.
2. POST `action=complete` — логин + код + новый пароль.

Ответ на шаг 1 намеренно не раскрывает, существует ли логин (если e-mail не задан — письмо не уйдёт, но сообщение то же).

Переменные окружения (опционально):

| Переменная | Назначение |
|------------|------------|
| `CRG_MAIL_FROM` | Отправитель писем |
| `CRG_ADMIN_PASSWORD_RESET_FALLBACK` | Запасной e-mail, если у учётки не задан свой |
| `CRG_ADMIN_PASSWORD_OTP_TTL` | Срок жизни кода в секундах (120–3600, по умолчанию 900) |

### Тариф подписки исполнителя

**Логика:** `api/include/admin_subscriptions.php` (`crg_admin_subscription_config_save`)

| Поле | Колонка БД | API |
|------|------------|-----|
| Цена, ₽ | `subscription_config.price_rub` | `get_subscription_config.php` → `price_rub`, `amount_kopecks` |
| Срок, дней | `subscription_config.days` | `get_subscription_config.php` → `days`; `update_subscription.php` при оплате |

Обновляется активная запись (`is_active = 1`, последняя по `id`). Изменение не пересчитывает уже оплаченные подписки.

---

## 6. Рассылка

**Страница:** `broadcast.php`  
**Логика:** `api/include/admin_broadcast.php`  
**Каналы:** plain-text e-mail (`admin_mail.php`) и FCM push (`fcm_push.php`, `users.fcm_token`, `api/service_account.json`).

### Аудитория

| Ключ | SQL-логика |
|------|------------|
| `all` | Все строки `users` |
| `city` | `users.city IN (...)` — список из справочника `cities` или DISTINCT из профилей |
| `subscription_ending_3` | JOIN `subscriptions` WHERE `s.date = CURDATE() + 3 days` |
| `subscription_expired` | JOIN `subscriptions` WHERE `s.date < CURDATE()` |
| `role` | `users.rollNum IN (1..4)` |
| `selected` | `users.idusers IN (...)` |

Пользователи с несколькими строками подписки дедуплицируются по `idusers`. Если колонки `fcm_token` нет (старый дамп), push пропускается для всех, e-mail работает.

### Форма

- Тема — subject письма и title push.
- Текст — тело письма; для push обрезается через `crg_admin_notify_excerpt()` (~240 символов).
- Кнопка **Проверить выборку** — только подсчёт без отправки.
- Лимит **2000** получателей за один POST; CSRF на все действия.

### Отправка одному пользователю

Шаблон письма: приветствие по display name + текст + подпись «CRG Transp72». Ошибки SMTP/FCM — в сводке (до 5 примеров).

---

## 7. Объявления исполнителей

Три вкладки (переключатель типа):

| Тип | Таблица | Категория `bd` |
|-----|---------|----------------|
| gp | `add_ob_gp` | 1 — грузоперевозки |
| vidt | `add_ob_vidt` | 2 — спецтехника |
| gr | `add_ob_gr` | 3 — грузчики |

**Модерация:** `flag = 0` — на проверке, `flag = 1` — опубликовано. Неопубликованные объявления не видны заказчикам в приложении.

**Карточка объявления:**

- одобрение / снятие с публикации;
- поля объявления (подписи как в приложении);
- фото и документы (BLOB) — клик по превью открывает просмотр;
- **Предложения заказчиков** (`offer_dataf`) — только для **опубликованных** объявлений;
- **Отклонение** — e-mail + push в приложение (`fcm_push.php`, `users.fcm_token`, `service_account.json`);
- **Автомодерация (P3)** — после INSERT в `add_ob_*.php` вызывается `crg_ad_auto_moderate_hook()` → `api/include/ad_auto_moderation.php` (стоп-слова, пустые фото, дубли);
- **Отзывы об исполнителе** (`reviewsisp`) — по владельцу объявления.

Фильтр `?user=ID` в списке — объявления конкретного пользователя.

---

## 8. Заявки заказчиков

| Тип | Таблица | Категория `bd` |
|-----|---------|----------------|
| orders | `orders` | 1 |
| orderst | `orderst` | 2 |
| ordersg | `ordersg` | 3 |

У заявок нет поля `flag` — публикуются сразу.

**Шаблоны (P2):** `get_customer_ad_templates.php`, `duplicate_customer_ad.php` — Flutter `ad_template_picker_screen.dart`.

**Карточка заявки:**

- поля заявки;
- фото;
- **Отклики исполнителей** (`offer_data`, статус: Активный / Принят);
- **Отзывы о заказчике** (`reviews`) — по автору заявки.

---

## 9. Отклики, предложения, отзывы

### Отклики исполнителей на заявку — `offer_data`

| Поле | Значение |
|------|----------|
| `iduser` | id заявки заказчика |
| `iduserp` | id исполнителя |
| `bd` | категория (1/2/3) |
| `status` | 0 — активный, 1 — принят |

### Предложения заказчиков на объявление — `offer_dataf`

| Поле | Значение |
|------|----------|
| `iduser` | id объявления исполнителя |
| `iduserp` | id заказчика |
| `bd` | категория |

### Отзывы об исполнителе — `reviewsisp`

| Поле | Значение |
|------|----------|
| `user_id` | исполнитель (о ком отзыв) |
| `target_user_id` | заказчик (автор отзыва) |

API приложения: `review_apiz.php`, сохранение — `save_reviewzaka.php`.

### Отзывы о заказчике — `reviews`

| Поле | Значение |
|------|----------|
| `user_id` | исполнитель (автор) |
| `target_user_id` | заказчик (о ком отзыв) |

API приложения: `review_api.php`, сохранение — `save_review.php`.

---

## 10. Справочники и города

**Города** — CRUD по таблице `cities`. При переименовании можно обновить название в связанных таблицах. Удаление — только если город нигде не используется.

**Справочники** (`vidt`, `vidg`, `vidkuzov`) — список, добавление, редактирование с загрузкой JPEG/PNG в BLOB, удаление. При переименовании — опциональное обновление в объявлениях и профилях.

---

## 11. Поиск в приложении (связь с админкой)

Поиск исполнителей и заявок выполняется **в мобильном приложении**, не в веб-админке. Администратор и менеджер **не запускают поиск за пользователя**, но от действий в админке зависит, **попадёт ли объявление в выдачу**.

Подробная спецификация алгоритма: **[search_logic_ru.md](./search_logic_ru.md)**.

### 11.1. Два режима поиска в приложении

| Режим | Где в приложении | API | Когда используется |
|-------|------------------|-----|------------------|
| **Классический** | Услуги → город → список | `get_cities.php` / `get_citiesisp.php` → `get_ads2_new.php` (исполнители) или `getads3.php` (заявки) | выбор раздела и города по шагам |
| **Расширенный** | Вкладка «Заказы» / «Заявки», кнопки «Найти исполнителей» / «Найти заявки» | `search_services.php` + `api/include/search_services_core.php` | форма поиска, текстовый запрос, фильтры |

| Кто ищет | Что в результате | Параметр `role` |
|----------|------------------|-----------------|
| Заказчик | объявления **исполнителей** | `customer` |
| Исполнитель | **заявки заказчиков** | `performer` |

При недоступности `search_services.php` приложение для части сценариев откатывается на `get_ads2_new.php` / `getads3.php` (нужны **город** и **услуга**).

### 11.2. Справочники и категории поиска

Список услуг в форме поиска (`getsearsh.php`) — объединение таблиц:

| Таблица | Раздел `bd` | Поле в объявлении | Раздел админки |
|---------|-------------|-------------------|----------------|
| `vidg` | 1 — грузоперевозки | `maxgruz` | **Грузоподъёмность** |
| `vidt` | 2 — спецтехника | `vidt` | **Вид техники** |
| `gruzchik` | 3 — грузчики | — | *(отдельная категория)* |

**Города** — таблица `cities`, раздел **Города** в админке.

| Действие в админке | Влияние на поиск |
|--------------------|------------------|
| Добавить город | появится в выпадающем списке приложения |
| Переименовать город | нужно согласовать обновление в объявлениях; иначе старые строки `city` не совпадут с новым названием |
| Добавить / переименовать пункт `vidt` / `vidg` | меняется список «Услуга»; название должно совпадать с полем в объявлении |
| Удалить город / справочник | только если нигде не используется |

> **Точное совпадение строк:** фильтр по городу — `city = 'Тюмень'`, не «тюмень» и не «г. Тюмень». Единообразие названий — задача справочников и модерации.

### 11.3. Что скрывает объявление из поиска

| Условие | Где проверяется | Что делать в админке |
|---------|-----------------|----------------------|
| Объявление исполнителя **не опубликовано** (`flag = 0`) | `search_services_core.php`, `get_ads2_new.php` | **Объявления исполнителей** → одобрить |
| У исполнителя **нет активной подписки** | `check_subscription.php` | **Пользователи** → подписка; **Настройки** → тариф |
| Заявка заказчика **просрочена** (`enddatez < сегодня`) | расширенный и классический поиск заявок | объяснить заказчику продление в приложении |
| Объявление уже **в сделке** (принят отклик / `ordersglobal`) | исключение в SQL | нормальное поведение |
| Пользователь **не одобрен** (`users.flag = 0`) | доступ в приложении ограничен | **Пользователи** → одобрить |
| На сервере **нет** `search_services_core.php` | `search_services.php` → ошибка / fallback | залить файл на хост (см. §11.6) |

### 11.4. Расширенный поиск — параметры API

**Endpoint:** `GET /api/search_services.php`

| Параметр | Описание |
|----------|----------|
| `role` | `customer` \| `performer` |
| `nameImg` | название услуги из справочника (как в `getsearsh.php`) |
| `city` | город из `cities` |
| `q` | текстовый запрос |
| `free_text=1` | режим «только строка» — город и категория извлекаются из `q` |
| `all_cities=1` | без фильтра по городу |
| `city_to` | город назначения (заявки грузоперевозок, bd=1) |
| `price_max` | бюджет |
| `sort` | `relevance` \| `rating` \| `price` \| `date` |
| `usersid` / `useId` | текущий пользователь (исключить свои объявления) |

**Текстовый поиск** (`free_text` или пустые `nameImg` + непустой `q`):

- слова короче 3 символов игнорируются;
- город ищется по вхождению названия из `cities` в строку (например «экскаватор в Тюмени»);
- категория — по вхождению названий из `vidg` / `vidt` / `gruzchik`;
- если категория не распознана — поиск по всем трём разделам (`bd` 1, 2, 3).

**Сортировка по рейтингу** использует те же таблицы отзывов, что и карточки в приложении: `reviewsisp` (о исполнителе), `reviews` (о заказчике).

### 11.5. Быстрый подбор из «Мои объявления»

| Роль | Кнопка | Логика |
|------|--------|--------|
| Заказчик | «Найти исполнителей» | город + категория из заявки → `search_services.php`; при пустой выдаче — форма поиска |
| Исполнитель | «Найти заявки» | то же для supply-объявления |

Модератору: если пользователь жалуется «ничего не находит» — проверить **опубликовано ли объявление**, **город и категорию** в карточке, **подписку** (исполнитель), **срок заявки** (заказчик).

### 11.6. Деплой API поиска на сервер

Для работы расширенного поиска на prod нужны **оба** файла:

| Файл | Назначение |
|------|------------|
| `api/search_services.php` | точка входа |
| `api/include/search_services_core.php` | алгоритм (обязателен; без него — HTML-ошибка или fallback) |

Проверка:

```bash
curl -sS "https://ваш-домен/api/search_services.php?role=customer&nameImg=Экскаваторы&city=Тюмень&usersid=1"
```

Ответ должен быть JSON-массивом, не HTML с `Fatal error`.

### 11.7. Поиск **внутри** веб-админки (локальные фильтры)

Не путать с поиском в приложении — это фильтрация **списков** в admin-web:

| Страница | Параметр | Поля поиска |
|----------|----------|-------------|
| `users.php` | `?q=` | имя, e-mail, телефон, город |
| `performer_ads.php` | `?q=` | город, марка, … |
| `customer_ads.php` | `?q=` | город, маршрут, … |
| `cities.php`, `ref_list.php` | `?q=` | название справочника |

Логика: `api/include/admin_users.php`, `admin_ads.php`, `admin_cities.php`, `admin_ref_lists.php`.

---

## 11.8. Пакеты доработок P1–P3 (файлы и миграции)

| Пакет | Миграция | Ключевые admin-web | API / include | Flutter |
|-------|----------|-------------------|---------------|---------|
| **P1** | `migrate_city_geo.sql`, `migrate_subscription_packages.sql` | `packages.php`, `promo_codes.php`, `support_queue.php`, `deal_chat_view.php` | `search_services_core.php`, `deal_push.php`, `subscription_packages.php` | геофильтры, `PaymentPage`, жалобы |
| **P2** | `migrate_p2_features.sql` | `boost_tariffs.php`, `stats.php` (воронка), `user_edit.php` (`is_verified`) | `ad_boost.php`, `apply_ad_boost.php`, шаблоны, `update_order_transit.php` | онбординг, boost, шаблоны, «в пути» |
| **P3** | `migrate_p3_features.sql` | `invoices.php`, `moderation.php`, `export.php` | `ad_auto_moderation.php`, `subscription_invoices.php`, `admin_export.php` | «Запросить счёт» в `PaymentPage` |

**Деплой:** `./scripts/pack_p1_deploy.sh`, `pack_p2_deploy.sh`, `pack_p3_deploy.sh` → `dist/p*_deploy_*.zip`.  
**Чеклисты:** [deploy_p1_checklist.md](./deploy_p1_checklist.md), [deploy_p2_checklist.md](./deploy_p2_checklist.md), [deploy_p3_checklist.md](./deploy_p3_checklist.md).  
**Тестирование:** [testing_guide_ru.md](./testing_guide_ru.md).

### P1 — гео, жалобы, push, пакеты

- Гео: `cities.lat/lng`, параметры `lat`, `lng`, `radius_km`, `sort=distance` в `search_services.php`.
- Жалобы: `support/create.php` → `support_queue.php`, категории `deal_dispute`, `ad_moderation`.
- Push сделки: `api/include/deal_push.php`, cron `subscription_reminders.php`.
- Подписка: `get_subscription_packages.php`, `validate_promo.php`, `update_subscription.php`.

### P2 — онбординг, топ, верификация, шаблоны, в пути, воронка

- `users.is_verified`, `ad_boost_tariffs` / `ad_boosts`, `ordersglobal` + `в_пути`, ETA.
- Flutter: `onboarding_screen.dart`, `ad_boost_screen.dart`, `OrderExecutionScreen.dart`.

### P3 — B2B, автомодерация, CSV

- `subscription_invoice_requests` — `request_subscription_invoice.php`, `get_subscription_invoices.php`.
- Автомодерация: хук в `add_ob_gp.php`, `add_ob_vidt.php`, `add_ob_gr.php`.
- CSV: `export.php?type=users|payments|deals`.

---

## 12. Установка на сервер

1. Импорт prod-дампа (при необходимости):  
   `mysql -u USER -p u2395188_apps < u2395188_apps.sql`

2. Миграция учётки админа:  
   `mysql -u USER -p u2395188_apps < sql/migrate_admin_accounts.sql`

3. Миграция сброса пароля (OTP по e-mail):  
   `mysql -u USER -p u2395188_apps < sql/migrate_admin_password_reset.sql`

3a. Журнал оплат подписки (выручка в статистике, финансы на карточке):  
   `mysql -u USER -p u2395188_apps < sql/migrate_subscription_payment_log.sql`

3b. **P1** (если ещё не применено):  
   `migrate_city_geo.sql`, `migrate_subscription_packages.sql`

3c. **P2:** `migrate_p2_features.sql`

3d. **P3:** `migrate_p3_features.sql`

4. Залить на хост каталоги `api/admin-web/` и `api/include/` (архивы `dist/p1_deploy_*.zip`, `p2_deploy_*.zip`, `p3_deploy_*.zip` или rsync). Не перезаписывать `databd.php`, `service_account.json`.

5. **Первый вход:** войти как `admin`, в **Настройки** указать e-mail и сменить пароль. Альтернатива — SQL:
   ```php
   echo password_hash('новый_пароль', PASSWORD_DEFAULT);
   ```  
   ```sql
   UPDATE admin_accounts SET password_hash = '...' WHERE login = 'admin';
   ```

6. Админка: `https://ваш-домен/admin-web/login.php` · сброс пароля: `.../admin-web/login_reset.php`

Подробная инструкция заливки на хост: **`docs/deploy_admin_host.md`**.

---

## 13. Структура файлов

```
api/
├── admin-web/
│   ├── login.php, login_reset.php, logout.php
│   ├── manager_guide.php, guide.php
│   ├── cities.php, ref_*.php
│   ├── users.php, user_edit.php
│   ├── performer_ads.php, performer_ad_view.php
│   ├── customer_ads.php, customer_ad_view.php
│   ├── stats.php
│   ├── broadcast.php
│   ├── packages.php, promo_codes.php, boost_tariffs.php
│   ├── support_queue.php, support_view.php, deal_chat_view.php
│   ├── invoices.php, moderation.php, export.php
│   └── settings.php
├── search_services.php
└── include/
    ├── admin_auth.php, admin_login_verify.php
    ├── admin_password_service.php
    ├── admin_mail.php, fcm_push.php
    ├── admin_cities.php, admin_ref_lists.php
    ├── admin_users.php, admin_ads.php
    ├── admin_stats.php
    ├── admin_finances.php
    ├── performer_finances.php
    ├── admin_broadcast.php
    ├── admin_subscriptions.php
    ├── subscription_packages.php
    ├── ad_boost.php, ad_auto_moderation.php
    ├── subscription_invoices.php, admin_export.php
    ├── admin_support.php, deal_push.php
    ├── admin_reviews.php
    └── search_services_core.php
```

**SQL-миграции админки:**

| Файл | Содержимое |
|------|------------|
| `sql/local_dev.sql` | База `crg_local`, справочники, `admin_accounts`, OTP |
| `sql/migrate_admin_accounts.sql` | `admin_accounts` + admin по умолчанию |
| `sql/migrate_admin_password_reset.sql` | `admin_password_reset_otp`, колонка `email` |
| `sql/migrate_admin_users_ads.sql` | Тестовые users/ads, subscriptions, reviews |
| `sql/migrate_subscription_payment_log.sql` | `subscription_payment_log` — журнал оплат, выручка в stats |
| `sql/migrate_city_geo.sql` | Координаты городов (P1) |
| `sql/migrate_subscription_packages.sql` | Пакеты и промокоды (P1) |
| `sql/migrate_p2_features.sql` | Boost, верификация, ETA, воронка (P2) |
| `sql/migrate_p3_features.sql` | B2B-счета, автомодерация (P3) |

---

## 14. Типичные задачи

| Задача | Действие |
|--------|----------|
| Сводка по приложению | **Статистика** (`stats.php`) |
| Выручка подписок за период | **Статистика** → `period=day|week|month|all|custom` |
| История оплат исполнителя | **Пользователи** → `user_edit.php?id=…#user-finances` |
| Доход исполнителя по сделкам | То же, блок «Доходы», `fin_period` |
| Первый вход / e-mail админа | **Настройки** → e-mail → сменить пароль |
| Одобить нового пользователя | Пользователи → карточка → статус «Одобрен» или кнопка на списке |
| Опубликовать объявление | Объявления исполнителей → карточка → «Одобрить и опубликовать» |
| Посмотреть отклики на заявку | Заявки заказчиков → карточка → блок «Отклики исполнителей» |
| Посмотреть предложения | Объявления исполнителей → опубликованное → «Предложения заказчиков» |
| Рейтинг исполнителя | Карточка пользователя или объявления → «Отзывы об исполнителе» |
| Рейтинг заказчика | Карточка пользователя или заявки → «Отзывы о заказчике» |
| Подписка исполнителя | Пользователи → колонка «Подписка» или карточка → блок «Подписка исполнителя» |
| Изменить цену/срок подписки | **Настройки** → сохранить тариф |
| Сменить пароль админа | **Настройки** → смена пароля или `login_reset.php` |
| Рассылка по подписке / городу / роли | **Рассылка** → **Проверить выборку** → **Отправить** |
| Отклонить объявление с уведомлением | Объявления исполнителей → карточка → **Отклонить и уведомить** |
| Пользователь не видит исполнителей в поиске | §11: опубликовать объявления (`flag=1`), подписка, город/категория в справочниках, `search_services_core.php` на сервере |
| Жалоба «поиск ничего не находит» | Проверить заявку: `enddatez`, город; исполнителя: `flag`, подписка; см. [search_logic_ru.md](./search_logic_ru.md) |
| Инструкция для менеджера | Меню → **Руководство** (`manager_guide.php`) |
| Инструкция для разработчика | Меню → **Техническое** (`guide.php`) |

---

## 15. Связанная документация

| Файл | Страница / назначение | Аудитория |
|------|----------------------|-----------|
| `docs/admin_manager_guide.md` | `manager_guide.php` | Менеджер: модерация, без SQL и API |
| `docs/admin_guide.md` | `guide.php` | Разработчик / администратор сервера |
| `docs/testing_guide_ru.md` | — | **Как проверить P1–P3** (приложение + админка) |
| `docs/deploy_p1_checklist.md` | — | Деплой и smoke P1 |
| `docs/deploy_p2_checklist.md` | — | Деплой и smoke P2 |
| `docs/deploy_p3_checklist.md` | — | Деплой и smoke P3 |
| `docs/deploy_admin_host.md` | — | Заливка на хост |
| `docs/app_scenarios_ru.md` | — | Свод сценариев приложения |
| `docs/search_logic_ru.md` | — | Алгоритм поиска |
| `docs/deals_logic_ru.md` | — | Сделки, offer_data, ordersglobal |
| `docs/chat_logic_ru.md` | — | Чаты и техподдержка |

---

*Документ в репозитории: `docs/admin_guide.md`. Для менеджера: `docs/admin_manager_guide.md`.*
