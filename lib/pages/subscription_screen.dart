import 'dart:convert';
import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../design/colors.dart'; // Убедитесь, что этот файл существует с определениями цветов

int userId = 0;

enum PaymentType { perHour, perKilometer, perShift }

enum PaymentType1 { perNal, perKard }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  SubscriptionForm createState() => SubscriptionForm();
}

class SubscriptionForm extends State<SubscriptionScreen> {
  PaymentType selectedPaymentType = PaymentType.perHour;
  PaymentType1 selectedPaymentType1 = PaymentType1.perNal;

  Future fetchSubscriptionInfo(int userId) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/get_subscribe_data.php',
        queryParameters: {
          'iduser': userId.toString(),
        },
      ),
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      return responseData['message'];
    } else {
      throw Exception('Failed to load subscription info');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Ждем получение токена
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
        // Обновляем состояние класса и UI
        setState(() {
          userId = data['idusers'];
        });
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  bool checkIfValidDate(String dateStr) {
    DateTime now = DateTime.now();
    DateTime parsedDate =
        DateTime.tryParse(dateStr) ?? now.add(Duration(days: -1));
    return parsedDate.isAfter(now) || parsedDate.isAtSameMomentAs(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Подписка',
          style: TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: FutureBuilder(
        future: fetchSubscriptionInfo(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else {
            String message = snapshot.data ?? '';
            bool hasValidDate = false;
            late DateTime validDate;

            if (message.contains('оформлена')) {
              int startIndex = message.indexOf('до ');
              if (startIndex >= 0) {
                String dateStr = message.substring(startIndex + 3).trim();
                validDate = DateTime.tryParse(dateStr) ??
                    DateTime.now().add(Duration(days: -1));
                hasValidDate = checkIfValidDate(dateStr);
              }
            }
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Порядок оплаты',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            );
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: DropdownButton<PaymentType1>(
                  value: selectedPaymentType1,
                  hint: const Text('Выберите способ расчета'),
                  dropdownColor: Colors.grey.shade300,
                  onChanged: (PaymentType1? newValue1) {
                    if (newValue1 != null) {
                      setState(() {
                        selectedPaymentType1 = newValue1;
                      });
                    }
                  },
                  isExpanded: false,
                  items: PaymentType1.values.map((PaymentType1 type1) {
                    return DropdownMenuItem<PaymentType1>(
                      value:
                          type1, // Возвращаемся к использованию объектов перечисления
                      child: Text(getLabelForPaymentMoney(type1)),
                    );
                  }).toList(),
                )),
                Center(
                    child: DropdownButton<PaymentType>(
                  value: selectedPaymentType,
                  hint: const Text('Выберите вид расчета'),
                  dropdownColor: Colors.grey.shade300,
                  onChanged: (PaymentType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedPaymentType = newValue;
                      });
                    }
                  },
                  isExpanded: false,
                  items: PaymentType.values.map((PaymentType type) {
                    return DropdownMenuItem<PaymentType>(
                      value:
                          type, // Возвращаемся к использованию объектов перечисления
                      child: Text(getLabelForPaymentType(type)),
                    );
                  }).toList(),
                )),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      uploadData(
                        context: context, // добавляем контекст
                        userID: userId,
                        selectedPaymentType: selectedPaymentType,
                        selectedPaymentType1: selectedPaymentType1,
                      ); // Здесь должна быть логика сохранения выбранной опции
                      print('Selected payment type: $selectedPaymentType');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.withOpacity(0.38),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Сохранить'),
                  ),
                ),
                const SizedBox(height: 60),
                Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
//                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: ElevatedButton(
                    onPressed: hasValidDate
                        ? () {
                            _showRenewSubscriptionDialog(context);
                          }
                        : () {
                            _showRenewSubscriptionDialog(context);
                          },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.withOpacity(0.38),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: Text(hasValidDate
                        ? 'Продлить подписку'
                        : 'Оформить подписку'),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: ElevatedButton(
                    onPressed: hasValidDate &&
                            (validDate.difference(DateTime.now()).inDays >= 0)
                        ? () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MyAppZakazScreen()));
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.withOpacity(0.38),
                      disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('Продолжить'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showRenewSubscriptionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Продлить подписку'),
          content: const Text(
              'Вы уверены, что хотите продлить подписку на 30 дней?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  await renewSubscription(
                      userId); // Вызываем обновление подписки
                  Navigator.of(context).pop(); // Закрываем диалог
                  setState(() {
                    fetchSubscriptionInfo(userId);
                  });
                } catch (e) {
                  print(e); // Выводим ошибку, если что-то пошло не так
                }
              },
              child: const Text('Да'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Просто закрывает диалог
              },
              child: const Text('Нет'),
            ),
          ],
        );
      },
    );
  }
}

String? selectedPaymentType = '';
String? selectedPaymentType1 = '';

Future<void> renewSubscription(int userID) async {
  var url = Uri.parse('${Config.baseUrl}/api/subscribe_new.php');
  var response = await http.post(url, body: {'iduser': userID.toString()});

  if (response.statusCode == 200) {
    var jsonResponse = jsonDecode(response.body);
    print('Ответ от сервера: $jsonResponse');
  } else {
    throw Exception('Failed to renew subscription.');
  }
}

String getLabelForPaymentType(PaymentType type) {
  switch (type) {
    case PaymentType.perHour:
      return 'За час';
    case PaymentType.perKilometer:
      return 'За километр';
    case PaymentType.perShift:
      return 'За смену';
  }
}

String getLabelForPaymentMoney(PaymentType1 type1) {
  switch (type1) {
    case PaymentType1.perNal:
      return 'Наличными';
    case PaymentType1.perKard:
      return 'Картой';
  }
}

// 1. Обновлённая сигнатура
Future<void> uploadData({
  required BuildContext context,
  required int userID,
  required PaymentType selectedPaymentType,
  required PaymentType1 selectedPaymentType1,
}) async {
  final uri = Uri.parse('http://ivnovav.ru/api/updatePayment.php');

  try {
    final response = await http.post(uri, body: {
      'idusers': userID.toString(),
      'payment': getLabelForPaymentType(selectedPaymentType),
      'typepayment': getLabelForPaymentMoney(selectedPaymentType1),
    });

    if (response.statusCode == 200) {
      _showSnack(context, 'Данные успешно загружены!');
      // _showDialog(context, 'Успех', 'Данные успешно загружены!');
    } else {
      _showSnack(
          context, 'Ошибка загрузки: ${response.statusCode}\n${response.body}');
      // _showDialog(context, 'Ошибка',
      //     'Код: ${response.statusCode}\n${response.body}');
    }
  } catch (err) {
    _showSnack(context, 'Ошибка сети: $err');
    // _showDialog(context, 'Ошибка сети', err.toString());
  }
}

/* ---------------------- Вспомогательные методы ---------------------- */

// SnackBar
void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// AlertDialog (если хочется всплывающего окна а-ля «окно»)
void _showDialog(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ок'),
        ),
      ],
    ),
  );
}
