import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../design/colors.dart';
import '../design/dimension.dart';
import 'subscription_screen.dart';
import 'package:http/http.dart' as http;

import 'zakaz_screen2.dart';

Future<bool?> checkSubscription(int userId) async {
  final response = await http.post(
    Uri.parse(
        '${Config.baseUrl}/api/check_subscription.php?iduser=$userId'), // Adding userId as a query parameter
    // Note: Since you are sending the userId in the URL, you do not need to include it in the body again
  );
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen()));
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
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'));

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
                    navigateIfNeeded(context,
                        userId); // предполагается, что userId уже объявлен и доступен
                  },
                  child: const Text('Я исполнитель'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
