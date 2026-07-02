import 'dart:async';

import 'package:flutter/material.dart';

import 'fcm_token.dart';
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
    // Разрешения и токен — только после входа (loginpage), не на splash.
    await configureFirebaseMessaging();
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
