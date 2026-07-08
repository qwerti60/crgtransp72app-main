import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/api/service_images_api.dart';
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
                          builder: (_) => CityScreen(
                                indexName: images[index].name,
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
