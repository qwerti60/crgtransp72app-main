import 'dart:typed_data';

import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../pages/ads1.dart';
import '../pages/outputobzlikes1.dart';
import '../pages/history_isp.dart';
import '../pages/subscription_screen.dart';
import '../pages/fcm_token.dart';

class HistortScreen extends StatefulWidget {
  const HistortScreen({
    Key? key,
    required this.pageProfile,
  }) : super(key: key);

  final String pageProfile;

  @override
  _HistortScreenState createState() => _HistortScreenState();
}

class _HistortScreenState extends State<HistortScreen> {
  int? _currentIndex;

  Map<String, dynamic>? orderInfo; // Информация о заказе

  final List<Widget?> _pages = List.filled(3, null, growable: false);
  late final List<Widget Function()> _builders = [
    () => MyAppI1z(),
    () => hasActiveOrder
        ? OrderExecutionScreen(
            userId: orderuserid, //orderInfo!['user_id'].toString(),
            orderId: orderid //orderInfo!['order_id'].toString()
            )
        : SearchForm(),
    () => zprofil_name2(),
  ];

  void _selectTab(int index) {
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
          orderuserid = data['user_id']?.toString() ?? '';
        });
        print('object');
        print(orderid);
        print(userId);
        print(orderuserid);
        print(data);
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
    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(userId.toString()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orderInfo = snapshot.data!;
        hasActiveOrder = orderInfo['result'] == true;

        return Scaffold(
          //       body: _currentIndex == null
          //         ? buildProfilePage(widget.pageProfile, orderId: orderid)
          //       : _pages[_currentIndex!],
          body: _currentIndex == null
              ? buildProfilePage(widget.pageProfile, orderId: orderid)
              : _builders[_currentIndex!](),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex ?? 0,
            onTap: _selectTab,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.fire_truck), label: 'Объявления'),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.subject,
                  color: hasActiveOrder
                      ? Colors.red
                      : null, // Меняется цвет иконки, если есть активная заявка
                ),
                label: 'Заявки',
              ),
              /*   const BottomNavigationBarItem(
                  icon: Icon(Icons.group), label: 'Заказчики'),
             */
              const BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle), label: 'Профиль'),
            ],
          ),
        );
      },
    );
  }
}

Widget buildProfilePage(String pageProfile, {required String orderId}) {
  print('[HistortScreen/test] pageProfile: $pageProfile');
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld();
    case 'Ads1App':
      return const Ads1Page();
    case 'zprofil_zayavki':
      return const zprofil_zayavki(nameImg: '', base: 1);
    case 'hist':
      return history_isp(nameImg: orderId, bd: 1);
    case 'izbrannoe':
      return const Outputobzlikes1Page(nameImg: '', base: 1);
    case 'outputobzlikes':
      return const Outputobzlikes1Page(nameImg: '', base: 1);
    case 'Subscription':
      return const SubscriptionScreen();
    case 'profileMain':
      return const zprofil_name2();
    default:
      return const SizedBox.shrink();
  }
}

String orderid = '';
String orderuserid = '';
bool isSwitched = false;
Uint8List? fotouser;
String firstName = '';
String lastName = '';
String middleName = '';
String city = '';
String phone = '';
String email = '';
int userId = 0;
