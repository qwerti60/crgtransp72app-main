import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

Future<bool> toggleLikeRequest({
  required int usersId,
  required Object? idusers,
  required Object? id,
  required int bd,
  bool usePerformerEndpoint = false,
}) async {
  final List<String> candidatePaths = usePerformerEndpoint
      ? ['/api/toggle_like.php', '/api/toggle_like2.php']
      : ['/api/toggle_like1.php', '/api/toggle_like.php'];

  http.Response? response;
  for (final path in candidatePaths) {
    final current = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: path,
        queryParameters: {
          'usersid': usersId.toString(),
          'idusers': (idusers ?? '').toString(),
          'id': (id ?? '').toString(),
          'bd': bd.toString(),
        },
      ),
    );
    if (current.statusCode == 200 && current.body.isNotEmpty) {
      response = current;
      break;
    }
  }

  if (response == null) return false;

  try {
    final parsed = json.decode(response.body);
    if (parsed is Map<String, dynamic>) {
      final dynamic success = parsed['success'] ?? parsed['status'];
      if (success is bool) return success;
      if (success is num) return success == 1;
      if (success is String) {
        return success == '1' ||
            success.toLowerCase() == 'true' ||
            success.toLowerCase() == 'success';
      }
    }
    return false;
  } catch (_) {
    return false;
  }
}
