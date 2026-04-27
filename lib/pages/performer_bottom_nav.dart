import 'package:crgtransp72app/pages/ads1.dart';
import 'package:crgtransp72app/pages/get_vt.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:crgtransp72app/pages/zprofil_page.dart';
import 'package:flutter/material.dart';

class PerformerBottomNav extends StatelessWidget {
  final int currentIndex;

  const PerformerBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fire_truck),
          label: 'Объявления',
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
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MyAppI1z(),
            ),
          );
          return;
        }

        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const Ads1App(),
            ),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HistortScreen(pageProfile: 'profileMain'),
          ),
        );
      },
    );
  }
}
