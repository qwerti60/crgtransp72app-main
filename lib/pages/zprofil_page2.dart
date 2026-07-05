import 'dart:typed_data';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/HistortScreen1z.dart';
import 'package:crgtransp72app/pages/chat_list_screen.dart';
import 'package:crgtransp72app/widgets/chat_auth_guard.dart';
import 'package:crgtransp72app/pages/performer_finances_screen.dart';
import 'package:crgtransp72app/pages/PaymentPage.dart';
import 'package:crgtransp72app/pages/ads2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/history_isp.dart';
import 'package:crgtransp72app/pages/list_predloj_na_obj_isp.dart';
import 'package:crgtransp72app/pages/menuzak.dart';
import 'package:crgtransp72app/pages/outputobzlikes.dart';
import 'package:crgtransp72app/pages/outputobzlikes1.dart';
import 'package:crgtransp72app/pages/scrmenu.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart' show MyApp;
import 'package:crgtransp72app/navigation/performer_active_order.dart';

import '../design/colors.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_rating_row.dart';
import 'account_deletion.dart';
import 'ads1.dart';
import 'change_user.dart';
import 'subscription_screen.dart';
import 'zakaz_screen2.dart';
import 'zprofil_ld.dart';
import 'zprofil_zakaz.dart';
import 'zprofile_izbrannoe.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class zprofil_name2 extends StatefulWidget {
  const zprofil_name2({super.key});

  @override
  zprofil_nameForm createState() => zprofil_nameForm();
}

class zprofil_nameForm extends State<zprofil_name2> {
  final _currentPage = 0;
  bool isSwitched = false;
  Uint8List? fotouser;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  int userId = 0;
  String orderid = '';
  double avgRating = 0;
  int reviewsCount = 0;
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo_order.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          userId = data['idusers'];
          firstName = data['firstName']?.toString() ?? '';
          lastName = data['lastName']?.toString() ?? '';
          middleName = data['middleName']?.toString() ?? '';
          city = data['city']?.toString() ?? '';
          phone = data['phone']?.toString() ?? '';
          email = data['email']?.toString() ?? '';
          // Проверяем, есть ли изображение пользователя и преобразуем его из base64.
          fotouser = decodeUserPhotoFromApi(data['fotouser']);
          orderid = data['order_id']?.toString() ?? '';
          final rating = ProfileRatingRow.fromApiMap(
            Map<String, dynamic>.from(data),
          );
          avgRating = rating.avgRating;
          reviewsCount = rating.reviewsCount;
        });
        print('d123 ${data}');
        print('o123 ${orderid}');
        print('Данные пользователя1: $data');
        // Теперь переменные firstName, lastName, middleName, и userfoto доступны для использования в build() методе.
      }
      print('Данные пользователя2: $data');
    } else {
      print('Ошибка при получении данных пользователя');
      //print('Данные пользователя: $data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ProfileAvatar(
                fotouser: fotouser,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistortScreen(
                        pageProfile: 'zprofil_ld',
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(
                '$firstName $lastName', // Интерполяция используется для вставки значений
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (userId > 0)
              ProfileRatingRow(
                avgRating: avgRating,
                reviewsCount: reviewsCount,
                onTap: () => ProfileRatingRow.openPerformerReviews(
                  context,
                  userId,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HistortScreen(
                                pageProfile: 'zprofil_ld')));
                  },
                  child: const Text('Личные данные')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const HistortScreen(pageProfile: 'Ads1App')));
                  },
                  child: const Text('Мои объявления')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    openPerformerOffersOrActiveOrder(context);
                  },
                  child: const Text('Предложения')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const Outputobzlikes1Page(nameImg: '', base: 1),
                      ),
                    );
                  },
                  child: const Text('Избранные заказчики')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            //history_isp(
                            //  nameImg: userId.toString(),
                            //bd: 1), //
                            HistortScreen(pageProfile: 'hist'),
                      ),
                    );
                  },
                  child: const Text('История заказов')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () async {
                    if (!await ensureChatAuthorized(context)) return;
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatListScreen(
                          showBottomNav: true,
                          isPerformer: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Чаты с заказчиками')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () async {
                    if (!await ensureChatAuthorized(context)) return;
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatListScreen(
                          initialTab: 1,
                          showBottomNav: true,
                          isPerformer: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Поддержка')),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                        builder: (_) => const PerformerFinancesScreen(),
                      ),
                    );
                  },
                  child: const Text('Финансы')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: TexticonsColor,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PaymentScreen() //SubscriptionScreen()
                            ));
                  },
                  child: const Text('Подписка')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 40.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: TexticonsColor,
                ),
                onPressed: () => _showExitConfirmationDialog(context),
                child: const Text('Выйти из аккаунта'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                onPressed: () => showDeleteAccountDialog(context),
                child: const Text('Удалить аккаунт'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    fixedSize: const Size(double.infinity, 50),
                    foregroundColor: whiteprColor,
                    backgroundColor: blueaccentColor,
                    disabledForegroundColor: grayprprColor,
                    shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(3))),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => MyApp()),
                      (Route<dynamic> route) => false,
                    );
                    //                  Navigator.push(context,
                    //                    MaterialPageRoute(builder: (_) => const MyApp()));
                  },
                  child: const Text('Стать заказчиком'),
                ),
              ),
            ),
            // _getScreen(),
          ],
        ),
      ),
    );
  }
}

class _showExitConfirmationDialog {
  _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выход'),
          content: const Text('Вы уверены, что хотите выйти?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Нет'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрыть диалоговое окно
              },
            ),
            TextButton(
              child: const Text('Да'),
              onPressed: () async {
                final pushToken = await getPushFcmToken();
                if (pushToken != null) {
                  try {
                    final response = await http.post(
                      Uri.parse(Config.baseUrl).replace(
                          path: '/api/clear_fcm_token.php'), // URL нашего API
                      body: {
                        'fcm_token': pushToken,
                      },
                      headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                      },
                    );

                    if (response.statusCode == 200) {
                      final result = jsonDecode(response.body);
                      if (result['success'] == true) {
                        print('FCM-token cleared successfully!');
                      } else {
                        print(
                            'Error clearing FCM-token: ${result['message'] ?? 'Unknown Error'}');
                      }
                    } else {
                      print(
                          'API request failed with code: ${response.statusCode}');
                    }
                  } catch (e) {
                    print('Error communicating with API: $e');
                  }
                } else {
                  print('No FCM token available for clearing.');
                }

                await clearAuthToken();
                await clearPushFcmTokenLocal();

                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MyAppZakazScreen(initialPage: 0)),
                  (_) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
