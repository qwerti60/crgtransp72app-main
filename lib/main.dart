import 'dart:async';

import 'package:crgtransp72app/firebase_options.dart';
import 'package:crgtransp72app/push_notifications.dart';
import 'package:crgtransp72app/design/app_theme.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/start_pages.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _initializeFirebaseMessaging() async {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await configureFirebaseMessaging();
    await initPushNotifications();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint('Firebase Messaging setup: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    unawaited(_initializeFirebaseMessaging());
  } catch (e) {
    debugPrint('Firebase init: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(clearAppIconBadge());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(clearAppIconBadge());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KipaRO',
      debugShowCheckedModeBanner: false,
      theme: crgAppTheme(),
      home: const SplashScreen(),
    );
  }
}
