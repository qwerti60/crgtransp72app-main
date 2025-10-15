import 'package:flutter/material.dart';

import '../design/colors.dart';
import 'vod_zak1.dart';

//import 'reguser2_page_.dart';

// Step 1.
String dropdownValue = 'Абатское';

class vod_zak extends StatefulWidget {
  const vod_zak({super.key});

  @override
  vod_zakForm createState() => vod_zakForm();
}

class vod_zakForm extends State<vod_zak> {
  final _currentPage = 0;
  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(130.0), // Высота AppBar
          child: AppBar(
            backgroundColor: violetColor,
            flexibleSpace: const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
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
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Кузов:"),
                      Text("Тентованный"),
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
                      Text("Вес:"),
                      Text("20 т."),
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
                      Text("Объём:"),
                      Text("83 м^3"),
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
                      Text("Прицеп:"),
                      Text(
                        "Полуприцеп",
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
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Владимир"),
                      Text(
                        " 76 р./км",
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
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Кузов:"),
                      Text("Тентованный"),
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
                      Text("Вес:"),
                      Text("20 т."),
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
                      Text("Объём:"),
                      Text("83 м^3"),
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
                      Text("Прицеп:"),
                      Text(
                        "Полуприцеп",
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
                  padding: EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Владимир"),
                      Text(
                        " 76 р./км",
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
                      backgroundColor: violetColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const vod_zak1()));
                    },
                    child: const Text('Заказ водителя 2'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
