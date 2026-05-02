import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:crgtransp72app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PerformerBottomNav extends StatefulWidget {
  final int currentIndex;

  const PerformerBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  State<PerformerBottomNav> createState() => _PerformerBottomNavState();
}

class _PerformerBottomNavState extends State<PerformerBottomNav> {
  bool _highlightOrders = false;
  String _orderId = '';
  String _orderUserId = '';

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
        Uri.parse('${Config.baseUrl}/api/getuserinfo_order.php?token=$token'),
      );
      if (userResponse.statusCode != 200) return;

      final userData = json.decode(userResponse.body);
      final userId = userData['idusers']?.toString() ?? '';
      if (userId.isEmpty) return;

      final statusResponse = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/check_order_status1.php?userIdok=$userId'),
      );
      if (statusResponse.statusCode != 200) return;

      final statusData = json.decode(statusResponse.body);
      if (!mounted) return;
      setState(() {
        _highlightOrders = statusData['result'] == true;
        _orderId = statusData['order_id']?.toString() ?? '';
        _orderUserId = statusData['user_id']?.toString() ?? '';
      });
    } catch (_) {
      // Не блокируем навигацию при ошибке сети.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.fire_truck),
          label: 'Объявления',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.subject,
            color: _highlightOrders ? Colors.red : null,
          ),
          label: 'Заявки',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Профиль',
        ),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MyAppI1z(),
            ),
          );
          return;
        }

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => _highlightOrders &&
                      _orderId.isNotEmpty &&
                      _orderUserId.isNotEmpty
                  ? OrderExecutionScreen(
                      userId: _orderUserId,
                      orderId: _orderId,
                      showBottomNav: true,
                    )
                  : SearchForm(),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HistortScreen(pageProfile: 'profileMain'),
          ),
        );
      },
    );
  }
}
