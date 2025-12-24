import 'package:flutter/material.dart';
import '../design/colors.dart'; // Импортируем цвета дизайна

class CustomBottomNavigationBar extends StatelessWidget {
  final Function(int)? onTabSelected; // Callback-функция для обработки кликов
  final int currentIndex; // Индекс текущего выбранного элемента

  const CustomBottomNavigationBar({
    Key? key,
    required this.onTabSelected,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.fire_truck),
          label: 'Объявления',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.subject),
          label: 'Заявки',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Заказчики',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.account_circle,
            color: currentIndex == 3
                ? violetColor // Если выбран профиль, выделяем фиолетовым цветом
                : null,
          ),
          label: 'Профиль',
        ),
      ],
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedIconTheme: const IconThemeData(color: violetColor),
      unselectedIconTheme: const IconThemeData(color: Colors.black87),
      onTap: (index) {
        onTabSelected?.call(index); // Передача события нажатия
      },
    );
  }
}
