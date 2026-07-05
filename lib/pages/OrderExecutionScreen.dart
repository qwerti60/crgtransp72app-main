import 'dart:async';
import 'dart:convert';
import 'package:crgtransp72app/navigation/shell_nav_auth_cache.dart';
import 'package:crgtransp72app/pages/SendReviewForm.dart';
import 'package:crgtransp72app/pages/chat_thread_screen.dart';
import 'package:crgtransp72app/pages/change_user.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:crgtransp72app/services/review_pair_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';

class OrderExecutionScreen extends StatefulWidget {
  final String userId;
  final String orderId;
  /// id заказчика (users.idusers) — пишется в ordersglobal.user_idok.
  final String? customerUserId;
  final int? bd;
  final bool showBottomNav;
  /// customer_order — отклик на заявку заказчика; performer_ad — заявка на объявление исполнителя.
  final String orderSource;
  /// start_time из ordersglobal — для мгновенного показа таймера после переустановки.
  final String? initialStartTime;

  const OrderExecutionScreen({
    Key? key,
    required this.userId,
    required this.orderId,
    this.customerUserId,
    this.bd,
    this.orderSource = 'customer_order',
    this.showBottomNav = false,
    this.initialStartTime,
  }) : super(key: key);

  @override
  _OrderExecutionScreenState createState() => _OrderExecutionScreenState();
}

class _OrderExecutionScreenState extends State<OrderExecutionScreen> {
  bool isLoading = true; // Используется для отображения индикатора загрузки
  Duration elapsedDuration = Duration.zero;
  Timer? timer;
  String? orderStatus; // Переменная для хранения текущего статуса заказа
  String? formattedDuration;
  bool _hasExistingReview = false;

  static const _timerDigitsStyle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
  );

  @override
  void initState() {
    super.initState();
    _applyInitialStartTime();
    _bootstrap();
  }

  void _applyInitialStartTime() {
    final startDate = _parseServerDateTime(widget.initialStartTime);
    if (startDate == null) return;
    orderStatus = 'Продолжается выполнение';
    startTimer(startDate);
  }

  Future<void> _bootstrap() async {
    await getUserData();
    if (!mounted) return;

    final resumeStart = await _fetchResumeStartTime();
    if (resumeStart != null && mounted) {
      _resumeRunningOrder(resumeStart);
      setState(() => isLoading = false);
    }

    await _loadOrderStatus();
  }

  /// start_time из shell, get_order_global_info или check_order_status1.
  Future<DateTime?> _fetchResumeStartTime() async {
    final fromWidget = _parseServerDateTime(widget.initialStartTime);
    if (fromWidget != null) {
      debugPrint('[ISP] resume start_time from widget: ${widget.initialStartTime}');
      return fromWidget;
    }

    final performerId = widget.userId.trim();
    final orderId = widget.orderId.trim();
    if (performerId.isEmpty || orderId.isEmpty) {
      return null;
    }

    try {
      final infoUri = Uri.parse('${Config.baseUrl}/api/get_order_global_info.php')
          .replace(queryParameters: {
        'performer_id': performerId,
        'order_id': orderId,
        if (_customerIdForRequest().isNotEmpty)
          'customer_id': _customerIdForRequest(),
      });
      final infoResp =
          await http.get(infoUri).timeout(const Duration(seconds: 10));
      debugPrint('[ISP] get_order_global_info ${infoResp.statusCode}: ${infoResp.body}');
      if (infoResp.statusCode == 200) {
        final info = json.decode(infoResp.body) as Map<String, dynamic>;
        if (info['found'] == true &&
            info['status']?.toString() == 'выполняется') {
          final start = _parseServerDateTime(info['start_time']);
          if (start != null) return start;
        }
      }
    } catch (e) {
      debugPrint('[ISP] get_order_global_info error: $e');
    }

    try {
      final statusUri = Uri.parse(
          '${Config.baseUrl}/api/check_order_status1.php?userIdok=$performerId');
      final statusResp =
          await http.get(statusUri).timeout(const Duration(seconds: 10));
      debugPrint('[ISP] check_order_status1 ${statusResp.statusCode}: ${statusResp.body}');
      if (statusResp.statusCode == 200) {
        final status = json.decode(statusResp.body) as Map<String, dynamic>;
        if (status['result'] == true &&
            status['order_id']?.toString() == orderId) {
          final st = status['status']?.toString() ?? 'выполняется';
          if (st == 'выполняется') {
            final start = _parseServerDateTime(status['start_time']);
            if (start != null) return start;
          }
        }
      }
    } catch (e) {
      debugPrint('[ISP] check_order_status1 resume error: $e');
    }

    return null;
  }

  bool get _timerIsActive => orderStatus == 'Продолжается выполнение';

  String userIdok = '';
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
          userIdok = data['idusers']?.toString() ?? '';
        });
        if (userIdok.isNotEmpty) {
          userId = int.tryParse(userIdok) ?? userId;
        }
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
    timer?.cancel();
    if (startDate != null) {
      final elapsed = DateTime.now().difference(startDate);
      elapsedDuration = elapsed.isNegative ? Duration.zero : elapsed;
    }
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (startDate != null) {
          final elapsed = DateTime.now().difference(startDate);
          elapsedDuration = elapsed.isNegative ? Duration.zero : elapsed;
        } else {
          elapsedDuration += const Duration(seconds: 1);
        }
      });
    });
  }

  String? formattedCancelTime;

  Future<void> updateOrderStatus(String newStatus) async {
    final now = DateTime.now();
    final customerId = await _resolveCustomerId();

    final dio = Dio();
    try {
      final payload = <String, dynamic>{
        'user_id': widget.userId,
        'order_id': widget.orderId,
        'status': newStatus,
        'current_date_time': now.toIso8601String(),
      };
      if (customerId.isNotEmpty) {
        payload['user_idok'] = customerId;
      }

      final response = await dio.put(
        '${Config.baseUrl}/api/update_order_status.php',
        data: payload,
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
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MyAppZakazScreen(initialPage: 1),
                      ),
                      (Route<dynamic> route) => false,
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
          int seconds = result['duration_seconds'];
          Duration duration = Duration(seconds: seconds);
          String hoursMinutes = formatDuration(duration);
          setState(() {
            orderStatus = newStatus;
            timer?.cancel();
            formattedDuration = hoursMinutes;
          });
          unawaited(_refreshExistingReviewFlag());
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Заказ выполнен'),
                content: Text('Время выполнения заказа: $hoursMinutes'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
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

  String _customerIdForRequest() {
    final fromWidget = widget.customerUserId?.trim() ?? '';
    if (fromWidget.isNotEmpty && fromWidget != '0') {
      return fromWidget;
    }
    return '';
  }

  DateTime? _parseServerDateTime(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty || s.startsWith('0000-00-00')) return null;

    // MySQL: 2026-06-30 12:34:09 — всегда локальное время сервера
    final mysql = RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})$');
    final m = mysql.firstMatch(s);
    if (m != null) {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
    }

    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      try {
        return DateTime.parse(s.replaceFirst(' ', 'T')).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  void _resumeRunningOrder(DateTime startDate) {
    final elapsed = DateTime.now().difference(startDate);
    setState(() {
      elapsedDuration = elapsed.isNegative ? Duration.zero : elapsed;
      orderStatus = 'Продолжается выполнение';
    });
    _markOrdersTabActive();
    startTimer(startDate);
  }

  void _markOrdersTabActive() {
    PerformerShellNavCache.update(
      isAuthorized: true,
      highlightOrders: true,
    );
  }

  /// id заказчика для ordersglobal.user_idok (нужен даже на старом API).
  Future<String> _resolveCustomerId() async {
    final fromWidget = _customerIdForRequest();
    if (fromWidget.isNotEmpty) {
      return fromWidget;
    }

    final performerId = widget.userId.trim();
    final orderId = widget.orderId.trim();
    if (performerId.isEmpty || orderId.isEmpty) {
      return '';
    }

    try {
      final infoUri = Uri.parse('${Config.baseUrl}/api/get_order_global_info.php')
          .replace(queryParameters: {
        'performer_id': performerId,
        'order_id': orderId,
        if (_customerIdForRequest().isNotEmpty)
          'customer_id': _customerIdForRequest(),
      });
      final infoResp = await http.get(infoUri).timeout(const Duration(seconds: 10));
      if (infoResp.statusCode == 200) {
        final info = json.decode(infoResp.body) as Map<String, dynamic>;
        final id = info['user_idok']?.toString().trim() ?? '';
        if (info['found'] == true && id.isNotEmpty && id != '0') {
          return id;
        }
      }
    } catch (e) {
      debugPrint('get_order_global_info: $e');
    }

    try {
      final loggedInId =
          userIdok.isNotEmpty ? userIdok : performerId;
      final statusUri = Uri.parse(
          '${Config.baseUrl}/api/check_order_status1.php?userIdok=$loggedInId');
      final statusResp =
          await http.get(statusUri).timeout(const Duration(seconds: 10));
      if (statusResp.statusCode == 200) {
        final status = json.decode(statusResp.body) as Map<String, dynamic>;
        if (status['result'] == true &&
            status['order_id']?.toString() == orderId) {
          final id = status['user_idok']?.toString().trim() ?? '';
          if (id.isNotEmpty && id != '0') {
            return id;
          }
        }
      }
    } catch (e) {
      debugPrint('check_order_status1 fallback: $e');
    }

    return '';
  }

  Future<void> _loadOrderStatus() async {
    try {
      final currentDateTime = DateTime.now();
      final formattedDateTime = currentDateTime.toIso8601String();
      final customerId = await _resolveCustomerId();

      debugPrint('[ISP] performer=${widget.userId} order=${widget.orderId} customer=$customerId');
      debugPrint('BD: ${widget.bd}');

      final fields = <String, String>{
        'user_id': widget.userId,
        'order_id': widget.orderId,
        'start_time': formattedDateTime,
        'user_idok': customerId,
        'source': widget.orderSource,
      };
      if (widget.bd != null && widget.bd! > 0) {
        fields['bd'] = widget.bd.toString();
      }

      final response = await http
          .post(
            Uri.parse('${Config.baseUrl}/api/check_order_status.php'),
            body: fields,
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
        if (!_timerIsActive) {
          showErrorSnackbar(err);
        } else {
          debugPrint('[ISP] POST failed but timer kept: $err');
        }
        return;
      }

      final dynamic decoded = json.decode(response.body);
      debugPrint('[ISP] check_order_status POST sync: $decoded');
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString() ?? '';
        switch (message) {
          case 'Продолжается выполнение':
            final startDate =
                _parseServerDateTime(decoded['start_time']) ?? DateTime.now();
            if (_parseServerDateTime(decoded['start_time']) == null) {
              debugPrint('[ISP] start_time parse fallback to now');
            }

            final totalElapsedSeconds =
                DateTime.now().difference(startDate).inSeconds.clamp(0, 1 << 31);
            final hours = totalElapsedSeconds ~/ 3600;
            final minutes = ((totalElapsedSeconds % 3600) / 60).round();
            final durationFormatted = '$hours часа(-ов) $minutes минут(-ы)';

            setState(() {
              formattedDuration = durationFormatted;
            });
            _resumeRunningOrder(startDate);
            break;

          case 'Запись успешно создана':
            final startDate =
                _parseServerDateTime(decoded['start_time']) ?? DateTime.now();
            _resumeRunningOrder(startDate);
            break;

          case 'Нельзя начать выполнение':
            showErrorSnackbar(
              decoded['block_message']?.toString() ??
                  'Нельзя начать новый заказ.',
            );
            break;

          case 'Заказ выполнен':
            final startDate = _parseServerDateTime(decoded['start_time']);
            final endDate = _parseServerDateTime(decoded['end_time']);
            if (startDate == null || endDate == null) {
              showErrorSnackbar('Некорректное время выполнения заказа');
              break;
            }

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
            unawaited(_refreshExistingReviewFlag());
            break;

          case 'Заказ отменен':
            final cancelDate = _parseServerDateTime(decoded['cancel_time']);
            if (cancelDate == null) {
              showErrorSnackbar('Некорректное время отмены');
              break;
            }
            final formattedDate =
                "${cancelDate.day}.${cancelDate.month}.${cancelDate.year} ${cancelDate.hour}:${cancelDate.minute}";

            setState(() {
              orderStatus = 'отменен';
              timer?.cancel();
              formattedCancelTime = formattedDate;
            });
            break;

          case 'Предложение не принято заказчиком':
            showErrorSnackbar('Заказчик ещё не принял ваше предложение');
            break;

          default:
            if (!_timerIsActive) {
              showErrorSnackbar(
                  message.isNotEmpty ? message : 'Неизвестный статус заказа');
            }
        }
      } else if (decoded is Map && decoded['error'] != null) {
        if (!_timerIsActive) {
          showErrorSnackbar(decoded['error'].toString());
        }
      } else if (!_timerIsActive) {
        showErrorSnackbar('Ошибка формата данных');
      }
    } catch (e) {
      debugPrint('OrderExecutionScreen _loadOrderStatus: $e');
      if (!_timerIsActive) {
        showErrorSnackbar('Ошибка связи с сервером');
      }
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

  Future<void> _openOrderChat() async {
    final customerId = int.tryParse(widget.customerUserId?.trim() ?? '');
    final adId = int.tryParse(widget.orderId);
    final performerId = int.tryParse(userIdok.isNotEmpty ? userIdok : widget.userId);
    if (customerId == null ||
        adId == null ||
        performerId == null ||
        customerId <= 0 ||
        adId <= 0) {
      showErrorSnackbar('Не удалось открыть чат по заказу');
      return;
    }
    await ChatThreadScreen.openDeal(
      context: context,
      counterpartUserId: customerId,
      bd: widget.bd ?? 1,
      adId: adId,
      title: 'Заказчик',
      currentUserId: performerId,
      showBottomNav: true,
      isPerformer: true,
    );
  }

  Future<void> _refreshExistingReviewFlag() async {
    final performerId =
        int.tryParse(userIdok.isNotEmpty ? userIdok : widget.userId) ?? 0;
    final customerId = int.tryParse(await _resolveCustomerId()) ?? 0;
    if (performerId <= 0 || customerId <= 0) return;

    final existing = await fetchReviewBetween(
      table: ReviewPairTable.performerAboutCustomer,
      performerId: performerId,
      customerId: customerId,
    );
    if (!mounted) return;
    setState(() => _hasExistingReview = existing != null);
  }

  Future<void> _openReviewForm() async {
    final performerId = userIdok.isNotEmpty ? userIdok : widget.userId;
    final customerId = widget.customerUserId?.trim() ?? '';
    final listingId = int.tryParse(widget.orderId) ?? 0;
    if (customerId.isEmpty || customerId == '0' || listingId <= 0) {
      showErrorSnackbar('Не удалось определить заказчика для отзыва');
      return;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SendReviewForm(
          currentUserId: performerId,
          targetUserId: customerId,
          parsedUserIdOk: listingId,
        ),
      ),
    );
    if (mounted) await _refreshExistingReviewFlag();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        leading: BackButton(),
        title: Text('Выполнение заказа №${widget.orderId}',
            style: const TextStyle(color: whiteprColor)),
        backgroundColor: blueaccentColor,
      ),
      body: isLoading && !_timerIsActive
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (orderStatus == 'Продолжается выполнение' ||
                      (elapsedDuration > Duration.zero &&
                          orderStatus != 'выполнен' &&
                          orderStatus != 'отменен'))
                    Column(children: [
                      Text('Время выполнения:',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(formatDuration(elapsedDuration),
                          style: _timerDigitsStyle),
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
                          if (orderStatus == 'выполнен')
                            ElevatedButton(
                              onPressed: _openReviewForm,
                              child: Text(_hasExistingReview
                                  ? 'Изменить отзыв'
                                  : 'Оставьте отзыв'),
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
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: whiteprColor),
                            label: const Text('Чат по заказу',
                                style: TextStyle(color: whiteprColor)),
                            onPressed: _openOrderChat,
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
      // Нижнее меню только у shell (zakaz_screen2), не у вложенного экрана выполнения.
      bottomNavigationBar: null,
    );
  }
}
