import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
const _saPath = 'assets/service_account.json';

/* ---------- Загрузка service_account.json ---------- */

/// Читаем файл и возвращаем карту
Future<Map<String, dynamic>> _loadSaMap() async {
  final jsonString = await rootBundle.loadString(_saPath);
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

/* ---------- Получение AuthClient ---------- */

Future<AuthClient> _getAuthClient() async {
  final saMap = await _loadSaMap();
  final credentials = ServiceAccountCredentials.fromJson(saMap);
  return clientViaServiceAccount(credentials, _scopes);
}

/* ---------- Отправка сообщения ---------- */

Future<void> sendNotificationV1({
  required String deviceToken,
  required String title,
  required String body,
}) async {
  final saMap = await _loadSaMap(); // ещё раз берём карту,
  final projectId = saMap['project_id']; // или сохраните куда-нибудь

  final client = await _getAuthClient();

  final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

  final payload = {
    'message': {
      'token': deviceToken,
      'notification': {
        'title': title,
        'body': body,
      },
      'android': {
        'priority': 'high',
        'notification': {'sound': 'default'},
      },
    }
  };

  final response = await client.post(
    url,
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode(payload),
  );

  print('FCM status: ${response.statusCode}');
  print('FCM body  : ${response.body}');

  if (response.statusCode != 200) {
    throw Exception('FCM request failed');
  }

  client.close();
}
