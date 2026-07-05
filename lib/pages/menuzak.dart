import 'dart:typed_data';

import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/history_zak.dart';
import 'package:crgtransp72app/pages/outputobzlikes.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../navigation/shell_bottom_nav_spec.dart';

class MenuzakScreen extends StatelessWidget {
  const MenuzakScreen({
    super.key,
    required this.pageProfile,
  });

  final String pageProfile;

  @override
  Widget build(BuildContext context) {
    final navIndex =
        ShellTabBodyIds.customerProfileRouteTabIndex(pageProfile);

    return Scaffold(
      backgroundColor: whiteprColor,
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => buildProfilePage(pageProfile),
            settings: settings,
          );
        },
      ),
      bottomNavigationBar: CustomerBottomNav(currentIndex: navIndex),
    );
  }
}

Widget buildProfilePage(String pageProfile) {
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld(showBottomNav: false);
    case 'Ads2App':
      return const Ads2Page();
    case 'outputobzlikes':
      return const outputobzlikes(nameImg: '', base: 1);
    case 'hist':
      return const history_zak(nameImg: '', bd: 1);
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
