import 'package:shared_preferences/shared_preferences.dart';

const String _authTokenKey = '789456123';
const String _pushFcmTokenKey = 'fcm_token';

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
}

Future<void> clearAuthToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_authTokenKey);
}
