import 'package:flutter/material.dart';

import '../design/colors.dart';

import 'exit.dart';

class zprofil_m extends StatefulWidget {
  const zprofil_m({super.key});

  @override
  zprofil_mForm createState() => zprofil_mForm();
}

class zprofil_mForm extends State<zprofil_m> {
  // var _currentPage = 0;
  var _currentPage = 0;
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: violetColor,
        iconTheme: const IconThemeData(color: whiteprColor),
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Маршрут и груз',
              style: TextStyle(color: whiteprColor, fontSize: 18),
            ),
            Text(
              '№04294354',
              style: TextStyle(color: whiteprColor, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white), // Иконка лайка
            onPressed: () {
              // Действие при нажатии иконки
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    // Первый текст выровнен слева
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Санкт-Петербург'),
                      ),
                    ),
                    // Картинка выровнена по центру
                    Image.asset(
                      'assets/images/strelkaleft.png', // путь к изображению
                    ),
                    // Второй текст выровнен справа
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Москва'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Описание: "),
                  ],
                ),
              ),
            ),
            Container(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Строительные материалы на паллетах 20 шт."),
                  ],
                ),
              ),
            ),
            Container(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Статус заказа"),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: const Center(
                child: CustomLayout(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fire_truck),
            label: 'Техника',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subject),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Водители',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Профиль',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentPage,
        fixedColor: violetColor,
        onTap: (int intIndex) {
          setState(() {
            _currentPage = intIndex;
          });
        },
      ),
    );
  }
}
