# Деплой P1 — чеклист и статус

**Дата реализации:** 2 августа 2026  
**Пакет:** P1 из [feature_proposals_estimate.html](./portfolio/feature_proposals_estimate.html)  
**Архив серверных файлов:** `dist/p1_deploy_YYYYMMDD.zip` (собрать: `./scripts/pack_p1_deploy.sh`)

---

## 1. Что сделано (статус)

| # | Блок | Статус | Ключевые артефакты |
|---|------|--------|--------------------|
| **1.1** | Геопоиск / «рядом со мной» | **готово** | `migrate_city_geo.sql`, `search_services_core.php`, админка городов, Flutter Near Me |
| **1.2** | Жалобы + deal-чат в админке | **готово** | `SupportCreateScreen` + context, `deal_chat_view.php`, фильтр жалоб |
| **1.3** | Системные push (сделка + подписка) | **готово** | `deal_push.php`, хуки offer/accept/start/complete, `cron/subscription_reminders.php`, deep links |
| **2.1** | Пакеты подписки + промокоды | **готово** | `migrate_subscription_packages.sql`, `packages.php` / `promo_codes.php`, `PaymentPage` |

**Не входит в P1 (осталось намеренно):** WebSocket чата, FULLTEXT / tonnage в поиске, App Store / Play релиз билда.

---

## 2. Миграции БД (обязательно на prod)

> Сначала бэкап: `mysqldump -u USER -p DATABASE > backup_before_p1_$(date +%F).sql`

```bash
mysql --default-character-set=utf8mb4 -u USER -p DATABASE < sql/migrate_city_geo.sql
mysql --default-character-set=utf8mb4 -u USER -p DATABASE < sql/migrate_subscription_packages.sql
```

| Миграция | Эффект |
|----------|--------|
| `sql/migrate_city_geo.sql` | `cities.lat` / `cities.lng` + сиды координат |
| `sql/migrate_subscription_packages.sql` | `subscription_packages`, `promo_codes`, `promo_redemptions`, колонки в `subscription_payment_log`, сиды месяц/квартал/год |

- [ ] Бэкап prod БД
- [ ] Применена `migrate_city_geo.sql`
- [ ] Применена `migrate_subscription_packages.sql`
- [ ] В админке «Города» видны координаты (хотя бы у Тюмени)
- [ ] В админке «Пакеты» есть 3 пакета

---

## 3. Заливка файлов API / admin-web

Из архива `dist/p1_deploy_*.zip` (или rsync из репозитория).

**Не затирать на сервере:** `api/databd.php`, `api/service_account.json`, `api/databd.local.php`.

### Include

- [ ] `api/include/search_services_core.php`
- [ ] `api/include/admin_cities.php`
- [ ] `api/include/admin_support.php`
- [ ] `api/include/chat_core.php`
- [ ] `api/include/deal_push.php` *(новый)*
- [ ] `api/include/subscription_packages.php` *(новый)*
- [ ] `api/include/performer_finances.php`

### API endpoints

- [ ] `api/add_offer.php`, `api/add_offerzakaz.php`, `api/updatePriemZak.php`
- [ ] `api/update_subscription.php`, `api/get_subscription_config.php`
- [ ] `api/get_subscription_packages.php` *(новый)*
- [ ] `api/validate_promo.php` *(новый)*
- [ ] `api/cron/subscription_reminders.php` *(новый)*

### Admin-web

- [ ] `api/admin-web/bootstrap_web.php` (пункты меню Пакеты / Промокоды)
- [ ] `api/admin-web/cities.php`, `city_edit.php`, `city_new.php`
- [ ] `api/admin-web/support_queue.php`, `support_view.php`
- [ ] `api/admin-web/deal_chat_view.php` *(новый)*
- [ ] `api/admin-web/packages.php`, `promo_codes.php` *(новые)*

### Cron (подписка)

```cron
0 9 * * * /usr/bin/php /path/to/api/cron/subscription_reminders.php >> /var/log/crg_sub_reminders.log 2>&1
```

- [ ] Cron настроен (или разовый ручной запуск для проверки)

---

## 4. Мобильное приложение (Flutter)

Серверный архив **не** содержит готовый APK/IPA. Нужна сборка из репозитория после `flutter pub get` (зависимость `geolocator`).

Затронутые клиентские файлы (для релиза стора):

- `pubspec.yaml` (+ `geolocator`)
- `lib/models/search_params.dart`, `lib/services/location_service.dart`
- `lib/widgets/search_form_widgets.dart`
- `lib/pages/customer_search_screen.dart`, `performer_search_screen.dart`
- `lib/pages/outputob.dart`, `outputobz.dart`
- `lib/pages/support_create_screen.dart`, `chat_thread_screen.dart`, `chat_list_screen.dart`
- `lib/services/chat_api.dart`, `chat_push_handler.dart`
- `lib/models/chat_thread.dart`
- `lib/pages/PaymentPage.dart`
- `android/app/src/main/AndroidManifest.xml` (location permissions)
- iOS: `NSLocationWhenInUseUsageDescription` уже был в Info.plist

- [ ] `flutter pub get`
- [ ] Сборка Android / iOS
- [ ] На устройстве: разрешение геолокации
- [ ] Smoke: «Рядом со мной», жалоба, push (если FCM), выбор пакета + промо

---

## 5. Smoke после деплоя

> Подробнее простым языком: **[testing_guide_ru.md](./testing_guide_ru.md)**

### 1.1 Геопоиск

- [ ] Админка → город Тюмень: lat/lng заполнены
- [ ] `search_services.php?role=customer&nameImg=…&lat=57.15&lng=65.53&radius_km=30&sort=distance` → есть `distance_km`
- [ ] В приложении тогл «Рядом со мной» + чипы радиуса

### 1.2 Жалобы

- [ ] Из deal-чата «Пожаловаться» → тикет `deal_dispute` с context
- [ ] С карточки объявления «Пожаловаться» → `ad_moderation`
- [ ] Админка → Поддержка → фильтр «Жалобы» → «Открыть deal-чат»

### 1.3 Push

- [ ] Новый отклик → push `deal_event` / `offer_received` получателю
- [ ] `php api/cron/subscription_reminders.php` отрабатывает без ошибок (CLI)

### 2.1 Подписка

- [ ] Админка → Пакеты / Промокоды
- [ ] `get_subscription_packages.php` → 3 пакета
- [ ] `validate_promo.php` с тестовым кодом
- [ ] PaymentPage: выбор пакета, промо, сумма к оплате

---

## 6. Связанная документация

| Документ | Обновление |
|----------|------------|
| [search_logic_ru.md](./search_logic_ru.md) §13–15 | фаза 5 геопоиск + чеклист |
| [chat_logic_ru.md](./chat_logic_ru.md) §12 | фаза 4 жалобы/deal admin |
| [deploy_admin_host.md](./deploy_admin_host.md) §8 | миграции P1 |
| [portfolio/feature_proposals_estimate.html](./portfolio/feature_proposals_estimate.html) | статус P1 |
| Этот файл | чеклист деплоя |

---

*После прохождения чеклиста отметьте пункты выше на prod и приложите дату релиза в changelog команды.*
