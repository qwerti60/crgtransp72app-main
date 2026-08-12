# crgtransp72app

Мобильное приложение маркетплейса грузоперевозок и спецтехники (Flutter + PHP API).

**Версия приложения:** 6.0.0+26 (`pubspec.yaml`)  
**Базовый URL API:** http://gruzoperevozki72.ru (см. `lib/config.dart`)

## Getting Started

```bash
flutter pub get
flutter run
```

Сборка release APK:

```bash
# Тест новой БД (/api_test/)
./scripts/build_apk_test.sh

# В сторы — старая БД (/api/), как у уже установленных приложений
./scripts/build_apk_store.sh apk
```

Сборка AAB для Google Play:

```bash
./scripts/build_apk_store.sh aab
```

Стенд на сервере: [docs/deploy_api_test.md](./docs/deploy_api_test.md)
## Документация (руководства)

| Документ | Описание |
|----------|----------|
| [Карта веток экранов и меню](./BRANCH_SCREENS_MAP_RU.md) | Заказчик vs исполнитель, навигация, shell |
| [Данные регистрации, поиска, объявлений](./REG_DATA_FORMS_RU.md) | Поля форм, API, названия экранов |
| [Логика сделок](./docs/deals_logic_ru.md) | `offer_data`, `ordersglobal`, два сценария |
| **[Сценарии приложения](./docs/app_scenarios_ru.md)** | **Свод всех согласованных сценариев, UI и навигации (промпты заказчика)** |
| [Логика поиска](./docs/search_logic_ru.md) | Алгоритм поиска, `search_services.php` |
| [Логика поиска (PDF)](./docs/search_logic_ru.pdf) | То же в PDF |
| [Логика чатов](./docs/chat_logic_ru.md) | Чаты user↔user, техподдержка, admin-web |
| **[Как протестировать P1–P3](./docs/testing_guide_ru.md)** | **Smoke-тесты приложения и админки** |
| [ТЗ проекта](./TZ_PROEKT_OBSHEE_RU.md) | Общее техническое задание |
| [Заметки для App Store](./APP_STORE_REVIEW_NOTES_RU.md) | Публикация в App Store |

### Админ-панель

- [docs/admin_guide.md](./docs/admin_guide.md)
- [docs/admin_manager_guide.md](./docs/admin_manager_guide.md)
- [docs/deploy_admin_host.md](./docs/deploy_admin_host.md)
- **[Деплой P1 (гео / жалобы / push / пакеты)](./docs/deploy_p1_checklist.md)** — статус «сделано», миграции, smoke
- **[Деплой P2 (онбординг / поднятие / верификация / …)](./docs/deploy_p2_checklist.md)** — статус «сделано», миграции, smoke
- **[Деплой P3 (B2B-счета / автомодерация / CSV)](./docs/deploy_p3_checklist.md)** — статус «сделано», миграции, smoke
- **[Стенд api_test + отдельная БД на prod](./docs/deploy_api_test.md)** — рядом с `/api/`, Flutter: `ApiEnv.prodTest`
- [Смета доработок](./docs/portfolio/feature_proposals_estimate.html) — P1, P2 и P3 отмечены выполненными (08.2026)

## Полезные скрипты

- `./scripts/pack_api_test_deploy.sh` — zip папки `api_test/` для хостинга

- `scripts/md_to_pdf.py` — конвертация `docs/search_logic_ru.md` в PDF
- `scripts/pack_p1_deploy.sh` — zip серверных файлов P1 → `dist/p1_deploy_YYYYMMDD.zip`
- `scripts/pack_p2_deploy.sh` — zip серверных файлов P2 → `dist/p2_deploy_YYYYMMDD.zip`
- `scripts/pack_p3_deploy.sh` — zip серверных файлов P3 → `dist/p3_deploy_YYYYMMDD.zip`

For help with Flutter development, see the [online documentation](https://docs.flutter.dev/).
