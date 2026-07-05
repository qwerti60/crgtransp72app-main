# Скриншоты для App Store и Google Play

Автогенерация:

```bash
chmod +x scripts/generate_store_screenshots.sh
./scripts/generate_store_screenshots.sh
```

## Структура после генерации

```
store_assets/screenshots/
├── _raw/                    # исходники с симулятора
│   ├── iphone/
│   └── ipad/
├── ios/                     # App Store Connect
│   ├── iphone-69/           # 1320×2868 (6.9", обязательно для новых iPhone)
│   ├── iphone-67/           # 1290×2796 (6.7")
│   ├── iphone-65/           # 1284×2778 (6.5", опционально)
│   ├── iphone-55/           # 1242×2208 (5.5", legacy)
│   ├── ipad-129/            # 2048×2732 (12.9" / 13")
│   └── ipad-11/             # 1668×2388 (11")
└── google_play/
    ├── phone/               # 1080×1920
    ├── phone-xxhdpi/        # 1440×2560
    ├── tablet-7/            # 1200×1920
    └── tablet-10/           # 1600×2560
```

## Кадры (4 штуки)

| Файл | Экран |
|------|--------|
| `01_customer_services` | Заказчик → каталог «Услуги» |
| `02_customer_search` | Заказчик → поиск исполнителей |
| `03_performer_listings` | Исполнитель → «Объявления» |
| `04_performer_search` | Исполнитель → поиск заявок |

## Загрузка в консоли

**App Store Connect** → приложение → **Screenshots**:
- iPhone 6.9" / 6.7" — папка `ios/iphone-67` или `iphone-69`
- iPad — `ios/ipad-129` (приложение поддерживает iPad)

**Google Play Console** → **Main store listing** → **Phone / Tablet**:
- Телефон: `google_play/phone/` или `phone-xxhdpi/`
- 7" / 10" планшет: `tablet-7/`, `tablet-10/`

Подробные требования: [docs/store_screenshots_ru.md](../docs/store_screenshots_ru.md)
