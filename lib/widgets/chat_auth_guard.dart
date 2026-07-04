import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/loginpage.dart';
import 'package:flutter/material.dart';

/// Проверяет JWT-сессию; при отсутствии показывает диалог и предлагает войти.
Future<bool> ensureChatAuthorized(BuildContext context) async {
  final token = await getSecurefcm_token();
  if (token != null && token.isNotEmpty) {
    return true;
  }

  if (!context.mounted) return false;

  final goLogin = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Требуется авторизация'),
        content: const Text(
          'Написать сообщение могут только авторизованные пользователи.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Войти'),
          ),
        ],
      );
    },
  );

  if (goLogin == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    final after = await getSecurefcm_token();
    return after != null && after.isNotEmpty;
  }

  return false;
}
