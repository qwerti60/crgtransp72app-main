import 'package:crgtransp72app/pages/CityScreenisp.dart';
import 'package:crgtransp72app/pages/change_user.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/loginpage.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../design/colors.dart';

Future<bool> _isAuthorizedUser() async {
  final token = await getSecurefcm_token();
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http
        .get(Uri.parse('https://ivnovav.ru/api/getuserinfo.php?token=$token'))
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
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
          'Услуги',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const change_user()),
              );
            },
            child: const Text(
              'Роли',
              style: TextStyle(color: whiteprColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text(
              'Войти',
              style: TextStyle(color: whiteprColor),
            ),
          ),
        ],
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

          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const changerol1()));
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
    final response = await http
        .get(
          Uri.parse('https://ivnovav.ru/api/getimage.php')
              .replace(queryParameters: {'bd': db}),
        )
        .timeout(const Duration(seconds: 12));
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
                                builder: (_) => CityScreenIsp(
                                      indexName: images[index].name,
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
