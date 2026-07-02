import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:http/http.dart' as http;

/// Статус заявки заказчика на объявление исполнителя (offer_dataf + ordersglobal).
class ZakazAdDealInfo {
  final bool hasOffer;
  final String orderStatus;

  const ZakazAdDealInfo({
    required this.hasOffer,
    this.orderStatus = '',
  });

  bool get isExecuting => orderStatus == 'выполняется';
  bool get isCompleted => orderStatus == 'выполнен';
  bool get isCancelled => orderStatus == 'отменен';
  bool get canDeleteEdit => hasOffer && !isExecuting && !isCompleted;
  bool get canSubmitNew => !hasOffer || isCompleted || isCancelled;
}

Future<ZakazAdDealInfo> fetchZakazAdDeal({
  required int customerId,
  required int adId,
  required int bd,
  required int performerId,
}) async {
  final uri = Uri.parse('${Config.baseUrl}/api/check_offer_zakaz.php').replace(
    queryParameters: {
      'iduser': customerId.toString(),
      'truck': adId.toString(),
      'bd': bd.toString(),
      'performer_id': performerId.toString(),
    },
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load offer status');
  }
  final data = json.decode(response.body) as Map<String, dynamic>;
  return ZakazAdDealInfo(
    hasOffer: data['exists'] == true,
    orderStatus: (data['order_status'] ?? '').toString(),
  );
}
