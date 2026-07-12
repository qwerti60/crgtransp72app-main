import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crgtransp72app/design/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _screenshotKey = ValueKey('store_screenshot');

Future<void> _snap(WidgetTester tester, String outPath) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_screenshotKey),
  );
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(outPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

Widget _wrap(Widget child) {
  return RepaintBoundary(
    key: _screenshotKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: child,
    ),
  );
}

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3.0;
}

void _setTabletViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(2048, 2732);
  tester.view.devicePixelRatio = 2.0;
}

Future<Uint8List> _readPlaceholder() async {
  return File('test/fixtures/placeholder.png').readAsBytes();
}

class _StoreScaffold extends StatelessWidget {
  const _StoreScaffold({
    required this.title,
    required this.body,
    required this.currentIndex,
    required this.items,
    this.badgeIndex,
  });

  final String title;
  final Widget body;
  final int currentIndex;
  final List<String> items;
  final int? badgeIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        backgroundColor: blueaccentColor,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: whiteprColor)),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: violetColor,
        unselectedItemColor: TexticonsColor,
        type: BottomNavigationBarType.fixed,
        items: [
          for (var i = 0; i < items.length; i++)
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(_navIcon(i)),
                  if (badgeIndex == i)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: readColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: items[i],
            ),
        ],
      ),
    );
  }

  IconData _navIcon(int index) {
    switch (index) {
      case 0:
        return Icons.local_shipping_outlined;
      case 1:
        return Icons.subject;
      default:
        return Icons.account_circle_outlined;
    }
  }
}

class _CatalogScreen extends StatelessWidget {
  const _CatalogScreen({required this.imageBytes, this.tablet = false});

  final Uint8List imageBytes;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final items = const [
      'Мини-погрузчики',
      'Экскаваторы',
      'Грузоперевозки',
      'Грузчики',
      'Манипуляторы',
      'Самосвалы',
    ];
    final crossAxisCount = tablet ? 3 : 2;

    return _StoreScaffold(
      title: 'Услуги',
      currentIndex: 0,
      items: const ['Услуги', 'Заказы', 'Профиль'],
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: blueaccentColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Техника, перевозки и грузчики в одном приложении',
                    style: TextStyle(
                      color: whiteprColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.bolt, color: Colors.amberAccent, size: 42),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: tablet ? 0.92 : 0.82,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: whiteprColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.memory(
                            imageBytes,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          items[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchScreen extends StatelessWidget {
  const _SearchScreen({
    required this.title,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.currentIndex,
  });

  final String title;
  final String primaryLabel;
  final String secondaryLabel;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return _StoreScaffold(
      title: title,
      currentIndex: currentIndex,
      badgeIndex: currentIndex == 1 ? 1 : null,
      items: currentIndex == 1
          ? const ['Услуги', 'Заказы', 'Профиль']
          : const ['Объявления', 'Заявки', 'Профиль'],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                children: [
                  _InputRow(label: 'Город', value: 'Тюмень'),
                  SizedBox(height: 10),
                  _InputRow(label: 'Услуга', value: 'Мини-погрузчики'),
                  SizedBox(height: 10),
                  _InputRow(label: 'Бюджет', value: 'до 5 000 ₽'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Chip(text: primaryLabel),
                const SizedBox(width: 8),
                _Chip(text: secondaryLabel),
                const Spacer(),
                const Icon(Icons.tune, color: violetColor),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Актуальные предложения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: const [
                  _OfferCard(
                    title: 'Мини-погрузчик Bobcat',
                    subtitle: 'Тюмень • сегодня • 4 500 ₽',
                    badge: 'Быстрый выезд',
                  ),
                  _OfferCard(
                    title: 'Грузчики 2–4 человека',
                    subtitle: 'Винзили • сегодня • от 600 ₽/час',
                    badge: 'Проверенный исполнитель',
                  ),
                  _OfferCard(
                    title: 'Манипулятор 5 тонн',
                    subtitle: 'Тюмень • завтра • 8 000 ₽',
                    badge: 'Фото техники',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: whiteprColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(value, style: const TextStyle(fontSize: 17)),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: violetColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteprColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: GreenColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8F1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: GreenColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  final rawIphone = Directory('store_assets/screenshots/_raw/iphone');
  final rawIpad = Directory('store_assets/screenshots/_raw/ipad');

  group('Store screenshots — iPhone', () {
    testWidgets('01 customer services', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final imageBytes = await _readPlaceholder();
      await tester.pumpWidget(_wrap(_CatalogScreen(imageBytes: imageBytes)));
      await tester.pump();
      await _snap(tester, '${rawIphone.path}/01_customer_services.png');
    });

    testWidgets('02 customer search', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const _SearchScreen(
            title: 'Заказы',
            primaryLabel: 'По цене',
            secondaryLabel: '12 предложений',
            currentIndex: 1,
          ),
        ),
      );
      await tester.pump();
      await _snap(tester, '${rawIphone.path}/02_customer_search.png');
    });

    testWidgets('03 performer listings', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final imageBytes = await _readPlaceholder();
      await tester.pumpWidget(_wrap(_CatalogScreen(imageBytes: imageBytes)));
      await tester.pump();
      await _snap(tester, '${rawIphone.path}/03_performer_listings.png');
    });

    testWidgets('04 performer search', (tester) async {
      _setPhoneViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const _SearchScreen(
            title: 'Заявки',
            primaryLabel: 'Без посредников',
            secondaryLabel: '24 заявки',
            currentIndex: 1,
          ),
        ),
      );
      await tester.pump();
      await _snap(tester, '${rawIphone.path}/04_performer_search.png');
    });
  });

  group('Store screenshots — iPad', () {
    testWidgets('01 customer services', (tester) async {
      _setTabletViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final imageBytes = await _readPlaceholder();
      await tester.pumpWidget(
        _wrap(_CatalogScreen(imageBytes: imageBytes, tablet: true)),
      );
      await tester.pump();
      await _snap(tester, '${rawIpad.path}/01_customer_services.png');
    });

    testWidgets('03 performer listings', (tester) async {
      _setTabletViewport(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const _SearchScreen(
            title: 'Заявки',
            primaryLabel: 'Новые заказы',
            secondaryLabel: 'Подходящие по городу',
            currentIndex: 1,
          ),
        ),
      );
      await tester.pump();
      await _snap(tester, '${rawIpad.path}/03_performer_listings.png');
    });
  });
}
