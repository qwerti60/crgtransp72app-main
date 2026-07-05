import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/last_app_role.dart';
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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final role = await loadLastAppRole();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => buildMainShellHome(role: role, initialPage: 0),
      ),
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
