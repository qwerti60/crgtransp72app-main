import 'dart:async';
import 'dart:convert';
import 'package:crgtransp72app/pages/SendReviewForm.dart' hide Config;
import 'package:crgtransp72app/pages/change_user.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/history_isp.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';

class OrderExecutionScreen extends StatefulWidget {
  final String userId;
  final String orderId;

  const OrderExecutionScreen(
      {Key? key, required this.userId, required this.orderId})
      : super(key: key);

  @override
  _OrderExecutionScreenState createState() => _OrderExecutionScreenState();
}

class _OrderExecutionScreenState extends State<OrderExecutionScreen> {
  bool isLoading = true; // Используется для отображения индикатора загрузки
  Duration elapsedDuration = Duration.zero;
  Timer? timer;
  String? orderStatus; // Переменная для хранения текущего статуса заказа
  String? formattedDuration;

  @override
  void initState() {
    super
        .initState(); // Assign nameImg from widget to a local variable if needed:

    getUserData();
  }

  String userIdok = '';
  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('https://ivnovav.ru/api/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          userIdok = data['idusers'];
        });
        print('вывод idiok: $userIdok');
        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  String formatDuration(Duration duration) {
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;
    return '$hours ч $minutes мин $seconds сек';
  }

  Future<void> startTimer([DateTime? startDate]) async {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (startDate != null) {
          elapsedDuration = DateTime.now().difference(startDate);
        } else {
          elapsedDuration += const Duration(seconds: 1);
        }
      });
    });
  }

  String? formattedCancelTime;

  Future<void> updateOrderStatus(String newStatus) async {
    final now = DateTime.now(); // Получение текущего времени

    final dio = Dio();
    try {
      final response = await dio.put(
        '${Config.baseUrl}/api/update_order_status.php',
        data: {
          'user_id': widget.userId,
          'order_id': widget.orderId,
          'status': newStatus,
          'current_date_time': now.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        var result = response.data;

        if (result.containsKey('cancel_time')) {
          String formattedCancelTime = formatDate(
              result['cancel_time']); // Форматируем дату в удобочитаемый вид
          showDialog(
            context: context,
            barrierDismissible:
                false, // запрещаем закрытие окна щелчком вне области
            builder: (context) => AlertDialog(
              title: const Text('Отмена заказа'),
              content: Text(
                  'Статус заказа: отменён\nДата и время отмены: $formattedCancelTime'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => history_isp(
                            nameImg: widget.orderId.toString(), bd: 1)));
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          setState(() {
            orderStatus = newStatus;
            timer?.cancel();
          });
        } else if (result.containsKey('duration_seconds')) {
          // Новое условие проверки
          int seconds = result['duration_seconds']; // Берём количество секунд
          Duration duration =
              Duration(seconds: seconds); // Создаем объект Duration
          String hoursMinutes =
              formatDuration(duration); // Преобразуем в удобное представление
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Заказ выполнен'),
              content: Text(
                  'Время выполнения заказа: $hoursMinutes'), // Отображаем продолжительность
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          setState(() {
            orderStatus = newStatus;
            timer?.cancel();
            formattedDuration = hoursMinutes;
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Статус заказа обновлен'),
              content: Text(result['message']), // Сообщение из API
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          setState(() {
            orderStatus = newStatus;
            timer?.cancel();
          });
        }
      } else {
        showErrorSnackbar('Ошибка при изменении статуса заказа.');
      }
    } catch (e) {
      showErrorSnackbar('Ошибка при изменении статуса заказа.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Функция для форматирования даты и времени в читабельный формат
  String formatDate(String isoDate) {
    return DateTime.parse(isoDate)
        .toLocal()
        .toString()
        .split('.')[0]; // Преобразуем дату в удобный формат
  }

  @override
  void dispose() {
    timer?.cancel(); // Остановка таймера при закрытии экрана
    super.dispose();
  }

  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    try {
      final currentDateTime = DateTime.now();
      final formattedDateTime = currentDateTime.toIso8601String();

      final dio = Dio();

      // Логируем переменные перед отправкой запроса
      print('User ID: ${widget.userId.toString()}');
      print('Order ID: ${widget.orderId.toString()}');
      print('Start Time: $formattedDateTime');
      print('User ID OK: ${userId.toString()}');

      final response = await dio.post(
        '${Config.baseUrl}/api/check_order_status.php',
        data: {
          'user_id': widget.userId.toString(),
          'order_id': widget.orderId.toString(),
          'start_time': formattedDateTime,
          'user_idok': userId.toString(),
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );
      if (response.data is Map<String, dynamic>) {
        final message = response.data['message'];
        print('вывод idiok777: $message');
        print('вывод idiok77766: $userId');
        switch (message) {
          case 'Продолжается выполнение':
            final startDateStr = response.data['start_time'];
            final startDate = DateTime.parse(startDateStr);

            // Рассчитываем полную разницу во времени сразу же
            final now = DateTime.now();
            final totalElapsedSeconds = now.difference(startDate).inSeconds;

            // Преобразуем общее количество секунд в часы и минуты
            final hours = totalElapsedSeconds ~/ 3600;
            final minutes = ((totalElapsedSeconds % 3600) / 60).round();

            final durationFormatted = '$hours часа(-ов) $minutes минут(-ы)';

            setState(() {
              formattedDuration = durationFormatted;
            });

            if (timer == null || timer!.tick == 0) {
              print("Перезапускаю таймер");

              // Проверка активности таймера
              startTimer(startDate); // Перезапускаем таймер
            }
            break;

          case 'Запись успешно создана':
            if (timer == null || timer!.tick == 0) {
              // Проверка активности таймера
              startTimer(null); // Запустим пустой таймер без начальной даты
            }
            break;

          case 'Заказ выполнен':
            final startDateStr = response.data['start_time'];
            final endDateStr = response.data['end_time'];

            final startDate = DateTime.parse(startDateStr);
            final endDate = DateTime.parse(endDateStr);

            // Полностью правильная логика расчета времени выполнения
            final durationSeconds = endDate.difference(startDate).inSeconds;
            final hours = durationSeconds ~/ 3600;
            final minutes = ((durationSeconds % 3600) / 60).round();

            final durationFormatted = '$hours часа(-ов) $minutes минута(-ы)';

            setState(() {
              orderStatus = 'выполнен';
              timer?.cancel();
              formattedDuration = durationFormatted;
            });
            break;

          case 'Заказ отменен':
            final cancelDateStr = response.data['cancel_time'];
            final cancelDate = DateTime.parse(cancelDateStr);
            final formattedDate =
                "${cancelDate.day}.${cancelDate.month}.${cancelDate.year} ${cancelDate.hour}:${cancelDate.minute}";

            setState(() {
              orderStatus = 'отменен';
              timer?.cancel();
              formattedCancelTime = formattedDate;
            });
            break;

          default:
            showErrorSnackbar('Неизвестный статус заказа');
        }
      } else {
        showErrorSnackbar('Ошибка формата данных');
      }
    } on DioError catch (e) {
      debugPrint(
          'DioError: ${e.message}\nSTATUS: ${e.response?.statusCode}\nDATA: ${e.response?.data}\nHEADERS: ${e.response?.headers}');
      showErrorSnackbar('Ошибка связи с сервером');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      showErrorSnackbar('Неизвестная ошибка');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Выполнение заказа №${widget.orderId}',
            style: const TextStyle(color: whiteprColor)),
        backgroundColor: blueaccentColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (elapsedDuration > Duration.zero &&
                      (orderStatus == null ||
                          orderStatus == 'Продолжается выполнение'))
                    Column(children: [
                      Text('Время выполнения:',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(formatDuration(elapsedDuration),
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(fontWeight: FontWeight.bold)),
                    ]),
                  if (orderStatus != null &&
                      ['выполнен', 'отменен'].contains(orderStatus))
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Статус заказа: $orderStatus',
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center),
                          if (orderStatus == 'отменен' &&
                              formattedCancelTime != null)
                            Text('Дата и время отмены: $formattedCancelTime',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center),
                          if (orderStatus == 'выполнен' &&
                              formattedDuration != null)
                            Text('Время выполнения: $formattedDuration',
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center),
                          if (orderStatus ==
                              'выполнен') // Добавляем условие вывода кнопки продолжения
                            ElevatedButton(
                              onPressed: () {
                                final parsedUserIdOk = int.tryParse(widget
                                    .orderId); // Пробуем преобразовать строку в int
                                print(
                                    'Current User ID: ${widget.userId.toString()}'); //141
                                print('Target User ID: $userId'); //140
                                print(
                                    'Parsed User ID Ok: $parsedUserIdOk'); //106

                                if (parsedUserIdOk != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SendReviewForm(
                                              currentUserId:
                                                  widget.userId.toString(),
                                              targetUserId: userId.toString(),
                                              parsedUserIdOk: parsedUserIdOk,
                                            )),
                                  );
                                } else {
                                  // Если преобразование не удалось, вывести предупреждение или ошибку
                                  print(
                                      'Ошибка: Невозможно преобразовать "$userIdok" в целое число.');
                                }
                              },
                              child: Text('Оставьте отзыв'),
                            ),
                        ],
                      ),
                    ),
                  if (orderStatus == null ||
                      !['выполнен', 'отменен'].contains(orderStatus))
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              fixedSize: const Size(double.infinity, 50),
                              foregroundColor: whiteprColor,
                              backgroundColor: blueaccentColor,
                              disabledForegroundColor: grayprprColor,
                              shape: const BeveledRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(3))),
                            ),
                            icon: const Icon(Icons.check_circle_outline,
                                color: whiteprColor),
                            label: const Text('Завершить заказ',
                                style: TextStyle(color: whiteprColor)),
                            onPressed: () => updateOrderStatus('выполнен'),
                          ),
                          const Divider(thickness: 1, height: 16),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              fixedSize: const Size(double.infinity, 50),
                              foregroundColor: whiteprColor,
                              backgroundColor: blueaccentColor,
                              disabledForegroundColor: grayprprColor,
                              shape: const BeveledRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(3))),
                            ),
                            icon: const Icon(Icons.close, color: whiteprColor),
                            label: const Text('Отказаться от выполнения',
                                style: TextStyle(color: whiteprColor)),
                            onPressed: () => updateOrderStatus('отменен'),
                          ),
                        ])
                ],
              ),
            ),
    );
  }
}
