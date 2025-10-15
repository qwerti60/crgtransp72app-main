import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                //outputob
//                                builder: (_) => MyAppGUD1(
                                //                                     nameImg: images[index].name,
//                                    )
//                                    ));
                                builder: (_) => outputob(
                                      nameImg: images[index].name,
                                    )));
                        /*                              Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => creguser5_name_(
                                    rollNum: rollNum,
                                    statNum: statNum,
                                    firstName: firstName,
                                    middleName: middleName,
                                    lastName: lastName,
                                    city: city,
                                    phone: phone,
                                    email: email,
                                    password: password,
                                    namefirm: '',
                                    innStr: '',
                                    ogrnStr: '',
                                    kppStr: '',
                                  )));*/
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
        imagesSection('Спецтехника', imagesVidt),
        imagesSection('Грузовые перевозки', imagesVidg),
        imagesSection('Помощь с погрузкой', imagesGruzchik),
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
