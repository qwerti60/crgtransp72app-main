import 'dart:typed_data';

import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/get_vt.dart' as performer_services;
import 'package:crgtransp72app/pages/history_zak.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../navigation/shell_bottom_nav_spec.dart';
import '../pages/ads1.dart';
import '../pages/outputobzlikes1.dart';
import '../pages/subscription_screen.dart';
import '../pages/fcm_token.dart';

class HistortScreen12 extends StatefulWidget {
  const HistortScreen12({
    Key? key,
    required this.pageProfile,
  }) : super(key: key);

  final String pageProfile;

  @override
  _HistortScreenState createState() => _HistortScreenState();
}

class _HistortScreenState extends State<HistortScreen12> {
  int? _currentIndex;
  bool _isAuthorized = false;
  final List<Widget?> _pages = List.filled(4, null, growable: false);

  List<Widget Function()> get _tabBuilders {
    final builders = <Widget Function()>[
      () => const performer_services.MyImageGrid(),
      () => const SearchForm(showBottomNav: false),
    ];

    if (_isAuthorized) {
      builders.add(() => zprofil_name2());
    }

    return builders;
  }

  void _selectTab(int index) {
    final builders = _tabBuilders;
    if (index >= builders.length) return;

    setState(() {
      _currentIndex = index;
      _pages[index] ??= builders[index]();
    });
  }

  bool hasActiveOrder = false; // Переменная для отслеживания активности заказа

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
          throw Exception('Error from server: ${data['error']}');
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
      } else {
        throw Exception(
            'Failed to load user data with status code: ${response.statusCode}}');
      }
    } catch (err) {
      print('Error loading user data: $err');
    }
  }

  Future<Map<String, dynamic>> checkOrderStatus(String userIdok) async {
    final uri = Uri.parse(
        'https://ivnovav.ru/api/check_order_status.php?userIdok=$userIdok');
    final response =
        await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      print('drr ${decodedResponse}');
      return decodedResponse;
    } else {
      throw Exception('Ошибка загрузки статуса заказа');
    }
  }

  @override
  void initState() {
    super.initState();
    _resolveAuthorization();
    getUserData().then((_) {
      setState(() {});
    }).catchError((err) {
      print('Ошибка в процессе получения данных: $err');
    });
  }

  Future<void> _resolveAuthorization() async {
    final token = await getSecurefcm_token();
    if (!mounted) return;

    setState(() {
      _isAuthorized = token != null && token.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(userId.toString()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orderInfo = snapshot.data!;
        hasActiveOrder = orderInfo['result'] == true;

        final navLabels = PerformerBmenuShellNav.bottomNavLabels(
            isAuthenticated: _isAuthorized);
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
        final initialPage = (!_isAuthorized &&
                const {'zprofil_ld', 'zprofil_zayavki', 'Subscription'}.contains(widget.pageProfile))
            ? const Ads1App()
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
      },
    );
  }
}

Widget buildProfilePage(String pageProfile, {required String orderId}) {
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld();
    case 'Ads1App':
      return const Ads1App();
    case 'zprofil_zayavki':
      return const zprofil_zayavki(nameImg: '', base: 1);
    case 'hist':
      return history_zak(nameImg: orderId, bd: 1);
    case 'izbrannoe':
      return outputobzlikes1(nameImg: '', base: 1);
    case 'Subscription':
      return const SubscriptionScreen();
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
