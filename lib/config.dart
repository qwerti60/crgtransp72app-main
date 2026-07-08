class Config {
  static const String baseUrl = 'http://gruzoperevozki72.ru';
  static const String recaptchaSiteKey =
      '6Ldk7NwrAAAAACT-aKjylHZGoKA1JtjnWGHFltzm';

  /// Совпадает с полем `city` в ответе `get_cities.php` / `get_citiesisp.php`, когда в разделе ещё нет объявлений.
  static const String emptyCityListPlaceholder =
      'В этом разделе ещё нет городов с объявлениями';

  static Uri apiUri(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final apiPath =
        normalized.startsWith('/api/') ? normalized : '/api$normalized';
    return Uri.parse(baseUrl).replace(
      path: apiPath,
      queryParameters: query,
    );
  }
}
