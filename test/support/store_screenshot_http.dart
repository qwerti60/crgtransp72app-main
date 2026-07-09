import 'dart:io';

/// Разрешает реальные HTTP-запросы в widget-тестах.
class StoreScreenshotHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 15)
      ..idleTimeout = const Duration(seconds: 15);
  }
}

Future<void> enableStoreScreenshotNetwork() async {
  HttpOverrides.global = StoreScreenshotHttpOverrides();
}
