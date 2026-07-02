import 'dart:typed_data';

import 'package:crgtransp72app/pages/SendReviewFormzakaz.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/history_zak.dart';
import 'package:crgtransp72app/pages/list_predloj_na_obj_isp.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/zprofil_ld.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';

import '../navigation/shell_bottom_nav_spec.dart';
import '../pages/ads1.dart';
import '../pages/subscription_screen.dart';

class HistortScreen1z extends StatelessWidget {
  final String pageProfile;
  final String userId1;
  final String orderId;
  final String parsedUserIdOk;
  final int? adBd;

  const HistortScreen1z({
    super.key,
    required this.pageProfile,
    required this.userId1,
    required this.orderId,
    required this.parsedUserIdOk,
    this.adBd,
  });

  @override
  Widget build(BuildContext context) {
    uid = userId1;
    oid = orderId;
    uidok = parsedUserIdOk;

    final navIndex =
        ShellTabBodyIds.customerProfileRouteTabIndex(pageProfile);

    return Scaffold(
      body: buildProfilePage(
        pageProfile,
        userId1,
        orderId,
        parsedUserIdOk,
        adBd: adBd,
      ),
      bottomNavigationBar: CustomerBottomNav(currentIndex: navIndex),
    );
  }
}

Widget buildProfilePage(
    String pageProfile, userId1, orderId123, String uidok,
    {int? adBd}) {
  switch (pageProfile) {
    case 'zprofil_ld':
      return const zprofil_ld(showBottomNav: false);
    case 'Ads1App':
      return const Ads1Page();
    case 'zprofil_zayavki':
      return const zprofil_zayavki(nameImg: '', base: 1, useCustomerMenu: false);
    case 'hist':
      return history_zak(nameImg: orderId123, bd: 1);
    case 'SendReviewForm':
      return SendReviewFormzakaz(
        currentUserId: userId1,
        targetUserId: orderId123,
        parsedUserIdOk: int.parse(uidok),
      );
    case 'Subscription':
      return const SubscriptionScreen();
    case 'SearchForm':
      return outputobz(
        nameImg: uid,
        city: oid,
        showBottomNav: false,
      );
    case 'list_predloj_na_obj_isp':
      return list_predloj_na_obj_isp(
        nameImg: uid,
        bd: adBd ?? 1,
        useCustomerMenu: false,
        wrapInMaterialApp: false,
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
