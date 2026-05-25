import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:http/http.dart' as http;

class ReferenceListResult {
  final List<dynamic>? data;
  final bool failed;

  const ReferenceListResult({this.data, this.failed = false});

  factory ReferenceListResult.failed() =>
      const ReferenceListResult(failed: true);
}

class ReferenceListsApi {
  static Future<ReferenceListResult> fetch(String path) async {
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}$path'))
          .timeout(kApiTimeout);
      if (response.statusCode == 200) {
        return ReferenceListResult(data: json.decode(response.body) as List);
      }
      return ReferenceListResult.failed();
    } catch (_) {
      return ReferenceListResult.failed();
    }
  }
}
