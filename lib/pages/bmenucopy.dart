import 'dart:typed_data';

import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/SendReviewFormzakaz.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/history_zak.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart' as customer_home;
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

class HistortScreen12z extends StatefulWidget {
  final String pageProfile;
  final String userId1; // Параметры принимаются конструктором
  final String orderId; // Параметры принимаются конструктором
  final String parsedUserIdOk;
  const HistortScreen12z({
    Key? key,
    required this.pageProfile,
    required this.userId1,
    required this.orderId,
    required this.parsedUserIdOk,
  }) : super(key: key);

  //final String pageProfile;

  @override
  _HistortScreenState createState() => _HistortScreenState();
}

class _HistortScreenState extends State<HistortScreen12z> {
  int? _currentIndex;

  final List<Widget?> _pages = List.filled(3, null, growable: false);

  late final List<Widget Function()> _builders = [
    () => const MyImageGrid(),
    () => const SearchForm(showBottomNav: false),
    //() => zprofil_zayavki(nameImg: '', base: 1),
    () => zprofil_name2(),
  ];

  void _selectTab(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const customer_home.MyApp()),
        (Route<dynamic> route) => false,
      );
      return;
    }
    setState(() {
      _currentIndex = index;
      _pages[index] ??= _builders[index]();
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
        'https://ivnovav.ru/api/check_order_status1.php?userIdok=$userIdok');
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
    getUserData().then((_) {
      setState(() {});
    }).catchError((err) {
      print('Ошибка в процессе получения данных: $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    print('lolo');
    print(widget.orderId);
    print(widget.userId1);
    print(widget.pageProfile);
    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(userId.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator()); // Показываем индикатор ожидания
        }

        if (snapshot.hasError) {
          return Text("Ошибка: ${snapshot.error}");
        }

        final orderInfo = snapshot.data!;
        hasActiveOrder = orderInfo['result'] == true;

        return Scaffold(
          body: _currentIndex == null
              ? buildProfilePage(widget.pageProfile, widget.userId1,
                  widget.orderId, widget.pageProfile)
              : _pages[_currentIndex!],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex ?? 0,
            onTap: _selectTab,
            type: BottomNavigationBarType.fixed,
            items: () {
              final navLabels = PerformerBmenuCopyShellNav.bottomNavLabels();
              return [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.fire_truck),
                  label: navLabels[0],
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.subject,
                    color: hasActiveOrder
                        ? Colors.red
                        : null, // Меняем цвет иконки на красный, если есть активная запись
                  ),
                  label: navLabels[1],
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.account_circle),
                  label: navLabels[2],
                ),
              ];
            }(),
          ),
        );
      },
    );
  }
}

Widget buildProfilePage(
    String pageProfile, String userId1, String orderId, String parsedUserIdOk) {
  switch (pageProfile) {
    case 'SearchForm':
      print(userId1); // Переместили сюда вывод строки
      print(orderId); // Переместили сюда вывод строки
      return outputobz(
        nameImg: orderId,
        city: userId1,
        showBottomNav: false,
      ); // Возвращаем виджет сразу же
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
