import 'dart:async';
import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/navigation/shell_nav_auth_cache.dart';
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
  bool _isLoadingAuth = true;

  @override
  void initState() {
    super.initState();
    if (CustomerShellNavCache.resolved) {
      _isAuthorized = CustomerShellNavCache.isAuthorized;
      _highlightOrders = CustomerShellNavCache.highlightOrders;
      _activeOrderUserId = CustomerShellNavCache.activeOrderUserId;
      _activeOrderId = CustomerShellNavCache.activeOrderId;
      _isLoadingAuth = false;
    }
    _loadOrderHighlight();
  }

  Future<void> _loadOrderHighlight() async {
    var isAuthorized = _isAuthorized;
    var highlightOrders = _highlightOrders;
    var activeOrderUserId = _activeOrderUserId;
    var activeOrderId = _activeOrderId;
    var authResolved = false;

    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) {
        isAuthorized = false;
        highlightOrders = false;
        activeOrderUserId = '';
        activeOrderId = '';
        authResolved = true;
        return;
      }

      final userResponse = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'),
      );
      if (userResponse.statusCode != 200) return;

      final userData = json.decode(userResponse.body);
      if (userData['error'] != null || userData['idusers'] == null) {
        isAuthorized = false;
        highlightOrders = false;
        activeOrderUserId = '';
        activeOrderId = '';
        authResolved = true;
        return;
      }

      final userId = userData['idusers'].toString();
      if (userId.isEmpty) {
        isAuthorized = false;
        highlightOrders = false;
        activeOrderUserId = '';
        activeOrderId = '';
        authResolved = true;
        return;
      }
      isAuthorized = true;
      authResolved = true;

      final statusResponse = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/check_order_statusisp.php?userIdok=$userId'),
      );
      if (statusResponse.statusCode != 200) return;

      final statusData = json.decode(statusResponse.body);
      highlightOrders = statusData['result'] == true;
      if (highlightOrders) {
        activeOrderUserId = statusData['user_id']?.toString() ?? '';
        activeOrderId = statusData['order_id']?.toString() ?? '';
      } else {
        activeOrderUserId = '';
        activeOrderId = '';
      }
    } catch (_) {
      // Не блокируем нижнее меню при ошибке сети.
    } finally {
      if (!mounted) return;
      if (authResolved || !CustomerShellNavCache.resolved) {
        CustomerShellNavCache.update(
          isAuthorized: isAuthorized,
          highlightOrders: highlightOrders,
          activeOrderUserId: activeOrderUserId,
          activeOrderId: activeOrderId,
        );
        setState(() {
          _isAuthorized = isAuthorized;
          _highlightOrders = highlightOrders;
          _activeOrderUserId = activeOrderUserId;
          _activeOrderId = activeOrderId;
          _isLoadingAuth = false;
        });
        if (isAuthorized) {
          unawaited(syncPushFcmTokenToServer(requestPermission: false));
        }
      } else {
        setState(() {
          _isLoadingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth) {
      return const SizedBox(height: kBottomNavigationBarHeight);
    }

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
              builder: (_) => const MyApp(initialPage: 1),
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
