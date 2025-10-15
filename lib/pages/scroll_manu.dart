import 'package:flutter/material.dart';

void main() {
  runApp(const MyAppSM());
}

class MyAppSM extends StatelessWidget {
  const MyAppSM({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State {
  final ScrollController _scrollController = ScrollController();

// Предполагается, что у вас есть ключи, связанные с виджетами, до которых вы хотите прокрутить
  GlobalKey specTechniqueKey = GlobalKey();
  GlobalKey cargoTransfersKey = GlobalKey();
  GlobalKey loadingHelpKey = GlobalKey();

  void scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context,
          duration: const Duration(seconds: 1), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пример приложения'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => scrollTo(specTechniqueKey),
                    child: const Text('Спецтехника'),
                  ),
                  TextButton(
                    onPressed: () => scrollTo(cargoTransfersKey),
                    child: const Text('Грузовые перевозки'),
                  ),
                  TextButton(
                    onPressed: () => scrollTo(loadingHelpKey),
                    child: const Text('Помощь с погрузкой'),
                  ),
                ],
              )),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  SpecTechniqueSection(key: specTechniqueKey),
                  CargoTransfersSection(key: cargoTransfersKey),
                  LoadingHelpSection(key: loadingHelpKey),
// Вы можете добавить другие разделы здесь
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Определяем плейсхолдер виджеты для каждого раздела
class SpecTechniqueSection extends StatefulWidget {
  const SpecTechniqueSection({super.key});

  @override
  SpecTechniqueSectionState createState() => SpecTechniqueSectionState();
}

class SpecTechniqueSectionState extends State {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // указывайте необходимую высоту
      color: Colors.yellow,
      child: const Center(child: Text('Спецтехника')),
    );
  }
}

class CargoTransfersSection extends StatefulWidget {
  const CargoTransfersSection({super.key});

  @override
  CargoTransfersSectionState createState() => CargoTransfersSectionState();
}

class CargoTransfersSectionState extends State {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: Colors.green,
      child: const Center(child: Text('Грузовые перевозки')),
    );
  }
}

class LoadingHelpSection extends StatefulWidget {
  const LoadingHelpSection({super.key});

  @override
  LoadingHelpSectionState createState() => LoadingHelpSectionState();
}

class LoadingHelpSectionState extends State {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: Colors.blue,
      child: const Center(child: Text('Помощь с погрузкой')),
    );
  }
}
