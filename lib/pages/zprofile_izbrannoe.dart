import 'package:flutter/material.dart';

import '../design/colors.dart';

class zprofile_izbrannoe extends StatefulWidget {
  const zprofile_izbrannoe({super.key});

  @override
  zprofile_izbrannoeForm createState() => zprofile_izbrannoeForm();
}

class zprofile_izbrannoeForm extends State<zprofile_izbrannoe> {
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
              'Избранное',
              style: TextStyle(color: whiteprColor, fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      "№04294354",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite,
                          color: violetColor), // Иконка лайка
                      onPressed: () {
                        // Действие при нажатии иконки
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/star.png', // путь к изображению
                    ),
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('4.2'),
                      ),
                    ),
                    // Картинка выровнена по центру
                    // Второй текст выровнен справа
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Отзывы 78'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Владимир'),
                      ),
                    ),
                    // Картинка выровнена по центру
                    // Второй текст выровнен справа
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(' 76 р./км'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      "№04294354",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite,
                          color: violetColor), // Иконка лайка
                      onPressed: () {
                        // Действие при нажатии иконки
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/star.png', // путь к изображению
                    ),
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('4.2'),
                      ),
                    ),
                    // Картинка выровнена по центру
                    // Второй текст выровнен справа
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('Отзывы 78'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Владимир'),
                      ),
                    ),
                    // Картинка выровнена по центру
                    // Второй текст выровнен справа
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(' 76 р./км'),
                      ),
                    ),
                  ],
                ),
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
