# Заливка админки CRG Transp72 на хост

Инструкция для замены данных приложения и публикации веб-админки на production-сервере (shared hosting / VPS).

---

## 1. Что заливаем

| Каталог / файл | Назначение |
|----------------|------------|
| `api/admin-web/` | Весь интерфейс админки (login, stats, users, ads, broadcast, settings…) |
| `api/include/admin_*.php` | Логика админки |
| `api/include/admin_mail.php`, `fcm_push.php` | Письма и push |
| `api/include/api_bootstrap.php` | PDO (если ещё не на сервере) |
| `docs/` | Руководства (опционально, читаются через `manager_guide.php`) |
| `sql/crg_app_deploy.sql` | Дамп **только нужных** таблиц с данными |

**Не перезаписывать** на сервере без необходимости:

- `api/databd.php` — prod-логин/пароль БД
- `api/service_account.json` — FCM
- Остальной `api/*.php` API приложения, если уже работает

Legacy-таблицы старого сайта (`catalog`, `news`, `usersadmin`, `message_*`, `temp_users` и др.) **в дамп не входят** — их можно оставить в MySQL или удалить отдельно, на приложение и админку они не влияют.

---

## 2. Дамп БД (локально)

Учётка **приложения** (таблица `users`, для теста входа в мобильное API):

- **E-mail:** `admin@qwerti.ru`
- **Пароль:** `pppp0000`
- **ID:** `2` (заказчик)

Учётка **веб-админки** (`admin_accounts`):

- **Логин:** `admin`
- **Пароль:** `ChangeMe_Admin1!` (как в миграции; смените на production)

Пересобрать дамп:

```bash
cd /path/to/crgtransp72app-main
./scripts/export_crg_app_dump.sh
# → sql/crg_app_deploy.sql
```

В дампе **21 таблица с данными** + пустые структуры `ordersglobal`, `likes`, `likes1`, `password_resets`, `email_verification_codes`.

---

## 3. Импорт на сервере

> **Сделайте бэкап** текущей БД перед импортом.

```bash
# Бэкап
mysqldump -u USER -p u2395188_apps > backup_before_admin_$(date +%F).sql

# Импорт (заменит данные перечисленных таблиц)
mysql --default-character-set=utf8mb4 -u USER -p u2395188_apps < sql/crg_app_deploy.sql
```

Дамп в конце добавляет колонки `users.payment`, `typepayment`, `fcm_token` (нужны для входа в приложение). Если БД уже импортирована без них:

```bash
mysql --default-character-set=utf8mb4 -u USER -p u2395188_apps < sql/migrate_users_app_columns.sql
```

Залить на сервер исправленный **`api/autoriz1.php`** и **`api/include/jwt_bootstrap.php`**.: collation `utf8mb4_unicode_ci` (не `utf8mb4_0900_ai_ci`); для BLOB убран синтаксис `DEFAULT (_utf8mb4'')` из MySQL 8. Пересборка: `./scripts/export_crg_app_dump.sh`.

Имя БД на хостинге обычно **`u2395188_apps`** (смотрите `api/databd.php`).

`mysqldump` в файле делает `DROP TABLE` + `CREATE` + `INSERT` для каждой включённой таблицы.

Если таблиц админки ещё не было:

```bash
mysql -u USER -p u2395188_apps < sql/migrate_admin_accounts.sql
mysql -u USER -p u2395188_apps < sql/migrate_admin_password_reset.sql
```

Затем снова импорт `crg_app_deploy.sql` или только нужные таблицы.

---

## 4. Заливка файлов админки

### Вариант A — FTP / файловый менеджер хостинга

1. Подключитесь к хосту (тот же каталог, где лежит `api/` приложения).
2. Загрузите:
   - `api/admin-web/` → целиком (merge/overwrite)
   - `api/docs/` → `admin_manager_guide.md`, `admin_guide.md` (руководства в админке)
   - `api/include/admin_*.php`, `admin_mail.php`, `fcm_push.php`, `admin_guide_render.php`, **`api_bootstrap.php`**
   - `api/load_databd.php` (или обновите `api_bootstrap.php` — он подхватит `databd.php` и без этого файла)
3. **Не заливайте** `api/databd.local.php`. **`api/databd.php`** на сервере должен остаться (prod-пароли БД).

### Вариант B — rsync / scp

```bash
HOST=user@your-server.ru
REMOTE=/var/www/.../api   # путь к api на сервере

rsync -avz --exclude 'databd.local.php' \
  api/admin-web/ \
  "$HOST:$REMOTE/admin-web/"

rsync -avz api/include/admin_*.php api/include/admin_mail.php \
  api/include/fcm_push.php api/include/admin_guide_render.php \
  api/include/api_bootstrap.php \
  "$HOST:$REMOTE/include/"

rsync -avz api/load_databd.php "$HOST:$REMOTE/"
```

### Вариант C — git на сервере

```bash
ssh user@server
cd /path/to/app
git pull
# только нужные каталоги, если репозиторий общий с мобильным API
```

---

## 5. Проверка после заливки

1. **Админка:** `https://ваш-домен/admin-web/login.php`  
   Логин `admin`, пароль `ChangeMe_Admin1!`.

2. **Статистика:** после входа открывается `stats.php` — проверьте блок «Выручка и оборот» и фильтр периода.

2a. **Журнал оплат** (если ещё не применён на prod):

```bash
mysql --default-character-set=utf8mb4 -u USER -p DATABASE < sql/migrate_subscription_payment_log.sql
```

Без этой таблицы в статистике не будет реальной выручки; финансы на карточке пользователя покажут предупреждение.

3. **Настройки:** укажите e-mail админа для сброса пароля; смените пароль `ChangeMe_Admin1!` на свой.

4. **Сброс пароля:** `https://ваш-домен/admin-web/login_reset.php` — нужен рабочий `mail()` на сервере или `CRG_MAIL_FROM`.

5. **Push / рассылка:** на сервере должны быть `api/service_account.json` и колонка `users.fcm_token` (в prod-дампе обычно есть).

6. **Мобильное API:** убедитесь, что `databd.php` указывает на ту же БД, куда импортировали дамп.

---

## 6. Права и PHP

- PHP **8.0+** (локально тестировалось на 8.x).
- Расширения: `pdo_mysql`, `mbstring`, `json`, `session`.
- Каталог `api/admin-web/` должен быть доступен через веб-сервер (Apache/Nginx → document root часто `api/` или корень сайта).

Пример URL, если document root = `api/`:

```
https://domain.ru/admin-web/login.php
```

Если document root = корень проекта — настройте alias или положите admin-web туда, где уже открывается API.

---

## 7. Переменные окружения (опционально)

| Переменная | Зачем |
|------------|--------|
| `CRG_MAIL_FROM` | Отправитель писем (рассылка, сброс пароля) |
| `CRG_ADMIN_PASSWORD_RESET_FALLBACK` | Запасной e-mail для OTP |
| `CRG_ADMIN_PASSWORD_OTP_TTL` | Срок кода сброса (сек) |

---

## 8. Краткий чеклист

- [ ] Бэкап prod БД
- [ ] `./scripts/export_crg_app_dump.sh` → `sql/crg_app_deploy.sql`
- [ ] `mysql … < crg_app_deploy.sql`
- [ ] Залиты `admin-web/` и `include/admin_*.php`
- [ ] `databd.php` на сервере **не** затёрт
- [ ] `mysql … < sql/migrate_subscription_payment_log.sql` (выручка и финансы)
- [ ] Вход в админку, статистика (период, выручка), финансы на карточке исполнителя, модерация объявления
- [ ] Сменить пароль admin на production-пароль

### 8.1. Дополнение — пакет P1 (гео / жалобы / push / пакеты)

Полный чеклист: **[deploy_p1_checklist.md](./deploy_p1_checklist.md)**.  
Архив серверных файлов: `./scripts/pack_p1_deploy.sh` → `dist/p1_deploy_YYYYMMDD.zip`.

- [ ] `mysql … < sql/migrate_city_geo.sql`
- [ ] `mysql … < sql/migrate_subscription_packages.sql`
- [ ] Залиты файлы из `p1_deploy_*.zip` (без перезаписи `databd.php`)
- [ ] Cron: `api/cron/subscription_reminders.php`
- [ ] Smoke: геопоиск, жалобы → deal-чат, пакеты/промо в админке
- [ ] Сборка Flutter с `geolocator` (отдельно от zip)

### 8.2. Дополнение — пакет P2 (онбординг / поднятие / верификация / шаблоны / в пути / воронка)

Полный чеклист: **[deploy_p2_checklist.md](./deploy_p2_checklist.md)**.  
Архив серверных файлов: `./scripts/pack_p2_deploy.sh` → `dist/p2_deploy_YYYYMMDD.zip`.

- [ ] P1 уже на prod ([deploy_p1_checklist.md](./deploy_p1_checklist.md))
- [ ] `mysql … < sql/migrate_p2_features.sql`
- [ ] Залиты файлы из `p2_deploy_*.zip` (без перезаписи `databd.php`)
- [ ] Smoke: поднятие, верификация, шаблоны, воронка в stats
- [ ] Сборка Flutter с экранами P2 (отдельно от zip)

### 8.3. Дополнение — пакет P3 (B2B-счета / автомодерация / экспорт CSV)

Полный чеклист: **[deploy_p3_checklist.md](./deploy_p3_checklist.md)**.  
Архив серверных файлов: `./scripts/pack_p3_deploy.sh` → `dist/p3_deploy_YYYYMMDD.zip`.

- [ ] P1 и P2 уже на prod ([deploy_p1_checklist.md](./deploy_p1_checklist.md), [deploy_p2_checklist.md](./deploy_p2_checklist.md))
- [ ] `mysql … < sql/migrate_p3_features.sql`
- [ ] Залиты файлы из `p3_deploy_*.zip` (без перезаписи `databd.php`)
- [ ] Smoke: счета B2B, автомодерация, CSV export
- [ ] Сборка Flutter с кнопкой «Запросить счёт» (отдельно от zip)

---

*Техническое руководство: `docs/admin_guide.md` · для менеджера: `docs/admin_manager_guide.md`*
