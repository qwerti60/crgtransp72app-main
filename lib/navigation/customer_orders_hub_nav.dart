import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/menuzak.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Выполняется заказ или завершён без отзыва заказчика — показываем экран-счётчик.
Future<bool> customerShouldOpenOrdersTimer() async {
  try {
    final token = await getSecurefcm_token();
    if (token == null || token.isEmpty) return false;

    final userResp = await http
        .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'))
        .timeout(const Duration(seconds: 8));
    if (userResp.statusCode != 200) return false;

    final userData = json.decode(userResp.body);
    if (userData['error'] != null || userData['idusers'] == null) return false;

    final userId = userData['idusers'].toString();
    if (userId.isEmpty) return false;

    final statusResp = await http
        .get(Uri.parse(
            '${Config.baseUrl}/api/check_order_statusisp.php?userIdok=$userId'))
        .timeout(const Duration(seconds: 8));
    if (statusResp.statusCode != 200) return false;

    final statusData = json.decode(statusResp.body);
    if (statusData['result'] != true) return false;

    return statusData['needs_review'] == true ||
        statusData['status']?.toString() == 'выполняется';
  } catch (_) {
    return false;
  }
}

void openCustomerOrdersHub(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MyApp(initialPage: 1)),
    (Route<dynamic> route) => false,
  );
}

/// «Мои объявления» или экран выполнения, если заказ ещё требует внимания.
Future<void> openCustomerMyAdsOrOrdersHub(BuildContext context) async {
  final goToTimer = await customerShouldOpenOrdersTimer();
  if (!context.mounted) return;
  if (goToTimer) {
    openCustomerOrdersHub(context);
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const MenuzakScreen(pageProfile: 'Ads2App'),
    ),
  );
}
