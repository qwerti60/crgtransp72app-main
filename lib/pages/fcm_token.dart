import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crgtransp72app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crgtransp72app/services/chat_push_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../navigation/shell_nav_auth_cache.dart';

const String _authTokenKey = '789456123';
const String _pushFcmTokenKey = 'fcm_token';
const String _firebaseAppIdKey = 'firebase_app_id';

bool _messagingConfigured = false;

/// JWT сессии после успешного входа.
Future<String?> getSecurefcm_token() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_authTokenKey);
  if (token == null || token.isEmpty) return null;
  return token;
}

/// FCM push-токен Firebase (уведомления, не сессия).
Future<String?> getPushFcmToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_pushFcmTokenKey);
  if (token == null || token.isEmpty) return null;
  return token;
}

Future<void> saveAuthToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_authTokenKey, token);
  CustomerShellNavCache.clear();
  PerformerShellNavCache.clear();
}

Future<void> clearAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_authTokenKey);
  CustomerShellNavCache.clear();
  PerformerShellNavCache.clear();
}

Future<void> clearPushFcmTokenLocal() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_pushFcmTokenKey);
}

Future<void> configureFirebaseMessaging() async {
  if (_messagingConfigured) return;

  ChatPushHandler.install();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM onTokenRefresh: ${newToken.substring(0, 16)}…');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pushFcmTokenKey, newToken);
    final auth = await getSecurefcm_token();
    if (auth != null && auth.isNotEmpty) {
      unawaited(syncPushFcmTokenToServer(pushToken: newToken));
    }
  });

  _messagingConfigured = true;
}

Future<void> _ensureFirebaseReady() async {
  final expectedAppId = DefaultFirebaseOptions.currentPlatform.appId;
  final prefs = await SharedPreferences.getInstance();
  final storedAppId = prefs.getString(_firebaseAppIdKey);

  if (storedAppId != null && storedAppId != expectedAppId) {
    await clearPushFcmTokenLocal();
  }
  await prefs.setString(_firebaseAppIdKey, expectedAppId);

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await configureFirebaseMessaging();
  // Дать Firebase Installations завершить check-in перед Messaging API.
  await Future<void>.delayed(const Duration(seconds: 2));
}

Future<bool> _waitForApnsTokenIfNeeded() async {
  if (!Platform.isIOS) return true;

  for (var attempt = 0; attempt < 40; attempt++) {
    final apns = await FirebaseMessaging.instance.getAPNSToken();
    if (apns != null && apns.isNotEmpty) {
      debugPrint('APNs получен (${apns.length} байт)');
      return true;
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }
  debugPrint('APNs не получен за 20 с');
  return false;
}

/// Получает актуальный FCM-токен из Firebase.
Future<String?> ensurePushFcmToken({
  bool requestPermission = false,
  bool forceRefresh = false,
}) async {
  try {
    await _ensureFirebaseReady();

    if (requestPermission) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          debugPrint('ensurePushFcmToken: уведомления запрещены');
          return null;
        }
      } catch (e) {
        debugPrint('ensurePushFcmToken requestPermission: $e');
      }
    } else if (Platform.isAndroid) {
      try {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        debugPrint('ensurePushFcmToken Android permission: $e');
      }
    }

    if (forceRefresh) {
      await clearPushFcmTokenLocal();
      try {
        await FirebaseMessaging.instance.deleteToken();
        await Future<void>.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('ensurePushFcmToken deleteToken (игнор): $e');
      }
    }

    await _waitForApnsTokenIfNeeded();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pushFcmTokenKey, token);
      debugPrint('ensurePushFcmToken: ${token.substring(0, 16)}… len=${token.length}');
      return token;
    }
  } catch (e) {
    debugPrint('ensurePushFcmToken: $e');
  }

  if (forceRefresh) {
    return null;
  }

  return getPushFcmToken();
}

/// Сохраняет FCM push-токен на сервере для рассылок и уведомлений.
Future<bool> syncPushFcmTokenToServer({
  String? pushToken,
  bool requestPermission = false,
  bool forceRefresh = false,
}) async {
  final authToken = await getSecurefcm_token();
  if (authToken == null || authToken.isEmpty) {
    debugPrint('syncPushFcmTokenToServer: нет JWT сессии');
    return false;
  }

  final fcm = pushToken ??
      await ensurePushFcmToken(
        requestPermission: requestPermission,
        forceRefresh: forceRefresh,
      );
  if (fcm == null || fcm.isEmpty) {
    debugPrint('syncPushFcmTokenToServer: нет FCM-токена на устройстве');
    return false;
  }

  try {
    final response = await http
        .post(
          Uri.parse('${Config.baseUrl}/api/update_fcm_token.php'),
          body: {
            'token': authToken,
            'fcm_token': fcm,
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      debugPrint('syncPushFcmTokenToServer HTTP ${response.statusCode}: ${response.body}');
      return false;
    }

    final data = json.decode(response.body);
    final ok = data is Map && data['success'] == true;
    if (!ok) {
      debugPrint('syncPushFcmTokenToServer: ${data['message'] ?? response.body}');
    } else {
      debugPrint('syncPushFcmTokenToServer: OK user=${data['user_id']}');
    }
    return ok;
  } catch (e) {
    debugPrint('syncPushFcmTokenToServer: $e');
    return false;
  }
}

/// После входа: ждём APNs и сохраняем токен на сервере.
Future<bool> syncPushFcmTokenAfterLogin() async {
  await Future.delayed(const Duration(seconds: 3));
  for (var attempt = 0; attempt < 5; attempt++) {
    if (attempt > 0) {
      await Future.delayed(const Duration(seconds: 5));
    }
    final synced = await syncPushFcmTokenToServer(
      requestPermission: attempt == 0,
      forceRefresh: false,
    );
    if (synced) {
      return true;
    }
  }
  return false;
}
