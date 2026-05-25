import 'dart:async';

import 'package:crgtransp72app/firebase_options.dart';
import 'package:crgtransp72app/pages/start_pages.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Не блокирует первый кадр UI — иначе ревью видит «вечную» загрузку на Launch Screen.
Future<void> _initializeFirebaseInBackground() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));

    final settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
        )
        .timeout(const Duration(seconds: 15));

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        )
        .timeout(const Duration(seconds: 5));

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('Новый FCM-токен: $newToken');
    });

    try {
      final fcmToken = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10));
      if (fcmToken != null) {
        debugPrint('Полученный FCM-токен: $fcmToken');
      }
    } catch (e) {
      debugPrint('Ошибка получения токена: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received a notification!');
      debugPrint(message.notification?.title);
      debugPrint(message.notification?.body);
    });
  } catch (e) {
    debugPrint('Firebase init skipped or failed: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  unawaited(_initializeFirebaseInBackground());
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
      home: const SplashScreen(),
    );
  }
}
