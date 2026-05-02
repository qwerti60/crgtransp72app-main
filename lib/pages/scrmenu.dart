import 'dart:typed_data';

import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/SendReviewForm.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/list_predloj_na_zayavki.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart' as customer_home;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import '../pages/ads1.dart';
import '../pages/outputobzlikes1.dart';
import '../pages/history_isp.dart';
import '../pages/subscription_screen.dart';
import '../pages/fcm_token.dart';

class HistortScreen1 extends StatefulWidget {
  final String? pageProfile;
  final String? userId1; // Параметры принимаются конструктором
  final String? orderId; // Параметры принимаются конструктором
  final String? parsedUserIdOk;
  const HistortScreen1({
    Key? key,
    required this.pageProfile,
    required this.userId1,
    required this.orderId,
    required this.parsedUserIdOk,
  }) : super(key: key);

  @override
  _HistortScreenState createState() => _HistortScreenState();
}

class _HistortScreenState extends State<HistortScreen1> {
  int? _currentIndex;

  Map<String, dynamic>? orderInfo; // Информация о заказе

  final List<Widget?> _pages = List.filled(4, null, growable: false);
  late final List<Widget Function()> _builders = [
    () => const MyImageGrid(),
    () => hasActiveOrder
        ? OrderExecutionScreen(
            userId: orderInfo!['user_id'],
            orderId: orderInfo!['order_id'],
            showBottomNav: false)
        : SearchForm(),
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
          userId1 = data['idusers'];
          firstName = data['firstName']?.toString() ?? '';
          lastName = data['lastName']?.toString() ?? '';
          middleName = data['middleName']?.toString() ?? '';
          city = data['city']?.toString() ?? '';
          phone = data['phone']?.toString() ?? '';
          email = data['email']?.toString() ?? '';
          fotouser =
              data['fotouser'] != null ? base64Decode(data['fotouser']) : null;
          orderid123 = data['order_id']?.toString() ?? '';
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
    uid = widget.userId1!;
    oid = widget.orderId!;
    uidok = widget.parsedUserIdOk!;
    bd = int.parse(widget.orderId!);
    print('userIdiii: ${uid}');
    print('orderIdiii: ${oid}');
    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(userId1.toString()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orderInfo = snapshot.data!;
        hasActiveOrder = orderInfo['result'] == true;

        return Scaffold(
          body: _currentIndex == null
              ? buildProfilePage(widget.pageProfile!, widget.userId1,
                  widget.orderId, widget.parsedUserIdOk!)
              : _pages[_currentIndex!],
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
              /*         const BottomNavigationBarItem(
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

Widget buildProfilePage(String pageProfile, userId1, orderId123, String uidok) {
  print('pageProfile'); // должно быть SearchForm
  print(pageProfile); // должно быть SearchForm
  print(userId1);
  print(orderId123);
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld();
    case 'Ads1App':
      return const Ads1App();
    case 'zprofil_zayavki':
      return const zprofil_zayavki(nameImg: '', base: 1);
    case 'hist':
      return history_isp(nameImg: orderid123, bd: 1);
    case 'SendReviewForm':
      return SendReviewForm(
        currentUserId: userId1,
        targetUserId: orderId123,
        parsedUserIdOk: int.parse(uidok),
      );
    case 'Subscription':
      return const SubscriptionScreen();
    /*case 'OrderExecutionScreen': // Специальный случай для OrderExecutionScreen
      return OrderExecutionScreen(
        userId: uid.toString(), // Передаем userId
        orderId: oid ?? '', // Передаем orderId
      );
*/
    case 'list_predloj_na_zayavki':
      return list_predloj_na_zayavki(nameImg: uid, bd: bd);
    case 'SearchForm':
      return outputobz(
        nameImg: userId1,
        city: orderId123,
        showBottomNav: false,
      );
    default:
      return const SizedBox.shrink();
  }
}

String orderid123 = '';
bool isSwitched = false;
Uint8List? fotouser;
String firstName = '';
String lastName = '';
String middleName = '';
String city = '';
String phone = '';
String email = '';
int userId1 = 0;
int userId123 = 0;
String uid = '';
String oid = '';
String uidok = '';
int bd = 0;
