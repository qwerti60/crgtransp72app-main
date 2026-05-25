import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:http/http.dart' as http;

class CitiesFetchResult {
  final List<dynamic>? data;
  final bool failed;

  const CitiesFetchResult({this.data, this.failed = false});

  factory CitiesFetchResult.failed() => const CitiesFetchResult(failed: true);
}

class CitiesApi {
  static Future<CitiesFetchResult> fetchAll() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/cities.php'))
          .timeout(kApiTimeout);

      if (response.statusCode == 200) {
        return CitiesFetchResult(data: json.decode(response.body) as List);
      }
      return CitiesFetchResult.failed();
    } catch (_) {
      return CitiesFetchResult.failed();
    }
  }
}
