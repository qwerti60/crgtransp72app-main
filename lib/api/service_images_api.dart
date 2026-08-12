import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Элемент каталога услуг (vidt / vidg / gruzchik).
class ServiceImageItem {
  final int id;
  final String name;
  final String imageUrl;
  final String? imageBase64;

  const ServiceImageItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.imageBase64,
  });

  factory ServiceImageItem.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['image_url'];
    return ServiceImageItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: '${json['name'] ?? ''}',
      imageUrl: rawUrl is String ? rawUrl : '',
      imageBase64: json['image'] is String ? json['image'] as String : null,
    );
  }
}

class ServiceImagesBundle {
  final List<ServiceImageItem> vidt;
  final List<ServiceImageItem> vidg;
  final List<ServiceImageItem> gruzchik;

  const ServiceImagesBundle({
    required this.vidt,
    required this.vidg,
    required this.gruzchik,
  });

  factory ServiceImagesBundle.fromJson(Map<String, dynamic> json) {
    List<ServiceImageItem> parseList(Object? raw) {
      if (raw is! List) {
        return const [];
      }
      return raw
          .whereType<Map>()
          .map((row) => ServiceImageItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    }

    return ServiceImagesBundle(
      vidt: parseList(json['vidt']),
      vidg: parseList(json['vidg']),
      gruzchik: parseList(json['gruzchik']),
    );
  }
}

class ServiceImagesApi {
  static Future<List<ServiceImageItem>> fetch(String table) async {
    final uri = Uri.parse('${Config.apiBase}/getimage.php').replace(
      queryParameters: {
        'bd': table,
        'w': '480',
      },
    );
    final response = await http.get(uri).timeout(kApiTimeout);
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить услуги ($table)');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Неверный ответ сервера');
    }

    return decoded
        .whereType<Map>()
        .map((row) => ServiceImageItem.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Один запрос: спецтехника (vidt), перевозки (vidg), грузчики (gruzchik).
  static Future<ServiceImagesBundle> fetchAll() async {
    final uri = Uri.parse('${Config.apiBase}/getimage.php').replace(
      queryParameters: {
        'bd': 'all',
        'w': '480',
      },
    );
    final response = await http.get(uri).timeout(kApiTimeout);
    if (response.statusCode != 200) {
      throw Exception('Не удалось загрузить каталог услуг');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map) {
      throw Exception('Неверный ответ сервера');
    }

    return ServiceImagesBundle.fromJson(Map<String, dynamic>.from(decoded));
  }
}

/// Превью услуги: по URL (лёгкий JSON) или fallback base64 для старого API.
class ServiceImagePreview extends StatelessWidget {
  final ServiceImageItem item;
  final BoxFit fit;

  const ServiceImagePreview({
    super.key,
    required this.item,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl.isNotEmpty) {
      return Image.network(
        item.imageUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image_outlined, size: 40);
        },
      );
    }

    final base64 = item.imageBase64;
    if (base64 != null && base64.isNotEmpty) {
      return Image.memory(
        base64Decode(base64),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image_outlined, size: 40);
        },
      );
    }

    return const Icon(Icons.image_not_supported_outlined, size: 40);
  }
}
