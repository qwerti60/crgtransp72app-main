import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zakaz_screen1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_requestFCMPermissionsAndGetToken());
    unawaited(_navigateToHome());
  }

  Future<void> _requestFCMPermissionsAndGetToken() async {
    try {
      await FirebaseMessaging.instance
          .requestPermission()
          .timeout(const Duration(seconds: 15));
      final fcmToken = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 10));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken ?? '');
      debugPrint('Полученный FCM-токен: $fcmToken');
    } catch (e) {
      debugPrint('Ошибка при получении FCM-токена: $e');
    }
  }

  Future<void> _navigateToHome() async {
    // Не ждём check_fcm_token.php — без таймаута splash мог не закрываться.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Каталог услуг без регистрации (Guideline 5.1.1) — не экран входа.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MyApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 189,
          height: 119,
        ),
      ),
    );
  }
}
