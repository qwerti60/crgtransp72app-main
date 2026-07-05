import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class OfferCheckResult {
  const OfferCheckResult({
    required this.exists,
    required this.editable,
    required this.refused,
    required this.status,
  });

  final bool exists;
  final bool editable;
  final bool refused;
  final int? status;

  factory OfferCheckResult.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'];
    final int? status = statusRaw == null
        ? null
        : int.tryParse(statusRaw.toString());

    return OfferCheckResult(
      exists: json['exists'] == true,
      editable: json['editable'] == true,
      refused: json['refused'] == true,
      status: status,
    );
  }

  static const empty = OfferCheckResult(
    exists: false,
    editable: false,
    refused: false,
    status: null,
  );
}

Future<OfferCheckResult> fetchOfferCheckState({
  required int performerUserId,
  required int orderId,
  required int bd,
}) async {
  final response = await http.get(
    Uri.parse(
      '${Config.baseUrl}/api/check_offer.php?iduser=$performerUserId&truck=$orderId&bd=$bd',
    ),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to load offer state');
  }

  final decoded = json.decode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return OfferCheckResult.empty;
  }
  return OfferCheckResult.fromJson(decoded);
}

bool offerRefusedFromMap(Map truck) {
  final raw = truck['offer_status'] ?? truck['status'];
  return int.tryParse(raw?.toString() ?? '') == 2;
}
