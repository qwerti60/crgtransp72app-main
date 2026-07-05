import 'package:crgtransp72app/design/app_theme.dart';
import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Автосъёмка экранов для App Store / Google Play.
/// Запуск: scripts/generate_store_screenshots.sh
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> snap(String name) async {
    await binding.convertFlutterSurfaceToImage();
    await binding.takeScreenshot(name);
  }

  Future<void> settle(WidgetTester tester, {int seconds = 12}) async {
    await tester.pumpAndSettle(Duration(seconds: seconds));
  }

  group('Store screenshots — заказчик', () {
    testWidgets('customer catalog and search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: crgAppTheme(),
          home: const MyApp(initialPage: 0),
        ),
      );
      await settle(tester, seconds: 14);
      await snap('01_customer_services');

      await tester.tap(find.text(CustomerShellNav.tabOrders));
      await settle(tester, seconds: 10);
      await snap('02_customer_search');
    });
  });

  group('Store screenshots — исполнитель', () {
    testWidgets('performer listings and applications', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: crgAppTheme(),
          home: const MyAppZakazScreen(initialPage: 0),
        ),
      );
      await settle(tester, seconds: 14);
      await snap('03_performer_listings');

      await tester.tap(find.text(PerformerShellNav.tabApplications));
      await settle(tester, seconds: 10);
      await snap('04_performer_search');
    });
  });
}
