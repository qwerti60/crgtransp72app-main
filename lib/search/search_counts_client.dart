import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Результат `search_order_counts.php`.
class SearchCountsResult {
  final Map<String, int> cities;
  final Map<String, int> services;
  final Map<String, Map<String, int>> cityBreakdown;
  final String? coreVersion;
  final String role;

  const SearchCountsResult({
    required this.cities,
    required this.services,
    this.cityBreakdown = const {},
    this.coreVersion,
    required this.role,
  });

  List<String> servicesWithCountInCity(String? cityName) {
    if (cityName == null || cityName.isEmpty) return [];
    final breakdown = cityBreakdown[cityName.trim()];
    if (breakdown != null && breakdown.isNotEmpty) {
      return breakdown.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList();
    }
    return services.entries
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .toList();
  }
}

/// Загрузка счётчиков поиска (заказчик / исполнитель).
class SearchCountsClient {
  static Future<SearchCountsResult?> fetch({
    required int userId,
    required String role,
    String? city,
    bool breakdown = true,
  }) async {
    // useId=0 — гость; API отдаёт общие счётчики без исключения «своих»
    if (userId < 0) return null;

    final params = <String, String>{
      'role': role == 'customer' ? 'customer' : 'performer',
      'useId': userId.toString(),
    };
    if (city != null && city.trim().isNotEmpty) {
      params['city'] = city.trim();
    }
    if (breakdown && city != null && city.trim().isNotEmpty) {
      params['breakdown'] = '1';
    }

    final uri = Uri.parse('${Config.baseUrl}/api/search_order_counts.php')
        .replace(queryParameters: params);

    http.Response response;
    try {
      response = await http.get(uri).timeout(kApiTimeout);
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    if (data is! Map || data['success'] != true) return null;

    return SearchCountsResult(
      role: (data['role'] ?? role).toString(),
      coreVersion: data['core_version']?.toString(),
      cities: _parseIntMap(data['cities']),
      services: _parseIntMap(data['services']),
      cityBreakdown: _parseBreakdown(data['city_breakdown']),
    );
  }

  static Map<String, int> _parseIntMap(dynamic raw) {
    final map = <String, int>{};
    if (raw is! Map) return map;
    raw.forEach((key, value) {
      final k = key.toString().trim();
      if (k.isEmpty) return;
      map[k] = (value as num?)?.toInt() ?? 0;
    });
    return map;
  }

  static Map<String, Map<String, int>> _parseBreakdown(dynamic raw) {
    final out = <String, Map<String, int>>{};
    if (raw is! Map) return out;
    raw.forEach((cityKey, servicesRaw) {
      final city = cityKey.toString().trim();
      if (city.isEmpty || servicesRaw is! Map) return;
      out[city] = _parseIntMap(servicesRaw);
    });
    return out;
  }
}
