import 'package:flutter/material.dart';

class profil_name extends StatefulWidget {
  const profil_name({super.key});

  @override
  profil_nameForm createState() => profil_nameForm();
}

class profil_nameForm extends State<profil_name> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bgcolor_head_green_white.png"),
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
        ),
      ),
    );
  }
}
