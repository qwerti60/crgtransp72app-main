import 'package:flutter/material.dart';

void main() {
  runApp(const tehn_screen());
}

class tehn_screen extends StatelessWidget {
  const tehn_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Грузовые перевозки',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Грузовые перевозки'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Поиск',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: const [
// Раздел "Грузовые перевозки"
                    CategorySection(
                      title: 'Грузовые перевозки',
                      items: [
                        CategoryItem(
                            text: 'Перевозка до 1 т.',
                            imagePath: 'assets/images/transport2.png'),
                        CategoryItem(
                            text: 'Перевозка до 2 т.',
                            imagePath: 'assets/images/transport2.png'),
                        CategoryItem(
                            text: 'Перевозка до 3.5 т.',
                            imagePath: 'assets/images/transport3.png'),
                        CategoryItem(
                            text: 'Перевозка до 5 т.',
                            imagePath: 'assets/images/transport4.png'),
                        CategoryItem(
                            text: 'Перевозка до 10 т.',
                            imagePath: 'assets/images/transport5.png'),
                      ],
                    ),
// Раздел "Спецтехника"
                    CategorySection(
                      title: 'Спецтехника',
                      items: [
                        CategoryItem(
                            text: 'Автовышки',
                            imagePath: 'assets/images/special1.png'),
                        CategoryItem(
                            text: 'Автокран',
                            imagePath: 'assets/images/special2.png'),
                        CategoryItem(
                            text: 'Ассенизатор и илососы',
                            imagePath: 'assets/images/special3.png'),
// Добавьте другие элементы аналогично...
                      ],
                    ),
// далее добавьте другие секции подобным образом
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  final String title;
  final List<CategoryItem>
      items; // Убедитесь, что тип items соответствует вашему списку объектов CategoryItem

  const CategorySection({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Мы применяем .map() к items и используем .toList() для конвертации в список виджетов
        Wrap(
          alignment: WrapAlignment.start,
          children: items
              .map((item) => item)
              .toList(), // Этот код ожидает, что каждый объект в items уже является виджетом
        ),
      ],
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String text;
  final String imagePath;

  const CategoryItem({super.key, required this.text, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Image.asset(imagePath, width: 50, height: 50),
          const SizedBox(height: 4.0),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
