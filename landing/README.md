# Лендинг Грузоперевозки72

Статический одностраничный сайт. Логотип и иконка — из приложения (`assets/images/logo.png`, `assets/images/icon/icon.png`).

## Локальный просмотр

```bash
open landing/index.html
```

## Деплой на gruzoperevozki72.ru

Скопируйте содержимое каталога `landing/` в корень сайта:

```bash
rsync -av landing/ user@gruzoperevozki72.ru:/path/to/site/
```

После публикации приложений обновите ссылки `#link-appstore` и `#link-googleplay` в `index.html`.
