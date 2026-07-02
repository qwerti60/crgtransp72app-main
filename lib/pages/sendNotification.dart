import 'dart:convert';
import 'package:crgtransp72app/config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<void> sendNotificationV1({
  required String deviceToken,
  required String title,
  required String body,
}) async {
  final response = await http.post(
    Uri.parse(Config.baseUrl).replace(path: '/api/send_notification.php'),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode({
      'device_token': deviceToken,
      'title': title,
      'body': body,
    }),
  );

  print('FCM status: ${response.statusCode}');
  print('FCM body  : ${response.body}');

  final data = jsonDecode(response.body);
  if (response.statusCode != 200 || data['success'] != true) {
    throw Exception('FCM request failed');
  }
}

/// Получить FCM-токен пользователя через notification.php и отправить push.
/// Ошибки не пробрасываются — уведомление не должно блокировать основной сценарий.
Future<void> notifyUserById({
  required String userId,
  required String title,
  required String body,
}) async {
  final trimmedId = userId.trim();
  if (trimmedId.isEmpty || trimmedId == '0') return;

  try {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/notification.php'),
      body: {'iduserp': trimmedId},
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    if (response.statusCode != 200) {
      debugPrint('notifyUserById: HTTP ${response.statusCode}');
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['fcm_token']?.toString();
    if (token == null || token.isEmpty) {
      debugPrint('notifyUserById: token not found for user $trimmedId');
      return;
    }

    await sendNotificationV1(
      deviceToken: token,
      title: title,
      body: body,
    );
    debugPrint('notifyUserById: sent to user $trimmedId');
  } catch (e) {
    debugPrint('notifyUserById: $e');
  }
}

const String kDefaultPushTitle = 'crgtransp72app';
