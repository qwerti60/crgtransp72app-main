# Карта веток экранов и меню

Этот документ фиксирует различия между двумя основными ветками приложения:

- Ветка **заказчика**
- Ветка **грузоперевозчика**

Важно: у веток могут быть экраны с похожими названиями (например, "Список городов", "Объявления"), но это **разные экраны и разные файлы**.

## Общее правило

- Нельзя смешивать экраны и меню между ветками.
- Если название экрана похоже, все равно проверять файл/класс, к какой ветке он относится.
- Нижнее меню у каждой ветки свое:
  - **Заказчик**: `CustomerBottomNav`
  - **Грузоперевозчик**: `PerformerBottomNav`

## Ветка заказчика

### Точка входа

- Роль: кнопка `Я заказчик`
- Основной контейнер: `lib/pages/zakaz_screen1.dart`

### Ключевые экраны и файлы

- Первая вкладка **Услуги**: `lib/pages/get_vt_z.dart` — `MyAppI1z()` / `MyImageGrid`; тап по категории → `CityScreenisp.dart` (`CityScreenIsp`).
- Список городов (заказчик): `lib/pages/CityScreenisp.dart` (`CityScreenIsp`, переход из `get_vt_z`); на экране — **`CustomerBottomNav`** с `currentIndex: 0` («Услуги»), по аналогии с `CityScreen` + `PerformerBottomNav` у исполнителя.
- Поиск исполнителей «Исполнители»: `lib/pages/outputob.dart` — меню заказчика (`CustomerBottomNav`, см. параметр ниже).
- **Расширенный поиск** (вкладка «Заказы»): `CustomerSearchScreen` (`SearchFormisp`) → `outputob` через `search_services.php`.
- **Мои объявления** заказчика: `Ads2Page` / `Ads2Shell` в `ads2.dart` — вложенный `Navigator`, меню снаружи; кнопка **«Найти исполнителей»** на активных карточках.
- Экран предложения заказа исполнителю: `lib/pages/OfferScreen2.dart` с `useCustomerNavigation: true` (открывается из `outputob.dart`). После успешной отправки — переход на **`lib/pages/zprofil_zakaz.dart`** с `useCustomerMenu: true` (нижнее меню заказчика, вкладка «Заказы» активна в `CustomerBottomNav` у целевого экрана); `nameImg` = id объявления (`userid` с карточки), `base` = категория `bd`.

- Лента **объявлений заказчиков** (смотрит грузоперевозчик): `lib/pages/outputobz.dart` — заголовок «Объявления», нижнее меню грузоперевозчика (`PerformerBottomNav`).
- Профиль (ветка заказчика): `lib/pages/zprofil_page.dart` — под именем рейтинг и отзывы (`ProfileRatingRow` → `ReviewScreen`).

### Меню

- **Один главный shell:** `lib/pages/zakaz_screen1.dart` (`MyApp` / `MyCustomScreen`)
- **Нижнее меню на дочерних экранах:** `lib/pages/customer_bottom_nav.dart` (`CustomerBottomNav`)
- **Гость:** 2 вкладки — «Услуги», «Заказы» (без «Профиль»)
- **Обёртки профиля** (`menuzak.dart`, `HistortScreen1z.dart`) используют только `CustomerBottomNav`, без второго shell

## Ветка грузоперевозчика

### Точка входа

- Роль: кнопка `Я грузоперевозчик`
- Основной контейнер: `lib/pages/zakaz_screen2.dart`

### Ключевые экраны и файлы

- Первая вкладка **Техника**: `lib/pages/get_vt.dart` — `MyImageGrid`; тап по категории → `CityScreen.dart`.
- Список городов (грузоперевозчик): `lib/pages/CityScreen.dart` (переход настроен из `get_vt`).
- После списка городов грузоперевозчика — просмотр **объявлений заказчиков** в `lib/pages/outputobz.dart` (меню грузоперевозчика).
- **Расширенный поиск** (вкладка «Заявки»): `PerformerSearchScreen` (`SearchForm`) → `outputobz` через `search_services.php`.
- **Мои объявления** исполнителя: `Ads1Page` / `Ads1Shell` в `ads1.dart` — вложенный `Navigator`; кнопка **«Найти заявки»** на опубликованных карточках.
- Профиль (ветка грузоперевозчика): `lib/pages/zprofil_page2.dart` — под именем рейтинг и отзывы (`ProfileRatingRow` → `ReviewScreenz`).

### Меню

- **Один главный shell:** `lib/pages/zakaz_screen2.dart` (`MyAppZakazScreen` / `MyCustomScreen`)
- **Нижнее меню на дочерних экранах:** `lib/pages/performer_bottom_nav.dart` (`PerformerBottomNav`)
- **Гость:** 2 вкладки — «Объявления», «Заявки» (без «Профиль»)
- **Обёртки профиля** (`test.dart`, `scrmenu.dart`, `bmenu.dart`, `bmenucopy.dart`) используют только `PerformerBottomNav`, без второго shell

### Обходные экраны и вложенные оболочки (та же логика «Техника → города», что у `zakaz_screen2`)

Чтобы снова не подставить **заказческую** сетку городов (`get_vt_z` → `CityScreenIsp`, `get_citiesisp.php`), во всех перечисленных местах первая вкладка / экран каталога для исполнителя должен браться из **`lib/pages/get_vt.dart`** (`MyImageGrid`, при необходимости импорт с префиксом, например `performer_services`), а переход по категории — в **`lib/pages/CityScreen.dart`**.

| Файл / виджет | Назначение |
|---------------|------------|
| `lib/pages/zakaz_screen2.dart` | Основной shell грузоперевозчика, вкладка «Техника» |
| `lib/pages/history_isp.dart` | История заказов исполнителя: вкладка с каталогом техники |
| `lib/pages/outputobzlikes1.dart` | Избранные заказчики: первая вкладка с сеткой категорий |
| `lib/pages/bmenu.dart` (`HistortScreen12`) | Нижнее меню: первая вкладка «Объявления» |
| `lib/pages/scrmenu.dart` (`HistortScreen1`) | Оболочка сценариев (в т.ч. отзыв): первый builder — сетка из `get_vt.dart`, не из `get_vt_z.dart` |

В этих экранах **нельзя** использовать `MyAppI1z` / `MyImageGrid` из `get_vt_z.dart` для роли исполнителя — откроются чужие города и API.

## Критичные соответствия (чтобы не ломать логику)

- `CityScreenisp.dart` (`CityScreenIsp`, из `get_vt_z`) → нижнее меню **`CustomerBottomNav(0)`** на самом экране городов; далее тап по городу → `outputob.dart` с `useCustomerNavigation: true` (заказчик: «Исполнители», меню заказчика).
- `CityScreen.dart` (из `get_vt`) → `outputobz.dart` (грузоперевозчик: объявления заказчиков, меню исполнителя).
- Поиск заявок у заказчика: `SearchFormisp` → `CustomerSearchScreen`; при переходе на `outputob.dart` передаётся `SearchParams` → `search_services.php`; для shell заказчика — `embedInCustomerShell: true`.
- Поиск заявок у исполнителя: `SearchForm` → `PerformerSearchScreen` → `outputobz` + `search_services.php`.
- **Мои объявления:** редактирование открывается во вложенном `Navigator` (`Ads1Shell` / `Ads2Shell` или обёртки `menuzak` / `HistortScreen`); после сохранения — `Navigator.pop`, не новый `MaterialApp`.
- В `outputob.dart` параметр `useCustomerNavigation`: `true` — меню заказчика (`CustomerBottomNav`), `false` — меню грузоперевозчика (`PerformerBottomNav`).
- `outputobz.dart` — экран объявлений для грузоперевозчика: использовать `PerformerBottomNav`.
- `OfferScreen2`: при `useCustomerNavigation: true` после отправки — `zprofil_zakaz` + `useCustomerMenu: true`; при `false` (исполнитель) — по-прежнему `zprofil_zayavki` с `useCustomerMenu: false`.
## Проверка перед релизом

Проверять отдельно оба сценария:

1. `Я заказчик` -> целевой экран -> корректное меню заказчика
2. `Я грузоперевозчик` -> целевой экран -> корректное меню грузоперевозчика

Если в одном сценарии появляется меню другой ветки, это регресс смешивания навигации.
