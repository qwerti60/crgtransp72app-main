import 'package:flutter/material.dart';
import 'package:crgtransp72app/api/service_images_api.dart';

import '../design/colors.dart';
import 'changerol_page2.dart';
import 'outputob.dart';

void main() {
  runApp(const MyAppI11());
}

class MyAppI11 extends StatelessWidget {
  const MyAppI11({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Заказ техники',
            style: TextStyle(
              color: whiteprColor,
            ),
          ),
          backgroundColor: blueaccentColor,
        ),
        body: const MyImageGrid(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Действие, производимое при нажатии на кнопку
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const changerol1()));
            print('Нажата плавающая кнопка');
          }, // Иконка, отображаемая на кнопке
          backgroundColor: blueaccentColor,
          child: const Icon(Icons.add), // Цвет фона кнопки
        ),
      ),
    );
  }
}

class MyImageGrid extends StatefulWidget {
  const MyImageGrid({super.key});

  @override
  _MyImageGridState createState() => _MyImageGridState();
}

class _MyImageGridState extends State {
  late Future<ServiceImagesBundle> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = ServiceImagesApi.fetchAll();
  }

  Widget imagesSection(String title, List<ServiceImageItem> images) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(title, style: const TextStyle(fontSize: 20)),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            itemCount: images.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => outputob(
                                nameImg: images[index].name,
                                city: '',
                                ignoreCityFilter: true,
                              )));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ServiceImagePreview(item: images[index]),
                      ),
                      const SizedBox(height: 8),
                      Text(images[index].name, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceImagesBundle>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final catalog = snapshot.data!;
          return CustomScrollView(
            slivers: [
              imagesSection('Спецтехника', catalog.vidt),
              imagesSection('Грузовые перевозки', catalog.vidg),
              imagesSection('Помощь с погрузкой', catalog.gruzchik),
            ],
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Не удалось загрузить: ${snapshot.error}'),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
