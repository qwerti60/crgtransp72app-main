/// Окружение API / MySQL.
///
/// | Сборка | Куда ходит | БД |
/// |--------|------------|-----|
/// | Уже в App Store / Google Play | `/api/` | старая (prod) |
/// | Новая тестовая APK | `/api_test/` | новая (test) |
/// | Релиз в сторы (будущий) | `/api/` | старая (prod) |
///
/// Переключение при сборке:
/// ```bash
/// # тестовая APK → новая БД
/// flutter build apk --release --dart-define=CRG_API_ENV=prodTest
///
/// # в сторы → старая БД (как у установленных приложений)
/// flutter build apk --release --dart-define=CRG_API_ENV=prod
/// flutter build appbundle --release --dart-define=CRG_API_ENV=prod
/// ```
enum ApiEnv { local, prod, prodTest }

class Config {
  /// По умолчанию [ApiEnv.prod] — как у приложений из сторов (старая БД).
  /// Тестовые сборки: `--dart-define=CRG_API_ENV=prodTest`.
  static const String _envName = String.fromEnvironment(
    'CRG_API_ENV',
    defaultValue: 'prod',
  );

  static ApiEnv get env {
    switch (_envName) {
      case 'local':
        return ApiEnv.local;
      case 'prodTest':
      case 'test':
        return ApiEnv.prodTest;
      case 'prod':
      default:
        return ApiEnv.prod;
    }
  }

  static String get host {
    switch (env) {
      case ApiEnv.local:
        // Android-эмулятор: 'http://10.0.2.2:8080'
        return 'http://127.0.0.1:8080';
      case ApiEnv.prod:
      case ApiEnv.prodTest:
        return 'http://gruzoperevozki72.ru';
    }
  }

  /// Префикс папки API на сервере.
  static String get apiPrefix {
    switch (env) {
      case ApiEnv.local:
        return '';
      case ApiEnv.prod:
        return '/api';
      case ApiEnv.prodTest:
        return '/api_test';
    }
  }

  /// Хост без `/api` (совместимость со старым кодом).
  static String get baseUrl => host;

  /// База для запросов: `…/api` (сторы) или `…/api_test` (новые сборки).
  static String get apiBase => '$host$apiPrefix';

  static const String recaptchaSiteKey =
      '6Ldk7NwrAAAAACT-aKjylHZGoKA1JtjnWGHFltzm';

  /// Совпадает с полем `city` в ответе `get_cities.php` / `get_citiesisp.php`, когда в разделе ещё нет объявлений.
  static const String emptyCityListPlaceholder =
      'В этом разделе ещё нет городов с объявлениями';

  /// Путь вида `/getuserinfo.php` или `/api/getuserinfo.php` → полный URL под текущий [apiPrefix].
  static String apiUrl(String path) {
    var p = path.startsWith('/') ? path : '/$path';
    if (p.startsWith('/api_test/')) {
      p = p.substring('/api_test'.length);
    } else if (p.startsWith('/api/')) {
      p = p.substring('/api'.length);
    }
    return '$apiBase$p';
  }

  static Uri apiUri(String path, {Map<String, String>? query}) {
    final uri = Uri.parse(apiUrl(path));
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {...uri.queryParameters, ...query});
  }
}
