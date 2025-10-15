import 'package:flutter/material.dart';

import '../design/colors.dart';

//import 'reguser2_page_.dart';

// Step 1.
String dropdownValue = 'Абатское';

class profil_transport extends StatefulWidget {
  const profil_transport({super.key});

  @override
  profil_nameForm createState() => profil_nameForm();
}

class profil_nameForm extends State<profil_transport> {
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: TexticonsColor,
                ),
                onPressed: () {},
                child: const Text('Транспорт'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: TexticonsColor,
                ),
                onPressed: () {},
                child: const Text('Mercedes'),
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
                    child: const Text('Добавить транспорт')),
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
