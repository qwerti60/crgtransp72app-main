import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getSecurefcm_token() async {
  final prefs = await SharedPreferences.getInstance();
  final fcmToken = prefs.getString('fcm_token');
  return fcmToken;
}
