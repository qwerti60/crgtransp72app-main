import 'package:flutter/material.dart';

void main() {
  runApp(const MyAppImg());
}

class MyAppImg extends StatelessWidget {
  const MyAppImg({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          // Center виджет для центрирования изображения
          child: Image.asset(
            'assets/images/fotouser.png', // Путь к вашему изображению
            width: 100, // Ширина 100
            height: 100, // Высота 100
          ),
        ),
      ),
    );
  }
}
