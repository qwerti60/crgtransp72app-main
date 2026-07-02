import 'dart:typed_data';

import 'package:crgtransp72app/pages/SendReviewForm.dart';
import 'package:crgtransp72app/pages/list_predloj_na_zayavki.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/pages/subscription_screen.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';

import '../navigation/shell_bottom_nav_spec.dart';
import '../pages/ads1.dart';
import '../pages/history_isp.dart';

class HistortScreen1 extends StatelessWidget {
  final String? pageProfile;
  final String? userId1;
  final String? orderId;
  final String? parsedUserIdOk;

  const HistortScreen1({
    super.key,
    required this.pageProfile,
    required this.userId1,
    required this.orderId,
    required this.parsedUserIdOk,
  });

  @override
  Widget build(BuildContext context) {
    uid = userId1 ?? '';
    oid = orderId ?? '';
    uidok = parsedUserIdOk ?? '';
    bd = int.tryParse(orderId ?? '') ?? 0;

    final navIndex = ShellTabBodyIds.performerProfileRouteTabIndex(
      pageProfile ?? '',
    );

    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => buildProfilePage(
              pageProfile!,
              userId1,
              orderId,
              parsedUserIdOk!,
            ),
            settings: settings,
          );
        },
      ),
      bottomNavigationBar: PerformerBottomNav(currentIndex: navIndex),
    );
  }
}

Widget buildProfilePage(
    String pageProfile, userId1, orderId123, String uidok) {
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld(showBottomNav: false);
    case 'Ads1App':
      return const Ads1Page();
    case 'zprofil_zayavki':
      return const zprofil_zayavki(nameImg: '', base: 1);
    case 'hist':
      return history_isp(nameImg: orderid123, bd: 1);
    case 'SendReviewForm':
      return SendReviewForm(
        currentUserId: userId1,
        targetUserId: orderId123,
        parsedUserIdOk: int.parse(uidok),
      );
    case 'Subscription':
      return const SubscriptionScreen();
    case 'list_predloj_na_zayavki':
      return list_predloj_na_zayavki(
        nameImg: userId1?.toString() ?? '',
        bd: int.tryParse(orderId123?.toString() ?? '') ?? 0,
      );
    case 'SearchForm':
      return outputobz(
        nameImg: userId1,
        city: orderId123,
        showBottomNav: false,
      );
    default:
      return const SizedBox.shrink();
  }
}

String orderid123 = '';
bool isSwitched = false;
Uint8List? fotouser;
String firstName = '';
String lastName = '';
String middleName = '';
String city = '';
String phone = '';
String email = '';
int userId1 = 0;
int userId123 = 0;
String uid = '';
String oid = '';
String uidok = '';
int bd = 0;
