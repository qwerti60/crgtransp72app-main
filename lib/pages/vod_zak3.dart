import 'package:flutter/material.dart';

import '../design/colors.dart';
import 'vod_zak4.dart';

String dropdownValue = 'Абатское';

class vod_zak3 extends StatefulWidget {
  const vod_zak3({super.key});

  @override
  vod_zak3Form createState() => vod_zak3Form();
}

class vod_zak3Form extends State<vod_zak3> {
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
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
// Действие для кнопки "Мои заказы"
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Откуда',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Страна',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Область',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Город',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Адрес',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Куда',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Страна',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Область',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Город',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Адрес',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Условия',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Грузчики',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Вид кузова',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Тип перевозки',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Тип загрузки',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Контакты',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Имя',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Телефон',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Способ оплаты',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Цена, до',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'О заказе',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 10.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                      borderSide: BorderSide(color: blueaccentColor),
                    ),
                    fillColor: grayprprColor,
                    filled: true,
                    hintText: 'Текст',
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                margin: const EdgeInsets.only(top: 5.0),
                child: const Text(
                  'Фото груза',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black38,
                    fontSize: 16.0,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Container(
                child: Image.asset(
                  'assets/images/plas.png', // путь к изображению
                  width: 189, // ширина изображения
                  height: 119, // высота изображения
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
                    onPressed: () {},
                    child: const Text('Опубликовать заказ'),
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
                          MaterialPageRoute(builder: (_) => const vod_zak4()));
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
