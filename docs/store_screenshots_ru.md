# Скриншоты для App Store и Google Play

**Версия:** 1.0  
**Дата:** 5 июля 2026  
**Приложение:** CRG Transp 72 (KipaRO), v6.0.0

---

## 1. Быстрый старт

На Mac с Xcode и Flutter:

```bash
cd /path/to/crgtransp72app-main
chmod +x scripts/generate_store_screenshots.sh
./scripts/generate_store_screenshots.sh
```

Результат: `store_assets/screenshots/` — все размеры для обеих площадок.

Опции:

| Флаг | Действие |
|------|----------|
| `--ios-only` | только iPhone (без iPad-симулятора) |
| `--resize-only` | только ресайз из `_raw/` (без новой съёмки) |

Переменные:

```bash
IOS_PHONE_DEVICE="iPhone 16 Pro Max" ./scripts/generate_store_screenshots.sh
```

---

## 2. App Store Connect — размеры (2026)

### iPhone (портрет)

| Папка | Пиксели | Устройство | Обязательность |
|-------|---------|------------|----------------|
| `ios/iphone-69` | **1320 × 2868** | iPhone 16 Pro Max, 6.9" | Рекомендуется (новые модели) |
| `ios/iphone-67` | **1290 × 2796** | iPhone 15 Pro Max, 6.7" | **Минимум для iPhone** |
| `ios/iphone-65` | 1284 × 2778 | iPhone 11 Pro Max, 6.5" | Опционально (Apple масштабирует с 6.7") |
| `ios/iphone-55` | 1242 × 2208 | iPhone 8 Plus, 5.5" | Legacy, обычно не нужен |

Достаточно загрузить **один** набор 6.7" или 6.9" — Apple подставит для остальных iPhone.

### iPad (портрет)

Приложение в проекте: `TARGETED_DEVICE_FAMILY = 1,2` (iPhone + iPad).

| Папка | Пиксели | Устройство |
|-------|---------|------------|
| `ios/ipad-129` | **2048 × 2732** | iPad Pro 12.9" / 13" |
| `ios/ipad-11` | **1668 × 2388** | iPad Pro 11" |

Минимум для iPad: **2048 × 2732**.

### Сколько скриншотов

- До **10** на локаль (язык)
- Рекомендуется **4–6** ключевых экранов
- Формат: PNG или JPEG, без альфа-канала в JPEG

---

## 3. Google Play Console — размеры

### Телефон

| Папка | Пиксели | Примечание |
|-------|---------|------------|
| `google_play/phone` | **1080 × 1920** | Стандарт 9:16 |
| `google_play/phone-xxhdpi` | **1440 × 2560** | Высокое качество |

Минимум **2** скриншота, максимум **8**. Соотношение сторон от 16:9 до 9:16.

### Планшет

| Папка | Пиксели |
|-------|---------|
| `google_play/tablet-7` | **1200 × 1920** |
| `google_play/tablet-10` | **1600 × 2560** |

Если в Play указана поддержка планшетов — загрузите отдельный набор.

### Feature Graphic (не генерируется скриптом)

- **1024 × 500** px — баннер в карточке приложения (обязателен для публикации)

---

## 4. Какие экраны снимает автотест

| № | Имя файла | Содержание |
|---|-----------|------------|
| 1 | `01_customer_services` | Гость/заказчик — сетка категорий «Услуги» |
| 2 | `02_customer_search` | Поиск исполнителей (город, услуга, запрос) |
| 3 | `03_performer_listings` | Исполнитель — каталог «Объявления» |
| 4 | `04_performer_search` | Поиск заявок заказчиков |

Тест: `integration_test/store_screenshots_test.dart`  
Нужен доступ к API (`Config.baseUrl`) — для заполненных списков дождитесь загрузки (~10–14 с на экран).

---

## 5. Ручная съёмка (если автотест недоступен)

1. Запустите симулятор нужного размера.
2. `flutter run -d "iPhone 16 Pro Max"` — пройдите сценарии из [APP_STORE_REVIEW_NOTES_RU.md](./APP_STORE_REVIEW_NOTES_RU.md).
3. **File → Save Screen** в Simulator или `Cmd+S`.
4. Положите PNG в `store_assets/screenshots/_raw/iphone/`.
5. `./scripts/generate_store_screenshots.sh --resize-only`

---

## 6. Android-эмулятор (опционально)

Если установлен Android Studio:

```bash
flutter emulators --launch <avd_id>
flutter test integration_test/store_screenshots_test.dart -d emulator-5554
```

Скопируйте PNG в `_raw/android/` и при необходимости добавьте ресайз в скрипт.  
Для Play часто достаточно ресайза с iPhone master (скрипт уже создаёт `google_play/*`).

---

## 7. Чеклист перед публикацией

- [ ] 4–6 скриншотов на русском языке
- [ ] Нет личных данных / тестовых паролей на экране
- [ ] Статус-бар iOS без «чужого» времени/заряда (Simulator — норма)
- [ ] iPhone 6.7" или 6.9" загружен в App Store Connect
- [ ] iPad 12.9" загружен (если iPad в поддерживаемых устройствах)
- [ ] Google Play: phone + feature graphic 1024×500
- [ ] Версия приложения в консоли совпадает с `pubspec.yaml`

---

## 8. Связанные файлы

| Файл | Назначение |
|------|------------|
| `scripts/generate_store_screenshots.sh` | съёмка + ресайз |
| `integration_test/store_screenshots_test.dart` | сценарий кадров |
| `store_assets/screenshots/README.md` | краткая справка |
| [APP_STORE_REVIEW_NOTES_RU.md](./APP_STORE_REVIEW_NOTES_RU.md) | сценарии для ревью Apple |

---

*При смене требований Apple/Google обновите массивы размеров в `scripts/generate_store_screenshots.sh`.*
