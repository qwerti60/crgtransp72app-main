import 'package:flutter/material.dart';

import '../design/colors.dart';

class profile_izbrannoe extends StatefulWidget {
  const profile_izbrannoe({super.key});

  @override
  profile_izbrannoeForm createState() => profile_izbrannoeForm();
}

class profile_izbrannoeForm extends State<profile_izbrannoe> {
  // var _currentPage = 0;
  var _currentPage = 0;
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GreenColor,
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
                          color: GreenColor), // Иконка лайка
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
                    Text("Загрузка 13.04.24 "),
                    Text("Выгрузка 17.04"),
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
                    Text("Исполнитель:"),
                    Text("Вы не выбрали"),
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
                          color: GreenColor), // Иконка лайка
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
                    Text("Загрузка 13.04.24 "),
                    Text("Выгрузка 17.04"),
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
                    Text("Исполнитель:"),
                    Text("Владимир"),
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
            icon: Icon(Icons.account_circle),
            label: 'Профиль',
          ),
        ],
        currentIndex: _currentPage,
        fixedColor: GreenColor,
        onTap: (int intIndex) {
          setState(() {
            _currentPage = intIndex;
          });
        },
      ),
    );
  }
}
