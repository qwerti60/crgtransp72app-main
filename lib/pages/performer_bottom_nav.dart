import 'package:crgtransp72app/navigation/performer_shell_scope.dart';
import 'package:crgtransp72app/navigation/shell_nav_auth_cache.dart';
import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:crgtransp72app/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
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
    if (PerformerShellNavCache.resolved) {
      _isAuthorized = PerformerShellNavCache.isAuthorized;
      _highlightOrders = PerformerShellNavCache.highlightOrders;
      _isLoadingAuth = false;
    }
    _loadOrderHighlight();
  }

  Future<void> _loadOrderHighlight() async {
    var isAuthorized = _isAuthorized;
    var highlightOrders = _highlightOrders;
    var authResolved = false;

    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) {
        isAuthorized = false;
        highlightOrders = false;
        authResolved = true;
        return;
      }

      // Тот же источник, что и MyCustomScreen (zakaz_screen2) — иначе после «Услуги» → CityScreen
      // нижнее меню без «Профиля», хотя пользователь уже вошёл.
      final userResponse = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'),
      );
      if (userResponse.statusCode != 200) return;

      final userData = json.decode(userResponse.body);
      if (userData['error'] != null || userData['idusers'] == null) {
        isAuthorized = false;
        highlightOrders = false;
        authResolved = true;
        return;
      }

      final userId = userData['idusers'].toString();
      if (userId.isEmpty) {
        isAuthorized = false;
        highlightOrders = false;
        authResolved = true;
        return;
      }
      isAuthorized = true;
      authResolved = true;

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
      if (authResolved || !PerformerShellNavCache.resolved) {
        PerformerShellNavCache.update(
          isAuthorized: isAuthorized,
          highlightOrders: highlightOrders,
        );
        setState(() {
          _isAuthorized = isAuthorized;
          _highlightOrders = highlightOrders;
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
        PerformerShellNav.bottomNavLabels(isAuthenticated: _isAuthorized);
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
      items: items,
      onTap: (index) {
        final shellSelectTab = PerformerShellScope.selectTabOf(context);
        if (shellSelectTab != null) {
          if (index == 2 && !_isAuthorized) {
            return;
          }
          shellSelectTab(index);
          return;
        }

        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MyCustomScreen(initialPage: 0),
            ),
            (Route<dynamic> route) => false,
          );
          return;
        }

        if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MyCustomScreen(initialPage: 1),
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
            builder: (_) => MyCustomScreen(initialPage: 2),
          ),
          (Route<dynamic> route) => false,
        );
      },
    );
  }
}
