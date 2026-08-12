import 'package:crgtransp72app/pages/CityScreenisp.dart';
import 'package:crgtransp72app/api/service_images_api.dart';
import 'package:crgtransp72app/config.dart';
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
        .get(Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'))
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
class MyAppI1zPage extends StatefulWidget {
  const MyAppI1zPage({super.key, this.isAuthenticated});

  /// Если передано из родительского shell — не делаем лишний запрос.
  final bool? isAuthenticated;

  @override
  State<MyAppI1zPage> createState() => _MyAppI1zPageState();
}

class _MyAppI1zPageState extends State<MyAppI1zPage> {
  bool? _isAuthorized;

  @override
  void initState() {
    super.initState();
    if (widget.isAuthenticated != null) {
      _isAuthorized = widget.isAuthenticated;
    } else {
      _loadAuthState();
    }
  }

  @override
  void didUpdateWidget(covariant MyAppI1zPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAuthenticated != null &&
        widget.isAuthenticated != oldWidget.isAuthenticated) {
      setState(() => _isAuthorized = widget.isAuthenticated);
    }
  }

  Future<void> _loadAuthState() async {
    final authorized = await _isAuthorizedUser();
    if (!mounted) return;
    setState(() => _isAuthorized = authorized);
  }

  @override
  Widget build(BuildContext context) {
    final showLoginButton = _isAuthorized != true;

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
          if (showLoginButton)
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
                if (!mounted) return;
                await _loadAuthState();
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
                  int base = 0;

                  if (title == 'Заказ спецтехники') base = 2;
                  if (title == 'Заказ грузовых перевозок') base = 1;
                  if (title == 'Заказ грузчиков') base = 3;
                  print('object567');
                  print(base);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CityScreenIsp(
                                indexName: images[index].name,
                                bd: base,
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
              imagesSection('Заказ спецтехники', catalog.vidt),
              imagesSection('Заказ грузовых перевозок', catalog.vidg),
              imagesSection('Заказ грузчиков', catalog.gruzchik),
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
