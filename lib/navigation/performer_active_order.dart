import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/navigation/performer_shell_scope.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Активная сделка исполнителя из ordersglobal (через check_order_status1).
class PerformerActiveOrder {
  final String performerId;
  final String orderId;
  final String customerUserId;
  final String? status;
  final String? startTime;

  const PerformerActiveOrder({
    required this.performerId,
    required this.orderId,
    required this.customerUserId,
    this.status,
    this.startTime,
  });

  bool get isExecuting =>
      status == null || status == '' || status == 'выполняется';
}

Future<PerformerActiveOrder?> fetchPerformerActiveOrder() async {
  try {
    final token = await getSecurefcm_token();
    if (token == null || token.isEmpty) return null;

    final userResp = await http.get(
      Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'),
    );
    if (userResp.statusCode != 200) return null;

    final userData = json.decode(userResp.body) as Map<String, dynamic>;
    final performerId = userData['idusers']?.toString() ?? '';
    if (performerId.isEmpty) return null;

    final statusResp = await http.get(
      Uri.parse(
          '${Config.apiBase}/check_order_status1.php?userIdok=$performerId'),
    );
    if (statusResp.statusCode != 200) return null;

    final status = json.decode(statusResp.body) as Map<String, dynamic>;
    if (status['result'] != true) return null;

    final orderId = status['order_id']?.toString() ?? '';
    if (orderId.isEmpty) return null;

    return PerformerActiveOrder(
      performerId: status['user_id']?.toString() ?? performerId,
      orderId: orderId,
      customerUserId: status['user_idok']?.toString() ?? '',
      status: status['status']?.toString(),
      startTime: status['start_time']?.toString(),
    );
  } catch (_) {
    return null;
  }
}

/// Профиль → «Предложения»: при выполняющемся заказе — вкладка с таймером.
Future<void> openPerformerOffersOrActiveOrder(BuildContext context) async {
  final active = await fetchPerformerActiveOrder();
  if (!context.mounted) return;

  if (active != null && active.isExecuting) {
    final shellSelectTab = PerformerShellScope.selectTabOf(context);
    if (shellSelectTab != null) {
      shellSelectTab(1);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MyAppZakazScreen(initialPage: 1),
      ),
      (route) => false,
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const zprofil_zayavki(
        nameImg: '',
        base: 1,
        showBottomNav: true,
      ),
    ),
  );
}
