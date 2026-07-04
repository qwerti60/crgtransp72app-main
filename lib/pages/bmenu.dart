import 'dart:typed_data';

import 'package:crgtransp72app/pages/history_isp.dart';
import 'package:crgtransp72app/pages/outputobzlikes1.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/pages/subscription_screen.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';

import '../navigation/shell_bottom_nav_spec.dart';
import '../pages/ads1.dart';

class HistortScreen12 extends StatelessWidget {
  const HistortScreen12({
    super.key,
    required this.pageProfile,
  });

  final String pageProfile;

  @override
  Widget build(BuildContext context) {
    final navIndex =
        ShellTabBodyIds.performerProfileRouteTabIndex(pageProfile);

    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => buildProfilePage(pageProfile, orderId: orderid),
            settings: settings,
          );
        },
      ),
      bottomNavigationBar: PerformerBottomNav(currentIndex: navIndex),
    );
  }
}

Widget buildProfilePage(String pageProfile, {required String orderId}) {
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld(showBottomNav: false, isPerformerProfile: true);
    case 'Ads1App':
      return const Ads1Page();
    case 'zprofil_zayavki':
      return const zprofil_zayavki(nameImg: '', base: 1);
    case 'hist':
      return history_isp(nameImg: orderId, bd: 1);
    case 'izbrannoe':
      return outputobzlikes1(nameImg: '', base: 1);
    case 'Subscription':
      return const SubscriptionScreen();
    default:
      return const SizedBox.shrink();
  }
}

String orderid = '';
bool isSwitched = false;
Uint8List? fotouser;
String firstName = '';
String lastName = '';
String middleName = '';
String city = '';
String phone = '';
String email = '';
int userId = 0;
