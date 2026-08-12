import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crgtransp72app/services/chat_push_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String kPushChannelId = 'crg_high_importance';
const String kPushChannelName = 'Уведомления CRG';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

bool _localNotificationsReady = false;

Future<void> initPushNotifications() async {
  if (_localNotificationsReady) {
    return;
  }

  const androidInit = AndroidInitializationSettings('@drawable/icon');
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );
  await _localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      unawaited(clearAppIconBadge());
      ChatPushHandler.handlePayloadJson(response.payload);
    },
  );

  if (Platform.isAndroid) {
    const channel = AndroidNotificationChannel(
      kPushChannelId,
      kPushChannelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  FirebaseMessaging.onMessageOpenedApp.listen((_) {
    unawaited(clearAppIconBadge());
  });
  _localNotificationsReady = true;

  // Сбрасываем кружок на иконке, если приложение уже открыто.
  await clearAppIconBadge();
}

/// Сброс бейджа на иконке (Android: очистка шторки; iOS: ещё и AppDelegate).
/// Вызывать при открытии/возврате в приложение и после тапа по push.
Future<void> clearAppIconBadge() async {
  try {
    if (!_localNotificationsReady) {
      return;
    }
    await _localNotifications.cancelAll();
    // iOS: бейдж ещё сбрасывается в AppDelegate.applicationDidBecomeActive.
    // Не показываем «пустой» notification — на части устройств это даёт сбой.
  } catch (e) {
    debugPrint('clearAppIconBadge: $e');
  }
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) {
    return;
  }

  final id = message.messageId?.hashCode ??
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  final payload = message.data.isNotEmpty ? json.encode(message.data) : null;

  await _localNotifications.show(
    id,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        kPushChannelId,
        kPushChannelName,
        channelDescription: 'Сообщения от CRG Transp72',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/icon',
        tag: message.messageId,
        number: 0,
      ),
      // В открытом приложении не копим бейдж на иконке — только баннер.
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    ),
    payload: payload,
  );

  debugPrint('FCM foreground shown: ${notification.title}');
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}
