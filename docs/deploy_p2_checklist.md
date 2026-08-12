# Деплой P2 — чеклист и статус

**Дата реализации:** 3 августа 2026  
**Пакет:** P2 из [feature_proposals_estimate.html](./portfolio/feature_proposals_estimate.html)  
**Архив серверных файлов:** `dist/p2_deploy_YYYYMMDD.zip` (собрать: `./scripts/pack_p2_deploy.sh`)

**Предусловие:** на prod уже развёрнут [P1](./deploy_p1_checklist.md) (гео, жалобы, push, пакеты подписки).

---

## 1. Что сделано (статус)

| # | Блок | Статус | Ключевые артефакты |
|---|------|--------|--------------------|
| **1.4** | Онбординг после регистрации | **готово** | `OnboardingScreen`, `OnboardingService`, показ после первого входа |
| **2.2** | Платное поднятие объявления | **готово** | `ad_boost_tariffs`, `ad_boosts`, `apply_ad_boost.php`, сортировка в топ в поиске |
| **3.1** | Верификация исполнителя | **готово** | `users.is_verified`, галочка в `user_edit.php`, бейдж в `outputob.dart` |
| **3.2** | Шаблоны повторных заявок | **готово** | `get_customer_ad_templates.php`, `duplicate_customer_ad.php`, кнопка в `ads2.dart` |
| **3.3** | Статус «в пути» + ETA | **готово** | `ordersglobal` + `update_order_transit.php`, кнопка в `OrderExecutionScreen` |
| **4.1** | Воронка в админке | **готово** | `crg_admin_stats_funnel()` → блок на `stats.php` |

**Следующий пакет:** [P3](./deploy_p3_checklist.md) — B2B-счета, автомодерация, экспорт CSV (**готово** 03.08.2026).

---

## 2. Миграции БД (обязательно на prod)

> Сначала бэкап: `mysqldump -u USER -p DATABASE > backup_before_p2_$(date +%F).sql`

```bash
mysql --default-character-set=utf8mb4 -u USER -p DATABASE < sql/migrate_p2_features.sql
```

| Миграция | Эффект |
|----------|--------|
| `sql/migrate_p2_features.sql` | `users.is_verified` / `verified_at`; таблицы `ad_boost_tariffs`, `ad_boosts`; сиды 24h/72h; `ordersglobal.status` + `в_пути`, `eta_at`, `transit_lat/lng` |

- [ ] Бэкап prod БД
- [ ] Применена `migrate_p2_features.sql`
- [ ] В админке «Поднятие» — тарифы 24 ч / 72 ч
- [ ] `SHOW COLUMNS FROM ordersglobal LIKE 'eta_at'` — колонка есть

---

## 3. Заливка файлов API / admin-web

Из архива `dist/p2_deploy_*.zip` (или rsync из репозитория).

**Не затирать на сервере:** `api/databd.php`, `api/service_account.json`, `api/databd.local.php`.

### Include

- [ ] `api/include/ad_boost.php` *(новый)*
- [ ] `api/include/search_services_core.php` (boost sort + `is_verified`)
- [ ] `api/include/admin_stats.php` (воронка)
- [ ] `api/include/admin_users.php` (`is_verified`)
- [ ] `api/include/deal_push.php` (событие `in_transit`)

### API endpoints

- [ ] `api/get_boost_tariffs.php` *(новый)*
- [ ] `api/apply_ad_boost.php` *(новый)*
- [ ] `api/get_customer_ad_templates.php` *(новый)*
- [ ] `api/duplicate_customer_ad.php` *(новый)*
- [ ] `api/update_order_transit.php` *(новый)*
- [ ] `api/getuserinfo.php` (`is_verified`)
- [ ] `api/get_order_global_info.php` (ETA / transit)
- [ ] `api/update_order_status.php` (статусы `в_пути`)

### Admin-web

- [ ] `api/admin-web/bootstrap_web.php` (пункт «Поднятие»)
- [ ] `api/admin-web/boost_tariffs.php` *(новый)*
- [ ] `api/admin-web/stats.php` (блок воронки)
- [ ] `api/admin-web/user_edit.php` (галочка «Проверен»)

---

## 4. Мобильное приложение (Flutter)

Серверный архив **не** содержит готовый APK/IPA. Нужна сборка из репозитория после `flutter pub get`.

Затронутые клиентские файлы (для релиза стора):

- `lib/services/onboarding_service.dart` *(новый)*
- `lib/pages/onboarding_screen.dart` *(новый)*
- `lib/pages/ad_boost_screen.dart` *(новый)*
- `lib/pages/ad_template_picker_screen.dart` *(новый)*
- `lib/pages/loginpage.dart` (онбординг после входа)
- `lib/pages/ads1.dart` (кнопка «Поднять в топ»)
- `lib/pages/ads2.dart` («Создать как прошлую»)
- `lib/pages/outputob.dart` (бейдж «Проверен»)
- `lib/pages/OrderExecutionScreen.dart` («В пути» + ETA)

- [ ] `flutter pub get`
- [ ] Сборка Android / iOS
- [ ] Smoke по разделу 5

---

## 5. Smoke после деплоя

> Подробнее простым языком: **[testing_guide_ru.md](./testing_guide_ru.md)**

### 1.4 Онбординг

- [ ] Первый вход (или сброс `OnboardingService` в debug) → 3 экрана
- [ ] «Пропустить» / «Начать работу» → главное меню, повторно не показывается

### 2.2 Поднятие

- [ ] Админка → **Поднятие** → цены 199 / 399 ₽ (или свои)
- [ ] `GET …/api/get_boost_tariffs.php` → `success`, массив `tariffs`
- [ ] Исполнитель → **Мои объявления** → иконка «в топ» → оплата (тест)
- [ ] В выдаче заказчика поднятое объявление выше остальных

### 3.1 Верификация

- [ ] Админка → исполнитель → «Проверен»
- [ ] `getuserinfo.php` → `is_verified: 1`
- [ ] В поиске у карточки — иконка и подпись «Проверен»

### 3.2 Шаблоны

- [ ] Заказчик → **Мои объявления** → иконка копии
- [ ] `GET …/api/get_customer_ad_templates.php?token=…` → список прошлых заявок
- [ ] Дубликат появляется в «Мои объявления»

### 3.3 В пути

- [ ] Активная сделка → исполнитель → **В пути + ETA**
- [ ] Заказчик: push «Исполнитель в пути»
- [ ] `get_order_global_info.php` → `eta_at`, `status`

### 4.1 Воронка

- [ ] Админка → **Статистика** → блок «Воронка (P2)» — 5 шагов с числами

---

## 6. Связанная документация

| Документ | Обновление |
|----------|------------|
| [deploy_admin_host.md](./deploy_admin_host.md) §8.2 | миграции P2 |
| [portfolio/feature_proposals_estimate.html](./portfolio/feature_proposals_estimate.html) | статус P2 «сделано» |
| [deploy_p1_checklist.md](./deploy_p1_checklist.md) | предусловие P1 |
| Этот файл | чеклист деплоя P2 |

---

*После прохождения чеклиста отметьте пункты на prod и зафиксируйте дату релиза.*
