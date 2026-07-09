import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Драйвер для `flutter drive`: сохраняет PNG со скриншотов на диск.
Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        final dir = Directory('store_assets/screenshots/_raw/iphone');
        await dir.create(recursive: true);
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(bytes);
        // ignore: avoid_print
        print('Saved screenshot: ${file.path}');
        return true;
      },
    );
