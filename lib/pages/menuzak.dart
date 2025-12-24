import 'dart:typed_data';

import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/get_vt.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/outputobzlikes.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_page.dart';
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
  final List<Widget?> _pages = List.filled(4, null, growable: false);

  late final List<Widget Function()> _builders = [
    () => MyAppI1(),
    () => Ads2App(),
    () => outputobzlikes(nameImg: '', base: 1),
    () => zprofil_name(),
  ];

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
      _pages[index] ??= _builders[index]();
    });
  }

  static Widget buildProfilePage(String pageProfile,
      {required String orderId}) {
    switch (pageProfile) {
      case 'zprofil_ld':
        return const zprofil_ld();
      case 'Ads2App':
        return const Ads2App();
      case 'outputobzlikes':
        return const outputobzlikes(nameImg: '', base: 1);
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
    getUserData();
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
          firstName = data['firstName'];
          lastName = data['lastName'];
          middleName = data['middleName'];
          city = data['city'];
          phone = data['phone'];
          email = data['email'];
          fotouser =
              data['fotouser'] != null ? base64Decode(data['fotouser']) : null;
          orderid = data['order_id'];
        });
      } else {
        throw Exception(
            'Failed to load user data with status code: ${response.statusCode}}');
      }
    } catch (err) {
      print('Error loading user data: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == null
          ? buildProfilePage(widget.pageProfile, orderId: orderid)
          : _pages[_currentIndex!],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex ?? 0,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.fire_truck), label: 'Услуги'),
          BottomNavigationBarItem(icon: Icon(Icons.subject), label: 'Заказы'),
          BottomNavigationBarItem(
              icon: Icon(Icons.group), label: 'Исполнители'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Профиль'),
        ],
      ),
    );
  }
}
