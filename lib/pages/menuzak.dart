import 'dart:typed_data';

import 'package:crgtransp72app/pages/OrderExecutionScreenzak.dart';
import 'package:crgtransp72app/pages/SearchFormisp.dart';
import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/history_zak.dart';
import 'package:crgtransp72app/pages/outputobzlikes.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_page.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../navigation/shell_bottom_nav_spec.dart';
import '../pages/ads1.dart';
import '../pages/outputobzlikes1.dart';
import '../pages/history_isp.dart';
import '../pages/subscription_screen.dart';
import '../pages/fcm_token.dart';

class MenuzakScreen extends StatefulWidget {
  const MenuzakScreen({
    Key? key,
    required this.pageProfile,
  }) : super(key: key);

  final String pageProfile;

  @override
  _MenuzakScreenState createState() => _MenuzakScreenState();
}

class _MenuzakScreenState extends State<MenuzakScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'История заказов',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(pageProfile: widget.pageProfile),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.pageProfile,
  });

  final String pageProfile;

  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? _currentIndex;
  bool _isAuthorized = false;
  final List<Widget?> _pages = List.filled(4, null, growable: false);

  List<Widget Function()> get _tabBuilders {
    final builders = <Widget Function()>[
      () => const MyAppI1zPage(),
      () => const SearchFormisp(embedInCustomerShell: true),
    ];

    if (_isAuthorized) {
      builders.add(() => zprofil_name());
    }

    return builders;
  }

  void _selectTab(int index) {
    final builders = _tabBuilders;
    if (index >= builders.length) return;

    if (index == 1 &&
        hasActiveOrder &&
        activeOrderUserId.isNotEmpty &&
        activeOrderId.isNotEmpty) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderExecutionScreenzak(
            userId: activeOrderUserId,
            orderId: activeOrderId,
          ),
        ),
        (Route<dynamic> route) => false,
      );
      return;
    }

    setState(() {
      _currentIndex = index;
      _pages[index] ??= builders[index]();
    });
  }

  static Widget buildProfilePage(String pageProfile,
      {required String orderId}) {
    switch (pageProfile) {
      case 'zprofil_ld':
        return const zprofil_ld(showBottomNav: false);
      case 'Ads2App':
        return const Ads2App(showBottomNav: false);
      case 'outputobzlikes':
        print('[menuzak] route: outputobzlikes -> outputobzlikes1');
        return const Outputobzlikes1Page(nameImg: '', base: 1);
      case 'hist':
        return const history_zak(nameImg: '', bd: 1);
      default:
        return const SizedBox.shrink();
    }
  }

  String orderid = '';
  bool isSwitched = false;
  Uint8List? fotouser;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _resolveAuthorization();
    getUserData();
  }

  Future<void> _resolveAuthorization() async {
    final token = await getSecurefcm_token();
    if (!mounted) return;

    setState(() {
      _isAuthorized = token != null && token.isNotEmpty;
    });
  }

  Future<void> getUserData() async {
    try {
      final token = await getSecurefcm_token();

      if (token == null || token.isEmpty) {
        throw Exception('Token not found or empty');
      }

      final response = await http.get(Uri.parse(
          '${Config.baseUrl}/api/getuserinfo_order.php?token=$token'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['error'] != null) {
          throw Exception('Error from server: ${data['error']}}');
        }

        setState(() {
          userId = data['idusers'];
          firstName = data['firstName']?.toString() ?? '';
          lastName = data['lastName']?.toString() ?? '';
          middleName = data['middleName']?.toString() ?? '';
          city = data['city']?.toString() ?? '';
          phone = data['phone']?.toString() ?? '';
          email = data['email']?.toString() ?? '';
          fotouser =
              data['fotouser'] != null ? base64Decode(data['fotouser']) : null;
          orderid = data['order_id']?.toString() ?? '';
        });

        final orderInfo = await checkOrderStatus(userId.toString());
        if (!mounted) return;
        setState(() {
          hasActiveOrder = orderInfo['result'] == true;
          activeOrderUserId = orderInfo['user_id']?.toString() ?? '';
          activeOrderId = orderInfo['order_id']?.toString() ?? '';
        });
      } else {
        throw Exception(
            'Failed to load user data with status code: ${response.statusCode}}');
      }
    } catch (err) {
      print('Error loading user data: $err');
    }
  }

  bool hasActiveOrder = false; // Переменная для отслеживания активности заказа
  String activeOrderUserId = '';
  String activeOrderId = '';

  Future<Map<String, dynamic>> checkOrderStatus(String userIdok) async {
    final uri = Uri.parse(
        '${Config.baseUrl}/api/check_order_statusisp.php?userIdok=$userIdok');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      print('drr ${decodedResponse}');
      return decodedResponse;
    } else {
      throw Exception('Ошибка загрузки статуса заказа');
    }
  }

  @override
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

    final safeIndex = (_currentIndex ?? 0) < items.length ? (_currentIndex ?? 0) : 0;
    final initialPage = (!_isAuthorized && widget.pageProfile == 'zprofil_ld')
        ? const Ads2App(showBottomNav: false)
        : buildProfilePage(widget.pageProfile, orderId: orderid);

    return Scaffold(
      body: _currentIndex == null ? initialPage : _pages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        items: items,
      ),
    );
  }

// Добавляем метод для отображения будущего результата проверки заказа
  Widget _checkOrderStatus(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(orderid.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Ошибка загрузки статуса заказа: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const Text('Нет данных');
        }

        final orderInfo = snapshot.data!;
        hasActiveOrder = orderInfo['result'] == true;
        return Scaffold(); // Здесь можете вернуть нужный вам виджет
      },
    );
  }
}
