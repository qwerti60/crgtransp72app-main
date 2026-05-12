import 'dart:convert';
import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/ads1.dart';
import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/outputobzlikes1.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../design/colors.dart';
import 'changerol_page.dart';
import 'get_vt.dart' as performer_services;
import 'vod_zak.dart';
import 'zprofil_page.dart';
import 'zprofil_zakaz.dart';
void main() {
  runApp(const MyAppZakazScreen());
}

class MyAppZakazScreen extends StatelessWidget {
  const MyAppZakazScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MyCustomScreen());
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
          setState(() {
            userIdok = data['idusers'].toString();
            _isAuthorized = true;
            _isLoadingAuth = false;
          });
          return;
        }
      }

      setState(() {
        _isAuthorized = false;
        _isLoadingAuth = false;
        userIdok = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAuthorized = false;
        _isLoadingAuth = false;
        userIdok = null;
      });
    }
  }

  Future<Map<String, dynamic>> checkOrderStatus(String userIdok) async {
    final uri = Uri.parse(
        'https://ivnovav.ru/api/check_order_status1.php?userIdok=$userIdok');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      print('drr454 ${decodedResponse}');
      return decodedResponse;
    } else {
      throw Exception('Ошибка загрузки статуса заказа');
    }
  }

  Widget _getScreen(Map<String, dynamic>? orderInfo) {
    switch (_currentPage) {
      case 0:
        return const performer_services.MyImageGrid();
      case 1:
        if (orderInfo != null && orderInfo['result'] == true) {
          return OrderExecutionScreen(
            userId: orderInfo['user_id'],
            orderId: orderInfo['order_id'],
            showBottomNav: true,
          );
        } else {
          return const SearchForm(showBottomNav: false); //Ads1App();
        }
      case 2:
        if (!_isAuthorized) {
          return const Ads2App();
        }
        return const zprofil_name2();
      default:
        return const performer_services.MyImageGrid();
    }
  }

  Widget _buildScaffold(Map<String, dynamic>? orderInfo) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.fire_truck),
        label: 'Объявления',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          Icons.subject,
          color: hasActiveOrder ? Colors.red : null,
        ),
        label: 'Заявки',
      ),
      if (_isAuthorized)
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Профиль',
        ),
    ];

    final safePage = _currentPage >= items.length ? 0 : _currentPage;
    if (safePage != _currentPage) {
      _currentPage = safePage;
    }

    return Scaffold(
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
                onPressed: () {
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
    getUserData().then((_) {
      setState(() {});
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
      return const Center(child: CircularProgressIndicator());
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

        return _buildScaffold(orderInfo);
      },
    );
  }
}
