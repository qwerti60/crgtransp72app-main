import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/OrderExecutionScreenzak.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CustomerBottomNav extends StatefulWidget {
  final int currentIndex;

  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  bool _highlightOrders = false;
  String _activeOrderUserId = '';
  String _activeOrderId = '';
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _loadOrderHighlight();
  }

  Future<void> _loadOrderHighlight() async {
    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) return;

      final userResponse = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'),
      );
      if (userResponse.statusCode != 200) return;

      final userData = json.decode(userResponse.body);
      if (userData['error'] != null || userData['idusers'] == null) return;

      final userId = userData['idusers'].toString();
      if (userId.isEmpty) return;

      final statusResponse = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/check_order_statusisp.php?userIdok=$userId'),
      );
      if (statusResponse.statusCode != 200) return;

      final statusData = json.decode(statusResponse.body);
      if (!mounted) return;
      setState(() {
        _isAuthorized = true;
        _highlightOrders = statusData['result'] == true;
        _activeOrderUserId = statusData['user_id']?.toString() ?? '';
        _activeOrderId = statusData['order_id']?.toString() ?? '';
      });
    } catch (_) {
      // Не блокируем нижнее меню при ошибке сети.
    }
  }

  @override
  Widget build(BuildContext context) {
    final navLabels =
        CustomerShellNav.bottomNavLabels(isAuthenticated: _isAuthorized);
    final items = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: const Icon(Icons.fire_truck),
        label: navLabels[0],
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.subject,
          color: _highlightOrders ? Colors.red : null,
        ),
        label: navLabels[1],
      ),
      if (navLabels.length > 2)
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_circle),
          label: navLabels[2],
        ),
    ];
    final safeIndex =
        widget.currentIndex < items.length ? widget.currentIndex : 0;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: const IconThemeData(color: violetColor),
      items: items,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MyApp()),
            (Route<dynamic> route) => false,
          );
          return;
        }

        if (index == 1 &&
            _highlightOrders &&
            _activeOrderUserId.isNotEmpty &&
            _activeOrderId.isNotEmpty) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => OrderExecutionScreenzak(
                userId: _activeOrderUserId,
                orderId: _activeOrderId,
              ),
            ),
            (Route<dynamic> route) => false,
          );
          return;
        }

        if (!_isAuthorized) {
          return;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MyApp(initialPage: index),
          ),
          (Route<dynamic> route) => false,
        );
      },
    );
  }
}
