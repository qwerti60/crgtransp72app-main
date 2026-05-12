import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/CityScreen.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../design/colors.dart';
import 'changerol_page.dart';
import 'loginpage.dart';
import 'outputob.dart';

Future<bool> _isAuthorizedUser() async {
  final token = await getSecurefcm_token();
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http
        .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return false;
    final data = json.decode(response.body);
    return data['error'] == null && data['idusers'] != null;
  } catch (_) {
    return false;
  }
}

Future<void> _showAuthRequiredDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text(
          'Эта функция доступна только для зарегистрированных пользователей.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text('Авторизация'),
          ),
        ],
      );
    },
  );
}

void main() {
  runApp(const MyAppI1());
}

class MyAppI1 extends StatelessWidget {
  const MyAppI1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Услуги',
            style: TextStyle(
              color: whiteprColor,
            ),
          ),
          backgroundColor: blueaccentColor,
        ),
        body: const MyImageGrid(),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final isAuthorized = await _isAuthorizedUser();
            if (!context.mounted) return;

            if (!isAuthorized) {
              await _showAuthRequiredDialog(context);
              return;
            }

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
    final response = await http.get(
        Uri.parse("${Config.baseUrl}/api/getimage.php")
            .replace(queryParameters: {'bd': db}));
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
                                builder: (_) => CityScreen(
                                      indexName: images[index].name,
                                    ),
                            ),
                        );
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
