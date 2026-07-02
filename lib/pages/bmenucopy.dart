import 'dart:typed_data';

import 'package:crgtransp72app/pages/SendReviewFormzakaz.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/pages/subscription_screen.dart';
import 'package:flutter/material.dart';

import '../navigation/shell_bottom_nav_spec.dart';

class HistortScreen12z extends StatelessWidget {
  final String pageProfile;
  final String userId1;
  final String orderId;
  final String parsedUserIdOk;

  const HistortScreen12z({
    super.key,
    required this.pageProfile,
    required this.userId1,
    required this.orderId,
    required this.parsedUserIdOk,
  });

  @override
  Widget build(BuildContext context) {
    final navIndex =
        ShellTabBodyIds.performerProfileRouteTabIndex(pageProfile);

    return Scaffold(
      body: buildProfilePage(
        pageProfile,
        userId1,
        orderId,
        parsedUserIdOk,
      ),
      bottomNavigationBar: PerformerBottomNav(currentIndex: navIndex),
    );
  }
}

Widget buildProfilePage(
    String pageProfile, String userId1, String orderId, String parsedUserIdOk) {
  switch (pageProfile) {
    case 'SearchForm':
      return outputobz(
        nameImg: orderId,
        city: userId1,
        showBottomNav: false,
      );
    case 'SendReviewForm':
      return SendReviewFormzakaz(
        currentUserId: userId1,
        targetUserId: orderId,
        parsedUserIdOk: int.parse(parsedUserIdOk),
      );
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
