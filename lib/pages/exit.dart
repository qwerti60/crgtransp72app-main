import 'package:flutter/material.dart';

class CustomLayout extends StatelessWidget {
  const CustomLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Левая часть с вертикальной линией и точками
        Stack(
          alignment: Alignment.center,
          children: [
            // Вертикальная линия
            Container(
              width: 2,
              height:
                  100, // Высота подбирается в зависимости от содержания и желаемого вида
              color: Colors.black,
            ),
            // Серая точка сверху
            Positioned(
              top: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
              ),
            ),
            // Горизонтальная точка снизу
            Positioned(
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10), // Отступ между линией и текстом
        // Правая часть с фразами
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Прибытие"),
                    Text("17.04"),
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
                    Text("Москва"),
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
                    Text("Отправление"),
                    Text("13.04"),
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
                    Text("Санкт-Петербург"),
                    Text("14:40"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CustomRow extends StatelessWidget {
  final String leftText;
  final String rightText;

  const CustomRow({super.key, required this.leftText, required this.rightText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(leftText),
          Text(rightText),
        ],
      ),
    );
  }
}
