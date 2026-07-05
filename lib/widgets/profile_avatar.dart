import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Декодирует фото пользователя из ответа API; пустые значения → null.
Uint8List? decodeUserPhotoFromApi(dynamic raw) {
  if (raw == null) return null;

  final value = raw.toString().trim();
  if (value.isEmpty || value.toLowerCase() == 'null') return null;

  try {
    final bytes = base64Decode(value);
    return bytes.isEmpty ? null : bytes;
  } catch (_) {
    return null;
  }
}

/// Аватар профиля: фото пользователя или стандартное изображение.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.fotouser,
    this.size = 100,
    this.onTap,
  });

  final Uint8List? fotouser;
  final double size;
  final VoidCallback? onTap;

  bool get _hasPhoto => fotouser != null && fotouser!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = _hasPhoto
        ? ClipOval(
            child: Image.memory(
              fotouser!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emptyPlaceholder(size),
            ),
          )
        : _emptyPlaceholder(size);

    final child = SizedBox(width: size, height: size, child: avatar);

    if (onTap == null) return child;

    return GestureDetector(onTap: onTap, child: child);
  }

  static Widget _emptyPlaceholder(double size) {
    return ClipOval(
      child: Image.asset(
        'assets/images/fotouser.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Colors.grey.shade300,
          child: Icon(Icons.person, size: size * 0.5, color: Colors.grey),
        ),
      ),
    );
  }
}
