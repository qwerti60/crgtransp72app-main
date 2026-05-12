import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
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
  bool _isAuthorized = false;
  bool _isLoadingAuth = true;

  @override
  void initState() {
    super.initState();
    _loadOrderHighlight();
  }

  Future<void> _loadOrderHighlight() async {
    var isAuthorized = false;
    var highlightOrders = false;

    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) return;

      // Тот же источник, что и MyCustomScreen (zakaz_screen2) — иначе после «Услуги» → CityScreen
      // нижнее меню без «Профиля», хотя пользователь уже вошёл.
      final userResponse = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'),
      );
      if (userResponse.statusCode != 200) return;

      final userData = json.decode(userResponse.body);
      if (userData['error'] != null || userData['idusers'] == null) return;

      final userId = userData['idusers'].toString();
      if (userId.isEmpty) return;
      isAuthorized = true;

      final statusResponse = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/check_order_status1.php?userIdok=$userId'),
      );
      if (statusResponse.statusCode != 200) return;

      final statusData = json.decode(statusResponse.body);
      highlightOrders = statusData['result'] == true;
    } catch (_) {
      // Не блокируем навигацию при ошибке сети.
    } finally {
      if (!mounted) return;
      setState(() {
        _isAuthorized = isAuthorized;
        _highlightOrders = highlightOrders;
        _isLoadingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth) {
      return const SizedBox(height: kBottomNavigationBarHeight);
    }

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
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
      if (_isAuthorized)
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Профиль',
        ),
    ];

    final safeIndex =
        widget.currentIndex < items.length ? widget.currentIndex : 0;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      type: BottomNavigationBarType.fixed,
      items: items,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MyCustomScreen(initialPage: 0),
            ),
          );
          return;
        }

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MyCustomScreen(initialPage: 1),
            ),
          );
          return;
        }

        if (!_isAuthorized) {
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
