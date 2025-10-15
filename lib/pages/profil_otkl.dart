import 'package:flutter/material.dart';

import '../design/colors.dart';
import 'profil_m.dart';

class profil_otkl extends StatefulWidget {
  const profil_otkl({super.key});

  @override
  profil_otklForm createState() => profil_otklForm();
}

class profil_otklForm extends State<profil_otkl> {
  var _currentPage = 0;
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image:
                      AssetImage("assets/images/bgcolor_head_green_white.png"),
                  fit: BoxFit.fill,
                ),
              ),
              child: SizedBox(
                height: 100.0,
                child: Image.asset(
                  'assets/images/fotouser.png', // путь к изображению
                  width: 100, // ширина изображения
                  height: 100, // высота изображения
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Иван Иванов',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
                child: Center(
                    child: SwitchListTile(
              tileColor: whiteprColor,
              activeColor: GreenColor,
              title: const Text('Доступен для заказов'),
              value: isSwitched,
              onChanged: (bool? value) {
                setState(() {
                  isSwitched = value!;
                });
              },
            ))),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Мои отклики',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
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
                    Text("Загрузка 13.04"),
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
                    Text("Не выбран"),
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
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const profil_m()));
                  },
                  child: const Text('Детали...'),
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
                    Text("Загрузка 13.04"),
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
                    Text(
                      "Вы",
                      style: TextStyle(color: GreenColor),
                    ),
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
                    child: const Text('Детали...')),
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
                    Text("Загрузка 13.04"),
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
                    Text(
                      "Найден",
                      style: TextStyle(color: Colors.red),
                    ),
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
                    child: const Text('Детали...')),
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
