import 'dart:convert';
import 'package:crgtransp72app/config.dart';
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
