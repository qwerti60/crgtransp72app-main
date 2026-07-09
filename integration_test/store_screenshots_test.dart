import 'package:crgtransp72app/design/app_theme.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Автосъёмка экранов для App Store / Google Play (без debug banner).
///
/// Локально:
///   ./scripts/generate_store_screenshots.sh --simulator
///
/// Codemagic:
///   ./scripts/codemagic_store_screenshots.sh
///   (workflow `store-screenshots`)
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> snap(String name) async {
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(name);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Widget app(Widget home) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: crgAppTheme(),
      home: home,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Store screenshots', () {
    testWidgets('01 customer services', (tester) async {
      await tester.pumpWidget(app(const MyApp(initialPage: 0)));
      await settle(tester);
      await snap('01_customer_services');
    });

    testWidgets('02 customer search', (tester) async {
      await tester.pumpWidget(app(const MyApp(initialPage: 1)));
      await settle(tester);
      await snap('02_customer_search');
    });

    testWidgets('03 performer listings', (tester) async {
      await tester.pumpWidget(app(const MyAppZakazScreen(initialPage: 0)));
      await settle(tester);
      await snap('03_performer_listings');
    });

    testWidgets('04 performer search', (tester) async {
      await tester.pumpWidget(app(const MyAppZakazScreen(initialPage: 1)));
      await settle(tester);
      await snap('04_performer_search');
    });
  });
}
