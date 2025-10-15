import 'package:flutter/material.dart';

import '../design/colors.dart';
import 'vod_zak3.dart';

String dropdownValue = 'Абатское';

class vod_zak2 extends StatefulWidget {
  const vod_zak2({super.key});

  @override
  vod_zak2Form createState() => vod_zak2Form();
}

class vod_zak2Form extends State<vod_zak2> {
  var _currentPage = 0;
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(170.0), // Высота AppBar
          child: AppBar(
            backgroundColor: violetColor,
            flexibleSpace: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        fillColor: whiteprColor,
                        filled: true,
                        hintText: 'Искать...',
                        suffixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0), // Расстояние между строками
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
// Действие для кнопки "Фильтр"
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: whiteprColor,
                              backgroundColor: darkvioletColor,
                              disabledForegroundColor: whiteprColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Создать заказ"),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
// Действие для кнопки "Мои заказы"
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: blackprColor,
                              backgroundColor: whiteprColor,
                              disabledForegroundColor: whiteprColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: const Text("Мои заказы"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                      // Первый текст выровнен слева
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Санкт-Петербург'),
                        ),
                      ),
                      // Картинка выровнена по центру
                      Image.asset(
                        'assets/images/strelkaleftblue.png', // путь к изображению
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
                      Text("Выгрузка 17.04.24"),
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
                      Text("703 км"),
                      Text("56 240 р."),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                margin: const EdgeInsets.only(top: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      fixedSize: const Size(double.infinity, 50),
                      foregroundColor: whiteprColor,
                      backgroundColor: violetColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const vod_zak3()));
                    },
                    child: const Text('Груз водителя 3'),
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
              icon: Icon(Icons.history),
              label: 'История',
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
      ),
    );
  }
}
