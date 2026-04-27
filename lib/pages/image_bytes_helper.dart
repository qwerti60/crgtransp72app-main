import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';

Uint8List? hexToBytes(String hex) {
  String normalized = hex.trim();
  if (normalized.startsWith('0x') || normalized.startsWith('0X')) {
    normalized = normalized.substring(2);
  }
  if (normalized.startsWith(r'\x')) {
    normalized = normalized.substring(2);
  }
  if (normalized.isEmpty || normalized.length.isOdd) return null;

  final RegExp onlyHex = RegExp(r'^[0-9a-fA-F]+$');
  if (!onlyHex.hasMatch(normalized)) return null;

  final bytes = <int>[];
  for (int i = 0; i < normalized.length; i += 2) {
    bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
  }
  return Uint8List.fromList(bytes);
}

Future<Uint8List?> resolveImageBytes(dynamic raw) async {
  if (raw == null) return null;

  if (raw is List) {
    try {
      return Uint8List.fromList(raw.cast<int>());
    } catch (_) {}
  }

  final String value = raw.toString().trim();
  if (value.isEmpty || value.toLowerCase() == 'null') return null;

  try {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final response = await http.get(Uri.parse(value));
      if (response.statusCode == 200) return response.bodyBytes;
      return null;
    }

    if (value.startsWith('data:')) {
      final int commaIndex = value.indexOf(',');
      if (commaIndex != -1) {
        final String dataPart = value.substring(commaIndex + 1);
        return base64Decode(dataPart);
      }
    }

    final bool looksLikeRelativeImagePath = value.contains('/') &&
        (value.endsWith('.jpg') ||
            value.endsWith('.jpeg') ||
            value.endsWith('.png') ||
            value.endsWith('.webp') ||
            value.endsWith('.heic'));
    if (looksLikeRelativeImagePath) {
      final String base = Config.baseUrl.replaceAll(RegExp(r'/$'), '');
      final String path = value.replaceFirst(RegExp(r'^/'), '');
      final response = await http.get(Uri.parse('$base/$path'));
      if (response.statusCode == 200) return response.bodyBytes;
    }

    final Uint8List? hexBytes = hexToBytes(value);
    if (hexBytes != null && hexBytes.isNotEmpty) return hexBytes;

    String normalized =
        value.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
    final int mod4 = normalized.length % 4;
    if (mod4 != 0) {
      normalized = normalized.padRight(normalized.length + (4 - mod4), '=');
    }
    return base64Decode(normalized);
  } catch (_) {
    return null;
  }
}

