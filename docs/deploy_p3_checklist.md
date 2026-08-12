# Деплой P3 — чеклист и статус

**Дата реализации:** 3 августа 2026  
**Пакет:** P3 из [feature_proposals_estimate.html](./portfolio/feature_proposals_estimate.html)  
**Архив серверных файлов:** `dist/p3_deploy_YYYYMMDD.zip` (собрать: `./scripts/pack_p3_deploy.sh`)

**Предусловие:** на prod уже развёрнуты [P1](./deploy_p1_checklist.md) и [P2](./deploy_p2_checklist.md).

---

## 1. Что сделано (статус)

| # | Блок | Статус | Ключевые артефакты |
|---|------|--------|--------------------|
| **2.3** | B2B-счета для юрлиц | **готово** | `subscription_invoice_requests`, `request_subscription_invoice.php`, админка `invoices.php`, кнопка в `PaymentPage.dart` |
| **4.2** | Автомодерация по правилам | **готово** | `moderation_stop_words`, `ad_auto_moderation.php`, хук в `add_ob_*.php`, админка `moderation.php` |
| **4.3** | Экспорт CSV | **готово** | `admin_export.php`, страница `export.php` (users / payments / deals) |

---

## 2. Миграции БД (обязательно на prod)

> Сначала бэкап: `mysqldump -u USER -p DATABASE > backup_before_p3_$(date +%F).sql`

```bash
mysql --default-character-set=utf8mb4 -u USER -p DATABASE < sql/migrate_p3_features.sql
```

| Миграция | Эффект |
|----------|--------|
| `sql/migrate_p3_features.sql` | `moderation_stop_words`, `moderation_log`; `subscription_invoice_requests`; `subscription_payment_log.payment_method` |

- [ ] Бэкап prod БД
- [ ] Применена `migrate_p3_features.sql`
- [ ] В админке «Автомодерация» — стоп-слова по умолчанию
- [ ] `SHOW TABLES LIKE 'subscription_invoice_requests'` — таблица есть

---

## 3. Заливка файлов API / admin-web

Из архива `dist/p3_deploy_*.zip` (или rsync из репозитория).

**Не затирать на сервере:** `api/databd.php`, `api/service_account.json`, `api/databd.local.php`.

### Include

- [ ] `api/include/ad_auto_moderation.php` *(новый)*
- [ ] `api/include/subscription_invoices.php` *(новый)*
- [ ] `api/include/admin_export.php` *(новый)*
- [ ] `api/include/performer_finances.php` (`payment_method` в журнале)

### API endpoints

- [ ] `api/add_ob_gp.php` (хук автомодерации)
- [ ] `api/add_ob_vidt.php` (хук автомодерации)
- [ ] `api/add_ob_gr.php` (хук автомодерации)
- [ ] `api/request_subscription_invoice.php` *(новый)*
- [ ] `api/get_subscription_invoices.php` *(новый)*
- [ ] `api/getuserinfo.php` (`statNum`, реквизиты юрлица)

### Admin-web

- [ ] `api/admin-web/bootstrap_web.php` (пункты «Счета B2B», «Автомодерация», «Экспорт CSV»)
- [ ] `api/admin-web/invoices.php` *(новый)*
- [ ] `api/admin-web/moderation.php` *(новый)*
- [ ] `api/admin-web/export.php` *(новый)*

---

## 4. Мобильное приложение (Flutter)

Серверный архив **не** содержит готовый APK/IPA.

- `lib/pages/PaymentPage.dart` — «Запросить счёт (юр. лицо)» при `statNum == 1`

- [ ] `flutter pub get`
- [ ] Сборка Android / iOS
- [ ] Smoke по разделу 5

---

## 5. Smoke после деплоя

> Подробнее простым языком: **[testing_guide_ru.md](./testing_guide_ru.md)**

### 2.3 B2B-счета

- [ ] Исполнитель-юрлицо (`statNum=1`) → **Оформление подписки** → «Запросить счёт»
- [ ] `POST …/api/request_subscription_invoice.php` → `success: true`
- [ ] Админка → **Счета B2B** → заявка в статусе «Запрошен»
- [ ] Выставить № счёта → статус «Счёт выставлен»
- [ ] «Оплачен» → подписка продлена, запись в `subscription_payment_log` с `payment_method=invoice`

### 4.2 Автомодерация

- [ ] Админка → **Автомодерация** → добавить стоп-слово
- [ ] Создать объявление исполнителя со стоп-словом в тексте → автоотклонение + push
- [ ] Объявление без фото → автоотклонение
- [ ] Дубль опубликованного → остаётся в очереди (`flag=0`)

### 4.3 Экспорт CSV

- [ ] Админка → **Экспорт CSV** → скачать `users.csv`
- [ ] Скачать `payments.csv` за 30 дней — UTF-8, разделитель `;`
- [ ] Скачать `deals.csv` — колонки `performer_id`, `customer_id`, `status`

---

## 6. Связанная документация

| Документ | Обновление |
|----------|------------|
| [testing_guide_ru.md](./testing_guide_ru.md) | **как проверить P1–P3** |
| [admin_manager_guide.md](./admin_manager_guide.md) | разделы P1–P3 для менеджера |
| [admin_guide.md](./admin_guide.md) | §11.8 справочник P1–P3 |
| [deploy_admin_host.md](./deploy_admin_host.md) §8.3 | миграции P3 |
| [portfolio/feature_proposals_estimate.html](./portfolio/feature_proposals_estimate.html) | статус P3 «сделано» |
| [deploy_p2_checklist.md](./deploy_p2_checklist.md) | предусловие P2 |
| Этот файл | чеклист деплоя P3 |

---

*После прохождения чеклиста отметьте пункты на prod и зафиксируйте дату релиза.*
