import 'package:crgtransp72app/pages/start_pages.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Импортируем core
import 'package:firebase_messaging/firebase_messaging.dart'; // Импортируем messaging
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(); // Инициализируем Firebase
  final fcmToken =
      await FirebaseMessaging.instance.getToken(); // Получаем токен устройства
  if (fcmToken != null) {
    print('Device Token: $fcmToken'); // Выводим токен в консоль
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Слушаем входящие уведомления
    print('Received a notification!');
    print(message.notification?.title); // Выводим заголовок уведомления
    print(message.notification?.body); // Выводим тело уведомления
  });
}

late final ServiceAccountCredentials credentials;
late final String projectId;

Future<void> initFcmSender() async {
  final jsonStr = await rootBundle.loadString('assets/service_account.json');
  final saMap = jsonDecode(jsonStr) as Map<String, dynamic>;

  credentials = ServiceAccountCredentials.fromJson(saMap);
  projectId = saMap['crgtransp72app'] as String;
}

void main() async {
  // Первая строка, обеспечивающая полную инициализацию привязки Flutter
  await WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase(); // Ждём завершения инициализации Firebase
  runApp(const MyApp()); // Стартуем приложение
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KipaRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // Стартовая страница остаётся неизменной
    );
  }
}
