import 'dart:io';
import 'dart:ui' as ui;

import 'package:crgtransp72app/design/app_theme.dart';
import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _screenshotKey = ValueKey('store_screenshot');

Future<void> _snap(WidgetTester tester, String outPath) async {
  await tester.pumpAndSettle(const Duration(seconds: 15));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_screenshotKey),
  );
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(outPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

Widget _wrap(Widget child) {
  return RepaintBoundary(key: _screenshotKey, child: child);
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3.0;
}

void _setTabletViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(2048, 2732);
  tester.view.devicePixelRatio = 2.0;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  final rawIphone = Directory('store_assets/screenshots/_raw/iphone');
  final rawIpad = Directory('store_assets/screenshots/_raw/ipad');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Store screenshots — iPhone', () {
    testWidgets('customer catalog and search', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: crgAppTheme(),
        home: const MyApp(initialPage: 0),
      )));
      await _settle(tester);
      await _snap(tester, '${rawIphone.path}/01_customer_services.png');

      await tester.tap(find.text(CustomerShellNav.tabOrders));
      await _settle(tester);
      await _snap(tester, '${rawIphone.path}/02_customer_search.png');
    });

    testWidgets('performer listings and applications', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: crgAppTheme(),
        home: const MyAppZakazScreen(initialPage: 0),
      )));
      await _settle(tester);
      await _snap(tester, '${rawIphone.path}/03_performer_listings.png');

      await tester.tap(find.text(PerformerShellNav.tabApplications));
      await _settle(tester);
      await _snap(tester, '${rawIphone.path}/04_performer_search.png');
    });
  });

  group('Store screenshots — iPad', () {
    testWidgets('customer catalog', (tester) async {
      _setTabletViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: crgAppTheme(),
        home: const MyApp(initialPage: 0),
      )));
      await _settle(tester);
      await _snap(tester, '${rawIpad.path}/01_customer_services.png');
    });

    testWidgets('performer listings', (tester) async {
      _setTabletViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: crgAppTheme(),
        home: const MyAppZakazScreen(initialPage: 0),
      )));
      await _settle(tester);
      await _snap(tester, '${rawIpad.path}/03_performer_listings.png');
    });
  });
}
