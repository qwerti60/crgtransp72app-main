import 'package:crgtransp72app/pages/ads1.dart';
import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/outputobzlikes1.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';

import '../design/colors.dart';
import 'get_vt.dart';
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
    return const MaterialApp(
      home: MyCustomScreen(),
    );
  }
}

// Преобразуем StatelessWidget в StatefulWidget
class MyCustomScreen extends StatefulWidget {
  const MyCustomScreen({super.key});

  @override
  _MyCustomScreenState createState() => _MyCustomScreenState();
}

class _MyCustomScreenState extends State {
  int _currentPage = 0; // Допустимо для StatefulWidget
  Widget _getScreen() {
    switch (_currentPage) {
      case 0:
// Вместо возвращения MyApp, возможно, вы захотите показать другой стартовый экран
        return const MyAppI1z(); // Поменяйте это на подходящий виджет
      case 1:
        return const Ads1App();
      case 2:
        return const zprofil_zayavki(
          nameImg: '',
          base: 1,
        ); //водители
      case 3:
        return const zprofil_name2();
      default:
        return const MyAppI1z(); // Теперь исправлено на правильный вызов
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: _getScreen(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fire_truck),
            label: 'Объявления',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subject),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Заказчики',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Профиль',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentPage,
        selectedIconTheme: const IconThemeData(
            color: violetColor), // Обновлено для актуальных версий Flutter
        onTap: (int intIndex) {
          setState(() {
            _currentPage = intIndex;
          });
        },
      ),
    );
  }
}
