import 'package:flutter/material.dart';

import '../design/colors.dart';
import 'gruz_vodit5.dart';

//import 'reguser2_page_.dart';

// Step 1.
String dropdownValue = 'Абатское';

class gruz_vodit4 extends StatefulWidget {
  const gruz_vodit4({super.key});

  @override
  gruz_vodit4Form createState() => gruz_vodit4Form();
}

class gruz_vodit4Form extends State<gruz_vodit4> {
  var _currentPage = 0;
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: GreenColor,
          iconTheme: const IconThemeData(color: whiteprColor),
          centerTitle: true,
          title: const Column(
            children: [
              Text(
                'Отклик на заказ',
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
              icon:
                  const Icon(Icons.delete, color: Colors.white), // Иконка лайка
              onPressed: () {
                // Действие при нажатии иконки
              },
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: whiteprColor,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
                      Text("Загрузка 13.04.24 "),
                      Text("с 10:00 до 18:00"),
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
                      Text("Выгрузка 17.04.24"),
                      Text("с 10:00 до 18:00"),
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
                      Text("Цена за перевозку"),
                      Text("44 444"),
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
                      Text("Время перевозки, дней"),
                      Text("4"),
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
                      Text("Транспорт"),
                      Text("Добавить"),
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
                      Text("Оплата"),
                      Text("Не выбрано"),
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
                      backgroundColor: GreenColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () {},
                    child: const Text('Оставить заявку'),
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
                      backgroundColor: GreenColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const gruz_vodit5()));
                    },
                    child: const Text('Груз водителя 4'),
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
          fixedColor: GreenColor,
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
