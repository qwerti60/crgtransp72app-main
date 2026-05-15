class Config {
  static const String baseUrl = 'https://ivnovav.ru';
  static const String recaptchaSiteKey =
      '6Ldk7NwrAAAAACT-aKjylHZGoKA1JtjnWGHFltzm';

  /// Совпадает с полем `city` в ответе `get_cities.php` / `get_citiesisp.php`, когда в разделе ещё нет объявлений.
  static const String emptyCityListPlaceholder =
      'В этом разделе ещё нет городов с объявлениями';
}
