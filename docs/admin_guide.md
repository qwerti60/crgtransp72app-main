# Руководство по веб-админке CRG Transp72

Браузерный интерфейс для модерации пользователей и объявлений, справочников и просмотра откликов, предложений и отзывов.

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
| **Статистика** | Сводка KPI: users, ads, subscriptions, offers, reviews |
| **Города** | Справочник `cities` для фильтров в приложении |
| **Вид техники** | Таблица `vidt` (+ картинки) |
| **Грузоподъёмность** | Таблица `vidg` |
| **Вид кузова** | Таблица `vidkuzov` |
| **Пользователи** | Регистрации приложения, модерация `flag` |
| **Объявления исполнителей** | `add_ob_gp`, `add_ob_vidt`, `add_ob_gr` |
| **Заявки заказчиков** | `orders`, `orderst`, `ordersg` |
| **Рассылка** | Массовая отправка e-mail и/или FCM push |
| **Настройки** | Тариф подписки, e-mail и пароль администратора |

Красная точка у «Объявления исполнителей» — есть объявления со статусом **На проверке** (`flag = 0`).

После входа открывается **Статистика** (`stats.php`).

---

## 3. Статистика

**Страница:** `stats.php` · **Логика:** `api/include/admin_stats.php`

Сводка без графических библиотек: KPI-карточки, таблицы, горизонтальные полоски. Отсутствующие таблицы в БД пропускаются без ошибки.

| Блок | Источник данных |
|------|-----------------|
| Пользователи | `users` — total, `rollNum`, `city`, `created_at`, `fcm_token`, `flag` |
| Объявления исполнителей | `add_ob_gp`, `add_ob_vidt`, `add_ob_gr` — `flag`, loop через `crg_admin_performer_ad_types()` |
| Заявки заказчиков | `orders`, `orderst`, `ordersg` — active: `enddatez >= CURDATE()` |
| Подписки | `subscriptions` (latest row per user), `subscription_config` — оценка выручки |
| Отклики | `offer_data` — `bd`, `status`, `cena`, `timestamp` |
| Предложения | `offer_dataf` — `bd`, `cena` |
| Отзывы | `reviewsisp`, `reviews` — rating distribution |
| Сделки | `ordersglobal` — `status` (если таблица есть) |

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

**Статус** (как в `check_subscription.php`):

| Условие | Статус |
|---------|--------|
| Нет строки в `subscriptions` | Не оформлена |
| `date` ≥ сегодня | Активна |
| `date` < сегодня | Истекла |

Оплата в приложении: `PaymentPage` → `payment-proxy.php` → `update_subscription.php` (продление на `days` из конфига). Тариф читается через `get_subscription_config.php`. Без активной подписки исполнитель видит экран оформления подписки.

В админке: колонка **Подписка** в списке пользователей; на карточке исполнителя — блок с датой окончания, ID платежа и числом оплат; **Настройки** — изменение цены и срока тарифа.

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

Письма: `admin_mail.php` (`crg_admin_send_plain_mail`, отправитель `CRG_MAIL_FROM` или `no-reply@ivnovav.ru`).

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

## 11. Установка на сервер

1. Импорт prod-дампа (при необходимости):  
   `mysql -u USER -p u2395188_apps < u2395188_apps.sql`

2. Миграция учётки админа:  
   `mysql -u USER -p u2395188_apps < sql/migrate_admin_accounts.sql`

3. Миграция сброса пароля (OTP по e-mail):  
   `mysql -u USER -p u2395188_apps < sql/migrate_admin_password_reset.sql`

4. Залить на хост каталоги `api/admin-web/` и `api/include/` (и остальной `api/` без перезаписи `databd.php` с prod-паролями).

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

## 12. Структура файлов

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
│   └── settings.php
└── include/
    ├── admin_auth.php, admin_login_verify.php
    ├── admin_password_service.php
    ├── admin_mail.php, fcm_push.php
    ├── admin_cities.php, admin_ref_lists.php
    ├── admin_users.php, admin_ads.php
    ├── admin_stats.php
    ├── admin_broadcast.php
    ├── admin_subscriptions.php
    └── admin_reviews.php
```

**SQL-миграции админки:**

| Файл | Содержимое |
|------|------------|
| `sql/local_dev.sql` | База `crg_local`, справочники, `admin_accounts`, OTP |
| `sql/migrate_admin_accounts.sql` | `admin_accounts` + admin по умолчанию |
| `sql/migrate_admin_password_reset.sql` | `admin_password_reset_otp`, колонка `email` |
| `sql/migrate_admin_users_ads.sql` | Тестовые users/ads, subscriptions, reviews |

---

## 13. Типичные задачи

| Задача | Действие |
|--------|----------|
| Сводка по приложению | **Статистика** (`stats.php`) |
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
| Инструкция для менеджера | Меню → **Руководство** (`manager_guide.php`) |
| Инструкция для разработчика | Меню → **Техническое** (`guide.php`) |

---

## 14. Два руководства

| Файл | Страница | Аудитория |
|------|----------|-----------|
| `docs/admin_manager_guide.md` | `manager_guide.php` | Менеджер: модерация, без SQL и API |
| `docs/admin_guide.md` | `guide.php` | Разработчик / администратор сервера |

---

*Документ в репозитории: `docs/admin_guide.md`. Для менеджера: `docs/admin_manager_guide.md`.*
