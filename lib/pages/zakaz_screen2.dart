import 'dart:async';
import 'dart:convert';
import 'package:crgtransp72app/services/chat_push_handler.dart';
import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:crgtransp72app/navigation/last_app_role.dart';
import 'package:crgtransp72app/navigation/pending_performer_order.dart';
import 'package:crgtransp72app/navigation/performer_shell_scope.dart';
import 'package:crgtransp72app/navigation/shell_bottom_nav_spec.dart';
import 'package:crgtransp72app/navigation/shell_nav_auth_cache.dart';
import 'package:crgtransp72app/config.dart';
import '../design/app_theme.dart';
import '../design/colors.dart';
import 'changerol_page.dart';
import 'loginpage.dart';
import 'get_vt.dart' as performer_services;
import 'zprofil_page2.dart';
void main() {
  runApp(const MyAppZakazScreen());
}

class MyAppZakazScreen extends StatelessWidget {
  final int initialPage;
  const MyAppZakazScreen({super.key, this.initialPage = 0});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: crgAppTheme(),
      home: MyCustomScreen(initialPage: initialPage),
    );
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
  Future<Map<String, dynamic>>? _activeOrderFuture;
  bool _autoSwitchedToOrders = false;

  void _loadActiveOrderFuture() {
    final performerId = userIdok;
    if (performerId == null || performerId.isEmpty) {
      _activeOrderFuture = null;
      return;
    }
    _activeOrderFuture = checkOrderStatus(performerId);
  }
  Future<void> getUserData() async {
    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        PerformerShellNavCache.update(
          isAuthorized: false,
          highlightOrders: false,
        );
        setState(() {
          _isAuthorized = false;
          _isLoadingAuth = false;
        });
        return;
      }

      final response = await http
          .get(Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'))
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == null && data['idusers'] != null) {
          PerformerShellNavCache.update(
            isAuthorized: true,
            highlightOrders: false,
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

      PerformerShellNavCache.update(
        isAuthorized: false,
        highlightOrders: false,
      );
      setState(() {
        _isAuthorized = false;
        _isLoadingAuth = false;
        userIdok = null;
      });
    } catch (_) {
      if (!mounted) return;
      PerformerShellNavCache.update(
        isAuthorized: false,
        highlightOrders: false,
      );
      setState(() {
        _isAuthorized = false;
        _isLoadingAuth = false;
        userIdok = null;
      });
    }
  }

  Future<Map<String, dynamic>> checkOrderStatus(String performerId) async {
    final uri = Uri.parse(
        '${Config.apiBase}/check_order_status1.php?userIdok=$performerId');
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
    if (PendingPerformerOrder.has && _currentPage == 1) {
      final pending = OrderExecutionScreen(
        userId: PendingPerformerOrder.performerId!,
        orderId: PendingPerformerOrder.orderId!,
        customerUserId: PendingPerformerOrder.customerUserId,
        bd: PendingPerformerOrder.bd,
        orderSource: PendingPerformerOrder.orderSource,
        showBottomNav: false,
      );
      PendingPerformerOrder.clear();
      return pending;
    }

    switch (_currentPage) {
      case 0:
        return const performer_services.MyImageGrid();
      case 1:
        if (orderInfo != null && orderInfo['result'] == true) {
          final customerId = orderInfo['user_idok']?.toString();
          final startTime = orderInfo['start_time']?.toString();
          debugPrint(
              '[ISP] shell order user=${orderInfo['user_id']} order=${orderInfo['order_id']} customer=$customerId start=$startTime');
          return OrderExecutionScreen(
            key: ValueKey('exec-${orderInfo['order_id']}'),
            userId: orderInfo['user_id']?.toString() ?? '',
            orderId: orderInfo['order_id']?.toString() ?? '',
            customerUserId:
                (customerId != null && customerId.isNotEmpty) ? customerId : null,
            initialStartTime:
                (startTime != null && startTime.isNotEmpty) ? startTime : null,
            showBottomNav: false,
          );
        } else {
          return const SearchForm(
            showBottomNav: false,
            embedInPerformerShell: true,
          );
        }
      case 2:
        if (!_isAuthorized) {
          return const performer_services.MyImageGrid();
        }
        return const zprofil_name2();
      default:
        return const performer_services.MyImageGrid();
    }
  }

  Widget _buildScaffold(Map<String, dynamic>? orderInfo) {
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
        backgroundColor: whiteprColor,
        appBar: safePage == 0
            ? AppBar(
                title: const Text(
                  'Техника',
                  style: TextStyle(
                    color: whiteprColor,
                  ),
                ),
                backgroundColor: blueaccentColor,
              )
            : null,
        floatingActionButton: safePage == 0
            ? FloatingActionButton(
                onPressed: () async {
                  if (!_isAuthorized) {
                    await showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          title: const Text('Требуется авторизация'),
                          content: const Text(
                            'Размещение объявления доступно после входа в аккаунт.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Отмена'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text('Войти'),
                            ),
                          ],
                        );
                      },
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const changerol(),
                    ),
                  );
                },
                backgroundColor: blueaccentColor,
                child: const Icon(Icons.add),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: PerformerShellScope(
          selectTab: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          child: Column(
            children: <Widget>[
              Expanded(child: _getScreen(orderInfo)),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: items,
          type: BottomNavigationBarType.fixed,
          currentIndex: safePage,
          selectedIconTheme: const IconThemeData(color: violetColor),
          onTap: (index) {
            setState(() {
              _currentPage = index;
            });
          },
        ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    unawaited(saveLastAppRole(AppRole.performer));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatPushHandler.tryOpenPending(context);
    });
    getUserData().then((_) {
      if (!mounted) return;
      if (!_isAuthorized && _currentPage >= 2) {
        setState(() => _currentPage = 0);
      } else {
        setState(() {
          _loadActiveOrderFuture();
        });
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

    if (_activeOrderFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _activeOrderFuture,
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
        PerformerShellNavCache.update(
          isAuthorized: true,
          highlightOrders: hasActiveOrder,
        );

        if (hasActiveOrder &&
            !_autoSwitchedToOrders &&
            _currentPage != 1) {
          final status = orderInfo['status']?.toString() ?? '';
          final isExecuting =
              status.isEmpty || status == 'выполняется';
          if (isExecuting) {
            _autoSwitchedToOrders = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _currentPage = 1);
              }
            });
          }
        }

        return _buildScaffold(orderInfo);
      },
    );
  }
}
