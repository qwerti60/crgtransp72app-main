import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Заказчик — каталог «Услуги»; исполнитель — «Объявления».
enum AppRole {
  customer,
  performer,
}

const String _prefsKey = 'last_app_role_v1';

Future<void> saveLastAppRole(AppRole role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _prefsKey,
    role == AppRole.performer ? 'performer' : 'customer',
  );
}

Future<AppRole> loadLastAppRole() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(_prefsKey);
  if (value == 'performer') {
    return AppRole.performer;
  }
  return AppRole.customer;
}

/// Главный экран после splash: вкладка 0 — услуги или объявления.
Widget buildMainShellHome({
  required AppRole role,
  int initialPage = 0,
}) {
  if (role == AppRole.performer) {
    return MyAppZakazScreen(initialPage: initialPage);
  }
  return MyApp(initialPage: initialPage);
}

/// Переход на главный shell с запоминанием роли.
void openMainShell(
  BuildContext context, {
  required AppRole role,
  int initialPage = 0,
}) {
  saveLastAppRole(role);
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute<void>(
      builder: (_) => buildMainShellHome(role: role, initialPage: initialPage),
    ),
    (_) => false,
  );
}
