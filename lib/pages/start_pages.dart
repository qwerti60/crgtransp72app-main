import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/loginpage.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Импортируем библиотеку Firebase Messaging

import 'package:http/http.dart' as http;
import 'change_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? fcmToken; // Переменная для хранения FCM-токена

  @override
  void initState() {
    super.initState();
    _requestFCMPermissionsAndGetToken(); // Запрашиваем разрешение и получаем токен
    _startTimer();
  }

  Future<void> _requestFCMPermissionsAndGetToken() async {
    try {
      await FirebaseMessaging.instance
          .requestPermission(); // Диалог разрешения уведомления
      fcmToken = await FirebaseMessaging.instance
          .getToken(); // Получение самого токена

      final prefs = await SharedPreferences.getInstance();
      prefs.setString(
          'fcm_token', fcmToken ?? ''); // Сохраняем токен в настройках
      print("Полученный FCM-токен: $fcmToken");
    } catch (e) {
      print("Ошибка при получении FCM-токена: $e");
    }
  }

  Future<void> _startTimer() async {
    final token = await getSecurefcm_token(); // Await the secure token
    Timer(const Duration(seconds: 5), () {
      print('token');
      print(token);

      if (token == null) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const change_user()));
      }
    });
  }

  Future<String?> getSecurefcm_token() async {
    final prefs = await SharedPreferences.getInstance();
    final fcmToken =
        prefs.getString('fcm_token'); // Берём токен FCM из настроек

    if (fcmToken == null) {
      return null; // Если токен не найден, возвращаем null
    }

    try {
      var response = await http.post(
        Uri.parse(Config.baseUrl).replace(path: '/api/check_fcm_token.php'),
        // final response = await http.post(
        // Uri.parse('YOUR_API_URL/check_fcm_token.php'), // Адрес вашего API
        body: {
          'fcm_token': fcmToken,
        },
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['exists'] == true) {
          return fcmToken; // Возвращаем токен, если он есть в базе данных
        } else {
          return null; // Иначе возвращаем null
        }
      } else {
        print('Ошибка при обращении к API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка при взаимодействии с API: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo.png', // путь к изображению
          width: 189, // ширина изображения
          height: 119, // высота изображения
        ),
      ),
    );
  }
}
