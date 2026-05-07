import 'package:crgtransp72app/pages/CityScreen.dart';
import 'package:crgtransp72app/pages/changerol_page.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../design/colors.dart';

void main() {
  runApp(const MyAppI1z());
}

class MyAppI1z extends StatelessWidget {
  const MyAppI1z({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Техника',
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
                MaterialPageRoute(builder: (context) => const changerol()));
            print('Нажата плавающая кнопка');
          }, // Иконка, отображаемая на кнопке
          backgroundColor: blueaccentColor,
          child: const Icon(Icons.add), // Цвет фона кнопки
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        bottomNavigationBar: const PerformerBottomNav(currentIndex: 0),
      ),
    );
  }
}

// Use this widget when the screen is opened inside another shell
// that already has BottomNavigationBar.
class MyAppI1zPage extends StatelessWidget {
  const MyAppI1zPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Техника',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: const MyImageGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const changerol()));
          print('Нажата плавающая кнопка');
        },
        backgroundColor: blueaccentColor,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class MyImageGrid extends StatefulWidget {
  final bool isGuestMode;

  const MyImageGrid({super.key, this.isGuestMode = false});

  @override
  _MyImageGridState createState() => _MyImageGridState();
}

class _MyImageGridState extends State<MyImageGrid> {
  late Future<List<ImageData>> imagesVidt;
  late Future<List<ImageData>> imagesVidg;
  late Future<List<ImageData>> imagesGruzchik;
  late String nameImg;
  Future<List<ImageData>> fetchImages(String db) async {
    final response =
        await http.get(Uri.parse('http://ivnovav.ru/api/getimage.php?bd=$db'));
    if (response.statusCode == 200) {
      return (json.decode(response.body) as List)
          .map((data) => ImageData.fromJson(data))
          .toList();
    } else {
      throw Exception('Failed to load images');
    }
  }

  @override
  void initState() {
    super.initState();
    imagesVidt = fetchImages("vidt");
    imagesVidg = fetchImages("vidg");
    imagesGruzchik = fetchImages("gruzchik");
  }

  Widget imagesSection(String title, Future images) {
    return FutureBuilder(
      future: images,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var images = snapshot.data!;
          return SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(title, style: const TextStyle(fontSize: 20)),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(), // Add this line
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                  ),
                  itemCount: images.length,
// Inside GridView.builder item builder
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        if (widget.isGuestMode) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Для перехода к заявкам и профилю войдите в аккаунт',
                              ),
                            ),
                          );
                          return;
                        }

                        int base =
                            0; // Объявление переменной за пределами условного блока

                        if (title == 'Заказ спецтехники') base = 2;
                        if (title == 'Заказ грузовыех перевозок') base = 1;
                        if (title == 'Заказ грузчиков') base = 3;
                        print('object567');
                        print(base);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CityScreen(
                                      //outputobz(
                                      indexName: images[index].name,
                                      //  base: base, // Передача переменной
                                    )));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.memory(
                                base64Decode(images[index]
                                    .image), // Make sure this is the correct decoding for your image
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(images[index].name,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Text("${snapshot.error}"),
          );
        }
        return const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        imagesSection('Заказ спецтехники', imagesVidt),
        imagesSection('Заказ грузовыех перевозок', imagesVidg),
        imagesSection('Заказ грузчиков', imagesGruzchik),
      ],
    );
  }
}

class ImageData {
  final String image;
  final String name;

  ImageData({required this.image, required this.name});

  factory ImageData.fromJson(Map json) {
    return ImageData(
      image: json['image'],
      name: json['name'],
    );
  }
}
