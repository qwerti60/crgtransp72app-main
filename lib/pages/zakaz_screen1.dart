import 'dart:convert';
import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/OrderExecutionScreenzak.dart';
import 'package:crgtransp72app/pages/SearchFormisp.dart';
import 'package:crgtransp72app/pages/ads1.dart';
import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/outputobzlikes.dart';
import 'package:crgtransp72app/pages/outputobzlikes1.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../design/colors.dart';
import 'get_vt.dart';
import 'vod_zak.dart';
import 'zprofil_page.dart';
import 'zprofil_zakaz.dart';

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
  bool hasActiveOrder = false; // Есть ли активная запись
  String? retrievedOrderId; // Извлекаемый идентификатор заказа

  Future<void> getUserData() async {
    final token = await getSecurefcm_token();
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('https://ivnovav.ru/api/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        setState(() {
          userIdok =
              data['idusers'].toString(); // Получаем идентификатор пользователя
        });
        print('Пользователь: $userIdok');
        print('Пользователь: $userIdok');
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<Map<String, dynamic>> checkOrderStatus(String userIdok) async {
    final uri = Uri.parse(
        'https://ivnovav.ru/api/check_order_statusisp.php?userIdok=$userIdok');
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
    print('oi678${orderInfo}');
    switch (_currentPage) {
      case 0:
        return const MyAppI1();
      case 1:
        if (orderInfo != null && orderInfo['result'] == true) {
          return OrderExecutionScreenzak(
            userId: orderInfo['user_id'],
            orderId: orderInfo['order_id'],
            showBottomNav: false,
          );
        } else {
          return const SearchFormisp(); // Ads1App();
        }
      case 2:
        // return const outputobzlikes(nameImg: '', base: 1);
        ///case 3:
        return const zprofil_name();
      default:
        return const MyAppI1z();
    }
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
    if (userIdok == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: checkOrderStatus(userIdok!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orderInfo = snapshot.data!;
        hasActiveOrder =
            orderInfo['result'] == true; // Проверяем наличие активной записи
        print('res: ${orderInfo['result']}');

        return Scaffold(
          body: Column(
            children: <Widget>[
              Expanded(child: _getScreen(orderInfo)),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.fire_truck),
                label: 'Услуги',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.subject,
                  color: hasActiveOrder
                      ? Colors.red
                      : null, // Меняем цвет иконки на красный, если есть активная запись
                ),
                label: 'Заказы',
              ),
              /*
              const BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Исполнители',
              ),
         
         */
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Профиль',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentPage,
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
      },
    );
  }
}
