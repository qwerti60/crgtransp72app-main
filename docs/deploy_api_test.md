# Стенд на prod: `api_test` + отдельная MySQL

На том же хосте, что и боевой сайт, поднимается **вторая** копия API и **вторая** БД.  
Боевые `/api/` и старая БД **не меняются** — ими пользуются приложения, уже установленные из сторов.

| | Сторы / бой | Новые тестовые сборки |
|--|-------------|------------------------|
| Папка | `/api/` | `/api_test/` |
| URL | `http://gruzoperevozki72.ru/api/…` | `http://gruzoperevozki72.ru/api_test/…` |
| Админка | `/api/admin-web/` | `/api_test/admin-web/` |
| БД | старая (prod) | новая (например `u3569916_test`) |
| Flutter | `CRG_API_ENV=prod` (по умолчанию) | `CRG_API_ENV=prodTest` |

**Важно:** уже установленные из сторов APK/IPA имеют внутри URL `/api/` — они всегда ходят в старую БД.  
Менять `api/databd.php` на сервере на новую БД **нельзя** — сломаете сторы.

---

## Сборка приложения

```bash
# Новая APK для теста новой БД
./scripts/build_apk_test.sh
# = flutter build apk --release --dart-define=CRG_API_ENV=prodTest

# Релиз в сторы (старая БД, как у установленных)
./scripts/build_apk_store.sh apk
./scripts/build_apk_store.sh aab
```

---

## 1. Сборка архива API стенда

```bash
./scripts/pack_api_test_deploy.sh
# → dist/api_test_deploy_YYYYMMDD.zip
```

---

## 2. MySQL на хостинге

В панели (reg.ru / ISPmanager):

1. Создайте БД, например `u3569916_test`
2. Пользователя с полными правами на эту БД
3. Импортируйте схему:

**Вариант A — чистая тестовая:**

```bash
mysql -u USER -p u3569916_test < sql/local_dev.sql
# + нужные migrate_*.sql из архива (P1/P2/P3 и т.д.)
```

**Вариант B — копия с prod (осторожно: персональные данные):**

```bash
mysqldump -u USER -p PROD_DB > prod_copy.sql
mysql -u USER -p u3569916_test < prod_copy.sql
```

---

## 3. Файлы на сервере

Рядом с существующей папкой `api/`:

```text
site/
  api/          ← prod / сторы, databd.php → СТАРАЯ БД (не трогать)
  api_test/     ← новый стенд, databd.php → НОВАЯ БД
```

```bash
cd /path/to/site
unzip -o api_test_deploy_YYYYMMDD.zip

cp api_test/databd.php.example api_test/databd.php
# отредактировать host / username / password / dbname → тестовая БД

# push (опционально)
cp api/service_account.json api_test/service_account.json

# почта: либо копия, либо автоподхват из api/mail.local.php (см. mail_config.php)
cp api/mail.local.php api_test/mail.local.php   # рекомендуется

# оплата / отмена подписки (иначе HTTP 404 HTML с хостинга)
cp api/payment-proxy.php api_test/payment-proxy.php
# если на стенде новый proxy из репозитория — ещё секреты:
# cp api/payment.local.php api_test/payment.local.php
# либо: cp api/payment.local.example.php api_test/payment.local.php и заполнить
```

Проверка:

```bash
curl -sS -X POST "http://gruzoperevozki72.ru/api_test/request_registration_code.php" \
  -d "email=ваш@email.ru"
# ожидается: {"status":"success",...}
```

Админка стенда:  
`http://gruzoperevozki72.ru/api_test/admin-web/login.php`

---

## 4. Важно

- Не заливайте `databd.local.php` в `api_test` на сервер.
- Не указывайте в `api_test/databd.php` боевую (старую) БД.
- Не меняйте `api/databd.php` на новую БД — сломаете приложения из сторов.
- Для писем на стенде нужен `mail.local.php` (свой или соседний `api/mail.local.php`).
- Cron reminders для стенда **не ставьте**, пока не нужно (иначе дубли push).
- В сторы всегда собирайте с `CRG_API_ENV=prod` (`./scripts/build_apk_store.sh`).
