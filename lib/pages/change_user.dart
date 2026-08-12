import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/PaymentPage.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../design/colors.dart';
import '../design/dimension.dart';
import 'subscription_screen.dart';
import 'package:http/http.dart' as http;

import 'loginpage.dart';
import 'changestatis_page.dart';
import 'zakaz_screen2.dart';

Future<bool?> checkSubscription(int userId) async {
  final response = await http
      .post(
        Uri.parse(
            '${Config.apiBase}/check_subscription.php?iduser=$userId'),
      )
      .timeout(const Duration(seconds: 8));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data['status']);
    if (data['status'] == 'active') {
      return true;
    } else if (data['status'] == 'expired' || data['status'] == 'not_found') {
      return false;
    }
  }
  return null; // It might be good to return null or handle errors if the response status code isn't 200, indicating an issue with the request
}

void navigateIfNeeded(BuildContext context, int userId) async {
  final subscriptionStatus = await checkSubscription(userId);
  if (!context.mounted) return;

  if (subscriptionStatus == true) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyAppZakazScreen()),
      (Route<dynamic> route) => false,
    );
    //  Navigator.push(
    //    context, MaterialPageRoute(builder: (_) => const MyAppZakazScreen()));
  } else if (subscriptionStatus == false) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Подписка"),
          content: const Text(
              "Ваша подписка неактивна. Оформите подписку для доступа."),
          actions: [
            TextButton(
              child: const Text("Оформить"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaymentScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  // Здесь может быть ваша логика перехода на экран оформления/продления подписки
}

int userId = 0;

class change_user extends StatefulWidget {
  const change_user({super.key});

  @override

  // ignore: library_private_types_in_public_api

  change_userForm createState() => change_userForm();
}

class change_userForm extends State<change_user> {
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final token = await getSecurefcm_token();
    final authorized = token != null && token.isNotEmpty;

    if (!mounted) return;
    setState(() => _isAuthorized = authorized);

    if (authorized) {
      await getUserData();
    }
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          userId = data['idusers'];
        });

        // Теперь переменные firstName, lastName, middleName, и userfoto доступны для использования в build() методе.
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Выбор роли',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50.0),
            Image.asset(
              'assets/images/logo.png', // путь к изображению
              width: 189, // ширина изображения
              height: 119, // высота изображения
            ),
            const Text('Выбор роли',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: blackprColor,
                  fontSize: fontSize30,
                )),
            if (!_isAuthorized) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Text(
                  'Просмотр услуг и объявлений не требует регистрации. Вход нужен только для размещения заказов и личного кабинета.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                margin: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      fixedSize: const Size(double.infinity, 50),
                      foregroundColor: blueaccentColor,
                      side: const BorderSide(color: blueaccentColor),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MyApp()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text('Смотреть без регистрации'),
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    fixedSize: const Size(double.infinity, 50),
                    foregroundColor: whiteprColor,
                    backgroundColor: blueaccentColor,
                    disabledForegroundColor: grayprprColor,
                    shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3))),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => MyApp()),
                      (Route<dynamic> route) => false,
                    );
                    //                  Navigator.push(context,
                    //                    MaterialPageRoute(builder: (_) => const MyApp()));
                  },
                  child: const Text('Я заказчик'),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 30.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    fixedSize: const Size(double.infinity, 50),
                    foregroundColor: whiteprColor,
                    backgroundColor: blueaccentColor,
                    disabledForegroundColor: grayprprColor,
                    shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3))),
                  ),
                  onPressed: () {
                    if (userId > 0) {
                      navigateIfNeeded(context, userId);
                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => MyAppZakazScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Я грузоперевозчик'),
                ),
              ),
            ),
            if (!_isAuthorized)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                margin: const EdgeInsets.only(top: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text('Войти'),
                    ),
                    const Text(' | ', style: TextStyle(color: Colors.black38)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const chagestatus(data: 1),
                          ),
                        );
                      },
                      child: const Text('Регистрация'),
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
