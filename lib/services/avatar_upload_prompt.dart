import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/services/avatar_image_upload.dart';
import 'package:crgtransp72app/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// После входа: если аватара нет — предложить загрузить или отложить.
Future<void> maybePromptAvatarUploadAfterLogin(
  BuildContext context, {
  required bool isPerformer,
}) async {
  final profile = await _loadProfileSnapshot(isPerformer: isPerformer);
  if (profile == null || profile.hasAvatar || !context.mounted) return;

  final shouldAddPhoto = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Добавьте фото профиля'),
        content: const Text(
          'Профиль с фотографией вызывает больше доверия у заказчиков '
          'и исполнителей. Вы можете загрузить фото сейчас или сделать '
          'это позже в разделе «Профиль» → «Личные данные».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Сделать позже'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Добавить фото'),
          ),
        ],
      );
    },
  );

  if (shouldAddPhoto != true || !context.mounted) return;

  await _runAvatarUploadFlow(context, email: profile.email);
}

class _ProfileSnapshot {
  _ProfileSnapshot({required this.hasAvatar, required this.email});

  final bool hasAvatar;
  final String email;
}

Future<_ProfileSnapshot?> _loadProfileSnapshot({
  required bool isPerformer,
}) async {
  final token = await getSecurefcm_token();
  if (token == null || token.isEmpty) return null;

  final apiPath = isPerformer
      ? '/api/getuserinfo_order.php'
      : '/api/getuserinfo.php';

  try {
    final response = await http.get(
      Uri.parse('${Config.baseUrl}$apiPath?token=$token'),
    );
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data is! Map || data['error'] != null) return null;

    final photo = decodeUserPhotoFromApi(data['fotouser']);
    final email = data['email']?.toString().trim() ?? '';

    return _ProfileSnapshot(
      hasAvatar: photo != null && photo.isNotEmpty,
      email: email,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _runAvatarUploadFlow(
  BuildContext context, {
  required String email,
}) async {
  if (email.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось определить e-mail профиля')),
    );
    return;
  }

  final result = await AvatarImageUpload.runPickPreviewUploadFlow(
    context,
    email: email,
  );

  if (!context.mounted || result == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result ? 'Загрузка успешна!' : 'Ошибка при загрузке изображения',
      ),
    ),
  );
}
