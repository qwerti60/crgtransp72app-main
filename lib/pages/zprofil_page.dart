import 'dart:typed_data';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/chat_list_screen.dart';
import 'package:crgtransp72app/widgets/chat_auth_guard.dart';
import 'package:crgtransp72app/pages/PaymentPage.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/history_isp.dart';
import 'package:crgtransp72app/pages/menuzak.dart';
import 'package:crgtransp72app/pages/outputobzlikes.dart';
import 'package:crgtransp72app/pages/subscription_screen.dart';
import 'package:crgtransp72app/pages/zakaz_screen1.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';

import '../design/colors.dart';
import '../widgets/profile_rating_row.dart';
import 'account_deletion.dart';
import 'ads2.dart';
import 'change_user.dart';
import 'rent_z.dart';
import 'zprofil_ld.dart';
import 'zprofil_zakaz.dart';
import 'zprofile_izbrannoe.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class zprofil_name extends StatefulWidget {
  const zprofil_name({super.key});

  @override
  zprofil_nameForm createState() => zprofil_nameForm();
}

class zprofil_nameForm extends State<zprofil_name> {
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
  double avgRating = 0;
  int reviewsCount = 0;
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<bool?> checkSubscription(int userId) async {
    final response = await http.post(
      Uri.parse(
          '${Config.baseUrl}/api/check_subscription.php?iduser=$userId'), // Adding userId as a query parameter
      // Note: Since you are sending the userId in the URL, you do not need to include it in the body again
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data['status']);
      if (data['status'] == 'active') {
        return true;
      } else if (data['status'] == 'expired' || data['status'] == 'not_found') {
        return false;
      }
    }
    return null; // It might be good to return null or handle errors if the response status code isn't 200, indicating an issue with the request
  }

  void navigateIfNeeded(BuildContext context, int userId) async {
    final subscriptionStatus = await checkSubscription(userId);
    if (subscriptionStatus == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MyAppZakazScreen()),
        (Route<dynamic> route) => false,
      );
      //  Navigator.push(
      //    context, MaterialPageRoute(builder: (_) => const MyAppZakazScreen()));
    } else if (subscriptionStatus == false) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Подписка"),
            content: const Text(
                "Ваша подписка неактивна. Оформите подписку для доступа."),
            actions: [
              TextButton(
                child: const Text("Оформить"),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PaymentScreen()));
                },
              ),
            ],
          );
        },
      );
    }

    // Здесь может быть ваша логика перехода на экран оформления/продления подписки
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          userId = data['idusers'];
          firstName = data['firstName'];
          lastName = data['lastName'];
          middleName = data['middleName'];
          city = data['city'];
          phone = data['phone'];
          email = data['email'];
          // Проверяем, есть ли изображение пользователя и преобразуем его из base64.
          fotouser =
              data['fotouser'] != null ? base64Decode(data['fotouser']) : null;
          final rating = ProfileRatingRow.fromApiMap(
            Map<String, dynamic>.from(data),
          );
          avgRating = rating.avgRating;
          reviewsCount = rating.reviewsCount;
        });

        // Теперь переменные firstName, lastName, middleName, и userfoto доступны для использования в build() методе.
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image:
                      AssetImage("assets/images/bgcolor_head_blue_white.png"),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                // Центрируем изображение
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: fotouser != null
                      ? Image.memory(
                          fotouser!,
                          // fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Ошибка при загрузке изображения: $error');
                            // Возвращает виджет, который отображается в случае ошибки
                            return Icon(Icons.error);
                          },
                        )
                      : Image.asset(
                          'assets/images/fotouser.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                'Ошибка при загрузке изображения из ассетов: $error');
                            // Возвращает виджет, который отображается в случае ошибки
                            return Icon(Icons.error);
                          },
                        ),
                ),
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
                onTap: () => ProfileRatingRow.openCustomerReviews(
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
                    print('[zprofil_page] tap: Избранное');
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MenuzakScreen(
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const MenuzakScreen(pageProfile: 'Ads2App')));
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const zprofil_zakaz(
                          nameImg: '',
                          base: 1,
                          useCustomerMenu: true,
                        ),
                      ),
                    );
                  },
                  child: const Text('Заявки')),
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
                                OutputobzlikesPage(nameImg: '', base: 1)));
                  },
                  child: const Text('Избранное')),
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
                                const MenuzakScreen(pageProfile: 'hist')));
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
                        ),
                      ),
                    );
                  },
                  child: const Text('Чаты с исполнителями')),
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
                        ),
                      ),
                    );
                  },
                  child: const Text('Поддержка')),
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
                    if (userId > 0) {
                      navigateIfNeeded(context, userId);
                      return;
                    }

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => MyAppZakazScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text('Стать грузоперевозчиком'),
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
                  MaterialPageRoute(builder: (_) => const MyApp(initialPage: 0)),
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
