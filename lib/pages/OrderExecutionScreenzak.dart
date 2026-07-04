import 'dart:async';
import 'dart:convert';
import 'package:crgtransp72app/pages/chat_thread_screen.dart';
import 'package:crgtransp72app/pages/HistortScreen1z.dart';
import 'package:crgtransp72app/pages/SendReviewForm.dart' hide Config;
import 'package:crgtransp72app/pages/SendReviewFormzakaz.dart';
import 'package:crgtransp72app/pages/change_user.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/history_isp.dart';
import 'package:crgtransp72app/pages/scrmenu.dart';
import 'package:crgtransp72app/pages/test.dart' as hist;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';

class OrderExecutionScreenzak extends StatefulWidget {
  final String userId;
  final String orderId;
  final bool showBottomNav;
  final String orderSource;
  final int? bd;

  const OrderExecutionScreenzak({
    Key? key,
    required this.userId,
    required this.orderId,
    this.showBottomNav = false,
    this.orderSource = 'customer_order',
    this.bd,
  }) : super(key: key);

  @override
  _OrderExecutionScreenState createState() => _OrderExecutionScreenState();
}

class _OrderExecutionScreenState extends State<OrderExecutionScreenzak> {
  bool isLoading = true; // Используется для отображения индикатора загрузки
  Duration elapsedDuration = Duration.zero;
  Timer? timer;
  String? orderStatus; // Переменная для хранения текущего статуса заказа
  String? formattedDuration;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await getUserData();
    if (!mounted) return;
    await _loadOrderStatus();
  }

  DateTime? _parseServerDateTime(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      try {
        return DateTime.parse(s.replaceFirst(' ', 'T'));
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _loadOrderStatus() async {
    try {
      final formattedDateTime = DateTime.now().toIso8601String();
      final performerId = widget.userId.trim();
      final customerId = userIdok.trim();

      debugPrint('[ZAK] performer=$performerId order=${widget.orderId} customer=$customerId');

      if (performerId.isEmpty || customerId.isEmpty) {
        showErrorSnackbar('Не удалось определить участников заказа');
        return;
      }

      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/check_order_statusisp2.php'),
            body: {
              'user_id': performerId,
              'order_id': widget.orderId,
              'start_time': formattedDateTime,
              'user_idok': customerId,
              'source': widget.orderSource,
            },
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        String err = 'Ошибка сервера (${response.statusCode})';
        try {
          final data = json.decode(response.body);
          if (data is Map) {
            err = (data['details'] ?? data['error'] ?? data['message'])
                    ?.toString() ??
                err;
          }
        } catch (_) {}
        showErrorSnackbar(err);
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        showErrorSnackbar('Ошибка формата данных');
        return;
      }

      final message = decoded['message']?.toString() ?? '';
      switch (message) {
        case 'Продолжается выполнение':
          final startDate = _parseServerDateTime(decoded['start_time']);
          if (startDate == null) {
            showErrorSnackbar('Некорректное время начала заказа');
            break;
          }
          setState(() => orderStatus = 'Продолжается выполнение');
          if (timer == null || timer!.tick == 0) {
            startTimer(startDate);
          }
          break;
        case 'Запись успешно создана':
          setState(() => orderStatus = 'Продолжается выполнение');
          if (timer == null || timer!.tick == 0) {
            startTimer(null);
          }
          break;
        case 'Заказ выполнен':
          final startDate = _parseServerDateTime(decoded['start_time']);
          final endDate = _parseServerDateTime(decoded['end_time']);
          if (startDate == null || endDate == null) {
            showErrorSnackbar('Некорректное время выполнения заказа');
            break;
          }
          final durationSeconds = endDate.difference(startDate).inSeconds;
          final hours = durationSeconds ~/ 3600;
          final minutes = ((durationSeconds % 3600) / 60).round();
          setState(() {
            orderStatus = 'выполнен';
            timer?.cancel();
            formattedDuration = '$hours часа(-ов) $minutes минута(-ы)';
          });
          break;
        case 'Заказ отменен':
          final cancelDate = _parseServerDateTime(decoded['cancel_time']);
          if (cancelDate == null) {
            showErrorSnackbar('Некорректное время отмены');
            break;
          }
          setState(() {
            orderStatus = 'отменен';
            timer?.cancel();
            formattedCancelTime =
                '${cancelDate.day}.${cancelDate.month}.${cancelDate.year} ${cancelDate.hour}:${cancelDate.minute}';
          });
          break;
        default:
          showErrorSnackbar(
              message.isNotEmpty ? message : 'Неизвестный статус заказа');
      }
    } catch (e) {
      debugPrint('[ZAK] _loadOrderStatus: $e');
      showErrorSnackbar('Ошибка связи с сервером');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String userIdok = '';
  Future<void> getUserData() async {
    final token = await getSecurefcm_token();
    if (token == null) {
      return;
    }
    final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] == null) {
        userIdok = data['idusers']?.toString() ?? '';
        debugPrint('[ZAK] customer session id=$userIdok');
      }
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
          if (widget.orderSource == 'performer_ad') 'user_idok': userIdok,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => history_isp(
                            nameImg: userIdok,
                            bd: 1), //hist.HistortScreen(pageProfile: 'hist'),
                      ),
                    );
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
    timer?.cancel();
    super.dispose();
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openOrderChat() async {
    final performerId = int.tryParse(widget.userId.trim());
    final customerId = int.tryParse(userIdok.trim());
    final adId = int.tryParse(widget.orderId);
    if (performerId == null ||
        customerId == null ||
        adId == null ||
        performerId <= 0 ||
        customerId <= 0 ||
        adId <= 0) {
      showErrorSnackbar('Не удалось открыть чат по заказу');
      return;
    }
    await ChatThreadScreen.openDeal(
      context: context,
      counterpartUserId: performerId,
      bd: widget.bd ?? 1,
      adId: adId,
      title: 'Исполнитель',
      currentUserId: customerId,
    );
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
      bottomNavigationBar: widget.showBottomNav
          ? const CustomerBottomNav(currentIndex: 1)
          : null,
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
                  if (orderStatus == null ||
                      !['выполнен', 'отменен'].contains(orderStatus))
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          fixedSize: const Size(double.infinity, 50),
                          foregroundColor: whiteprColor,
                          backgroundColor: blueaccentColor,
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline,
                            color: whiteprColor),
                        label: const Text('Чат по заказу',
                            style: TextStyle(color: whiteprColor)),
                        onPressed: _openOrderChat,
                      ),
                    ),
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
                                    'Parsed User ID Ok zab: $parsedUserIdOk'); //106

                                if (parsedUserIdOk != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => HistortScreen1z(
                                            pageProfile: 'SendReviewForm',
                                            userId1: userIdok,
                                            orderId: widget.orderId.toString(),
                                            parsedUserIdOk:
                                                widget.userId.toString())
                                        /*   SendReviewFormzakaz(
                                              currentUserId:
                                                  widget.userId.toString(),
                                              targetUserId:
                                                  widget.orderId.toString(),
                                              parsedUserIdOk: parsedUserIdOk,
                                            )
                                        SendReviewForm(
                                              currentUserId:
                                                  widget.userId.toString(),
                                              targetUserId: userId.toString(),
                                              parsedUserIdOk: parsedUserIdOk,
                                            )*/
                                        ),
                                  );
                                } else {
                                  // Если преобразование не удалось, вывести предупреждение или ошибку
                                  print(
                                      'Ошибка: Невозможно преобразовать "$userIdok" в целое число.');
                                }
                              },
                              child: Text('Оставьте отзыв о исполнителе'),
                            ),
                        ],
                      ),
                    ),
                  /*        if (orderStatus == null ||
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
           */
                ],
              ),
            ),
    );
  }
}
