import 'dart:async';
import 'dart:convert';
import 'package:crgtransp72app/services/chat_push_handler.dart';
import 'package:crgtransp72app/pages/OrderExecutionScreenzak.dart';
import 'package:crgtransp72app/pages/SearchFormisp.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/navigation/shell_nav_auth_cache.dart';
import '../design/colors.dart';
import 'get_vt_z.dart';
import 'zprofil_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final int initialPage;
  const MyApp({super.key, this.initialPage = 0});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MyCustomScreen(initialPage: initialPage));
  }
}

class MyCustomScreen extends StatefulWidget {
  final int initialPage;
  const MyCustomScreen({super.key, this.initialPage = 0});

  @override
  _MyCustomScreenState createState() => _MyCustomScreenState();
}

class _MyCustomScreenState extends State<MyCustomScreen> {
  int _currentPage = 0;
  String? userIdok; // Пользовательский идентификатор
  bool _isAuthorized = false;
  bool _isLoadingAuth = true;
  bool hasActiveOrder = false; // Есть ли активная запись
  String? retrievedOrderId; // Извлекаемый идентификатор заказа


  Future<void> getUserData() async {
    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        CustomerShellNavCache.update(
          isAuthorized: false,
          highlightOrders: false,
          activeOrderUserId: '',
          activeOrderId: '',
        );
        setState(() {
          _isAuthorized = false;
          _isLoadingAuth = false;
        });
        return;
      }

      final response = await http
          .get(Uri.parse('https://ivnovav.ru/api/getuserinfo.php?token=$token'))
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == null && data['idusers'] != null) {
          CustomerShellNavCache.update(
            isAuthorized: true,
            highlightOrders: false,
            activeOrderUserId: '',
            activeOrderId: '',
          );
          setState(() {
            userIdok = data['idusers'].toString();
            _isAuthorized = true;
            _isLoadingAuth = false;
          });
          unawaited(syncPushFcmTokenToServer(requestPermission: true));
          return;
        }
      }

      CustomerShellNavCache.update(
        isAuthorized: false,
        highlightOrders: false,
        activeOrderUserId: '',
        activeOrderId: '',
      );
      setState(() {
        _isAuthorized = false;
        _isLoadingAuth = false;
        userIdok = null;
      });
    } catch (_) {
      if (!mounted) return;
      CustomerShellNavCache.update(
        isAuthorized: false,
        highlightOrders: false,
        activeOrderUserId: '',
        activeOrderId: '',
      );
      setState(() {
        _isAuthorized = false;
        _isLoadingAuth = false;
        userIdok = null;
      });
    }
  }

  Future<Map<String, dynamic>> checkOrderStatus(String userIdok) async {
    final uri = Uri.parse(
        'https://ivnovav.ru/api/check_order_statusisp.php?userIdok=$userIdok');
    final response =
        await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      print('drr454 ${decodedResponse}');
      return decodedResponse;
    } else {
      throw Exception('Ошибка загрузки статуса заказа');
    }
  }

  Widget _getScreen(Map<String, dynamic>? orderInfo) {
    print('oi678${orderInfo}');
    switch (_currentPage) {
      case 0:
        return MyAppI1zPage(isAuthenticated: _isAuthorized);
      case 1:
        if (orderInfo != null && orderInfo['result'] == true) {
          return OrderExecutionScreenzak(
            userId: orderInfo['user_id']?.toString() ?? '',
            orderId: orderInfo['order_id']?.toString() ?? '',
            showBottomNav: false,
          );
        } else {
          return const SearchFormisp(embedInCustomerShell: true); // Ads1App();
        }
      case 2:
        if (!_isAuthorized) {
          return MyAppI1zPage(isAuthenticated: _isAuthorized);
        }
        return const zprofil_name();
      default:
        return MyAppI1zPage(isAuthenticated: _isAuthorized);
    }
  }

  Widget _buildScaffold(Map<String, dynamic>? orderInfo) {
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
          color: hasActiveOrder ? Colors.red : null,
        ),
        label: navLabels[1],
      ),
      if (navLabels.length > 2)
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_circle),
          label: navLabels[2],
        ),
    ];

    final safePage = _currentPage >= items.length ? 0 : _currentPage;
    if (safePage != _currentPage) {
      _currentPage = safePage;
    }

    return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(child: _getScreen(orderInfo)),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: items,
          type: BottomNavigationBarType.fixed,
          currentIndex: safePage,
          selectedIconTheme: const IconThemeData(color: violetColor),
          onTap: (index) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => MyApp(initialPage: index)),
              (Route<dynamic> route) => false,
            );
          },
        ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatPushHandler.tryOpenPending(context);
    });
    getUserData().then((_) {
      if (!mounted) return;
      if (!_isAuthorized && _currentPage >= 2) {
        setState(() => _currentPage = 0);
      } else {
        setState(() {});
      }
    }).catchError((err) {
      print('Ошибка в процессе получения данных: $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isAuthorized) {
      hasActiveOrder = false;
      return _buildScaffold(null);
    }

    if (userIdok == null) {
      return _buildScaffold(null);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(userIdok!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orderInfo = snapshot.data;
        if (snapshot.hasError || orderInfo == null) {
          hasActiveOrder = false;
          return _buildScaffold(null);
        }
        hasActiveOrder =
            orderInfo['result'] == true; // Проверяем наличие активной записи
        CustomerShellNavCache.update(
          isAuthorized: true,
          highlightOrders: hasActiveOrder,
          activeOrderUserId: orderInfo['user_id']?.toString() ?? '',
          activeOrderId: orderInfo['order_id']?.toString() ?? '',
        );
        print('res: ${orderInfo['result']}');

        return _buildScaffold(orderInfo);
      },
    );
  }
}
