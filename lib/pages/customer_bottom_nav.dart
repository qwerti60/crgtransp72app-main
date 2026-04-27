import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';

class CustomerBottomNav extends StatelessWidget {
  final int currentIndex;

  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedIconTheme: const IconThemeData(color: violetColor),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fire_truck),
          label: 'Объявления',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.subject),
          label: 'Заявки',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Профиль',
        ),
      ],
      onTap: (index) {
        if (index == 0 || index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MyCustomScreen(initialPage: index),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MyCustomScreen(initialPage: 2),
          ),
        );
      },
    );
  }
}
