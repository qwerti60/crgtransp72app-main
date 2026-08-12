import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/models/search_params.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class SearchServicesApi {
  static Future<List<dynamic>> fetch({
    required String role,
    String nameImg = '',
    String city = '',
    required int userId,
    SearchParams params = const SearchParams(),
    bool allCities = false,
  }) async {
    final queryParameters = params.toQueryParameters(
      role: role,
      nameImg: nameImg,
      city: city,
      userId: userId,
      allCities: allCities,
    );
    queryParameters['_ts'] = DateTime.now().millisecondsSinceEpoch.toString();

    final response = await http
        .get(
          Uri.parse(Config.baseUrl).replace(
            path: '${Config.apiPrefix}/search_services.php',
            queryParameters: queryParameters,
          ),
        )
        .timeout(kApiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Ошибка поиска (${response.statusCode})');
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return [];
    }
    if (!(body.startsWith('{') || body.startsWith('['))) {
      throw Exception('Некорректный ответ сервера');
    }

    final parsed = json.decode(body);
    if (parsed is List) {
      return parsed;
    }
    if (parsed is Map && parsed['error'] != null) {
      throw Exception(parsed['error'].toString());
    }
    return [];
  }

  /// Возвращает null при ошибке API (для fallback на legacy endpoint).
  static Future<List<dynamic>?> tryFetch({
    required String role,
    String nameImg = '',
    String city = '',
    required int userId,
    SearchParams params = const SearchParams(),
    bool allCities = false,
  }) async {
    try {
      return await fetch(
        role: role,
        nameImg: nameImg,
        city: city,
        userId: userId,
        params: params,
        allCities: allCities,
      );
    } catch (e) {
      debugPrint('SearchServicesApi.tryFetch: $e');
      return null;
    }
  }
}
