# crgtransp72app

Мобильное приложение маркетплейса грузоперевозок и спецтехники (Flutter + PHP API).

**Версия приложения:** 6.0.0+26 (`pubspec.yaml`)  
**Базовый URL API:** https://ivnovav.ru

## Getting Started

```bash
flutter pub get
flutter run
```

Сборка release APK:

```bash
flutter build apk --release
```

Сборка AAB для Google Play:

```bash
flutter build appbundle --release
```

## Документация (руководства)

| Документ | Описание |
|----------|----------|
| [Карта веток экранов и меню](./BRANCH_SCREENS_MAP_RU.md) | Заказчик vs исполнитель, навигация, shell |
| [Данные регистрации, поиска, объявлений](./REG_DATA_FORMS_RU.md) | Поля форм, API, названия экранов |
| [Логика поиска](./docs/search_logic_ru.md) | Алгоритм поиска, `search_services.php` |
| [Логика поиска (PDF)](./docs/search_logic_ru.pdf) | То же в PDF |
| [Логика чатов](./docs/chat_logic_ru.md) | Чаты user↔user, техподдержка, admin-web (проект) |
| [ТЗ проекта](./TZ_PROEKT_OBSHEE_RU.md) | Общее техническое задание |
| [Заметки для App Store](./APP_STORE_REVIEW_NOTES_RU.md) | Публикация в App Store |

### Админ-панель

- [docs/admin_guide.md](./docs/admin_guide.md)
- [docs/admin_manager_guide.md](./docs/admin_manager_guide.md)
- [docs/deploy_admin_host.md](./docs/deploy_admin_host.md)

## Полезные скрипты

- `scripts/md_to_pdf.py` — конвертация `docs/search_logic_ru.md` в PDF

For help with Flutter development, see the [online documentation](https://docs.flutter.dev/).
