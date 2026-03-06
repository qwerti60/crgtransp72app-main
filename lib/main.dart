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
  //final fcmToken

  // Запрашиваем разрешения на отправку уведомлений (особенно важно для iOS)
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    // Пользователь отказал в разрешении – возвращаемся без дальнейших действий
    return;
  }

  // Подписываемся на получение нового токена (рекомендуемый способ)
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('Новый FCM-токен: $newToken');
  });

  // Пробуем сразу получить токен, используя await (для немедленного вывода токена)
  try {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      debugPrint('Полученный FCM-токен: $fcmToken');
    }
  } catch (e) {
    debugPrint('Ошибка получения токена: $e');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Слушаем входящие уведомления
    print('Received a notification!');
    print(message.notification?.title); // Выводим заголовок уведомления
    print(message.notification?.body); // Выводим тело уведомления
  });
}

Future<void> initPush() async {
  await Firebase
      .initializeApp(); // Инициализация Firebase должна произойти первой

  // Запрашиваем разрешения на отправку уведомлений (особенно важно для iOS)
  NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    // Пользователь отказал в разрешении – возвращаемся без дальнейших действий
    return;
  }

  // Подписываемся на получение нового токена (рекомендуемый способ)
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    debugPrint('Новый FCM-токен: $newToken');
  });

  // Пробуем сразу получить токен, используя await (для немедленного вывода токена)
  try {
    String? currentToken = await FirebaseMessaging.instance.getToken();
    if (currentToken != null) {
      debugPrint('Полученный FCM-токен: $currentToken');
    }
  } catch (e) {
    debugPrint('Ошибка получения токена: $e');
  }

  // Обработчик входящих сообщений
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Получено уведомление:');
    debugPrint(
        'Заголовок: ${message.notification?.title}, Сообщение: ${message.notification?.body}');
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
