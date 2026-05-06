import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/loginpage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showDeleteAccountDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Удалить аккаунт'),
        content: const Text(
          'Аккаунт и связанные персональные данные будут удалены без возможности восстановления.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final fcmToken = await getSecurefcm_token();
  if (fcmToken == null || fcmToken.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось определить аккаунт')),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse(Config.baseUrl).replace(path: '/api/delete_account.php'),
      body: {'fcm_token': fcmToken},
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );
    final result = jsonDecode(response.body);

    if (response.statusCode == 200 && result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_token');
      await prefs.remove('789456123');

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт удален')),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(result['message'] ?? 'Не удалось удалить аккаунт')),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка удаления аккаунта: $e')),
    );
  }
}
