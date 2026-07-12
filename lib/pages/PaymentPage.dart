import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crgtransp72app/design/colors.dart';
import 'dart:async';
import 'dart:convert';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? orderId;
  String? subscriptionPaymentOrderId;
  String? statusText;
  String subscriptionStatusText = 'Проверяем подписку...';
  String? newSubscriptionStatusText;
  bool _isSavingSubscription = false;
  bool _hasSubscriptionRecord = false;
  DateTime? _subscriptionEndDate;

  // Флаг успешной оплаты
  bool _isPaymentSuccess = false;

  // Таймер для периодической проверки статуса
  Timer? _statusTimer;

  // --- НАСТРОЙКИ ---
  static const String proxyUrl = '${Config.baseUrl}/api/payment-proxy.php';
  static const String returnUrl =
      'intent://success#Intent;scheme=myapp;package=com.newunique.crgtransp72app;end';

  // Настройки подписки (приходят из БД через API)
  int _subscriptionDays = 30;
  int _subscriptionPriceRub = 300;
  bool _isSubscriptionConfigLoading = false;

  bool get _isSubscriptionActive {
    if (_subscriptionEndDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !_subscriptionEndDate!.isBefore(today);
  }

  bool get _canPayOrExtend => !_hasSubscriptionRecord || !_isSubscriptionActive;

  bool get _canCancelSubscription =>
      _hasSubscriptionRecord &&
      _isSubscriptionActive &&
      (subscriptionPaymentOrderId?.isNotEmpty ?? false);

  String get _paymentButtonLabel =>
      _hasSubscriptionRecord ? 'Пролить подписку' : 'Оплатить подписку';

  int get _subscriptionAmountKopecks => _subscriptionPriceRub * 100;

  String _generateOrderNumber() {
    return DateTime.now()
        .toLocal()
        .toString()
        .replaceAll(' ', '_')
        .replaceAll(':', '-');
  }

  // --- МЕТОДЫ ДЛЯ РАБОТЫ С API ---
  Future<Map<String, dynamic>> _sendPostRequest(
    String method,
    Map<String, dynamic> data,
  ) async {
    data['method'] = method;
    final body = data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');

    final response = await http.post(
      Uri.parse(proxyUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    debugPrint('STATUS CODE: ${response.statusCode}');
    debugPrint('BODY RESPONSE: ${response.body}');

    // У шлюза Альфа-Банка HTTP 200 ≠ успех операции: смотрим JSON
    // (success == true или errorCode == 0).
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'errorCode': '1',
        'errorMessage': 'Неожиданный формат ответа банка',
      };
    } catch (e) {
      debugPrint('JSON Error: $e');
      return {
        'errorCode': '1',
        'errorMessage':
            'Ответ не JSON (HTTP ${response.statusCode}): ${response.body.length > 180 ? response.body.substring(0, 180) : response.body}',
      };
    }
  }

  void _handleStatusResponse(Map<String, dynamic> response) {
    final orderStatusRaw =
        response['orderStatus'] ?? response['OrderStatus'];
    final int? orderStatus = orderStatusRaw is int
        ? orderStatusRaw
        : int.tryParse(orderStatusRaw?.toString() ?? '');
    final String? errorCode = response['errorCode']?.toString() ??
        response['ErrorCode']?.toString();
    final String? errorMessage = response['errorMessage']?.toString() ??
        response['ErrorMessage']?.toString();

    if (!_isBankSuccess(response) && orderStatus == null) {
      setState(() {
        statusText =
            '⚠️ Статус: Ошибка\nКод: ${errorCode ?? 'N/A'}\nСообщение: ${errorMessage ?? 'N/A'}';
      });
      return;
    }

    String displayText;
    if (orderStatus == 0 || orderStatus == 1) {
      displayText = '⏳ Статус: В обработке\nКод: $orderStatus';
    } else if (orderStatus == 2) {
      displayText = '✅ Подписка успешно оплачена!';

      if (!_isPaymentSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Подписка успешно оплачена!')),
        );
      }

      _statusTimer?.cancel();

      setState(() {
        _isPaymentSuccess = true;
        statusText = displayText;
      });
      _saveSubscriptionAfterPayment();
      return;
    } else {
      displayText =
          '⚠️ Статус: Ошибка\nКод: ${errorCode ?? 'N/A'}\nСообщение: ${errorMessage ?? 'N/A'}';
    }

    setState(() {
      statusText = displayText;
    });
  }

  Future<void> _checkOrderStatus() async {
    if (orderId == null) return;

    final data = {'orderId': orderId!};
    final response = await _sendPostRequest('getOrderStatus.do', data);
    _handleStatusResponse(response);
  }

  Future<void> _saveSubscriptionAfterPayment() async {
    if (_isSavingSubscription || userId <= 0 || orderId == null) {
      return;
    }

    _isSavingSubscription = true;
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/update_subscription.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'userId': userId.toString(),
          'orderId': orderId!,
          'days': _subscriptionDays.toString(),
          'amountRub': _subscriptionPriceRub.toString(),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final String? newDate = data['date']?.toString();
          final DateTime? parsedDate = newDate != null
              ? DateTime.tryParse(newDate)
              : null;
          setState(() {
            subscriptionStatusText = newDate != null && newDate.isNotEmpty
                ? 'Текущая подписка действует до $newDate'
                : 'Подписка обновлена';
            newSubscriptionStatusText = newDate != null && newDate.isNotEmpty
                ? 'Новая подписка действует до $newDate'
                : null;
            _hasSubscriptionRecord = newDate != null && newDate.isNotEmpty;
            _subscriptionEndDate = parsedDate;
            subscriptionPaymentOrderId = data['payment']?.toString();
          });
          return;
        }
      }

      setState(() {
        statusText = 'Оплата прошла, но не удалось обновить подписку';
      });
    } catch (e) {
      setState(() {
        statusText = 'Оплата прошла, но ошибка обновления подписки';
      });
      debugPrint('SUBSCRIPTION SAVE ERROR: $e');
    } finally {
      _isSavingSubscription = false;
      _fetchSubscriptionStatus();
    }
  }

  void _startStatusTimer() {
    _statusTimer?.cancel();
    debugPrint('[DEBUG] Старт таймера проверки статуса.');

    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      debugPrint('[DEBUG] Таймер сработал. Проверяем статус...');
      _checkOrderStatus();
    });
  }

  bool _isBankSuccess(Map<String, dynamic> response) {
    if (response['success'] == true || response['success'] == 'true') {
      return true;
    }
    final code = response['errorCode']?.toString() ??
        response['ErrorCode']?.toString();
    // Успех: errorCode отсутствует или равен 0
    return code == null || code == '0';
  }

  void _handleRegisterResponse(Map<String, dynamic> response) {
    final errorCode = response['errorCode']?.toString() ??
        response['ErrorCode']?.toString();
    final errorMessage = response['errorMessage']?.toString() ??
        response['ErrorMessage']?.toString() ??
        'Ошибка банка';

    if (!_isBankSuccess(response)) {
      setState(() {
        statusText = 'Ошибка #$errorCode: $errorMessage';
      });
      return;
    }

    final formUrl = response['formUrl'];
    final registeredOrderId = response['orderId']?.toString();

    if (formUrl == null || formUrl.toString().isEmpty) {
      setState(() {
        statusText =
            'Банк не вернул ссылку на оплату (orderId: ${registeredOrderId ?? '—'})';
      });
      return;
    }

    setState(() {
      orderId = registeredOrderId;
      statusText = 'Перенаправление на оплату...';
    });

    Navigator.of(context)
        .push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentWebViewScreen(paymentUrl: formUrl.toString()),
      ),
    )
        .then((_) {
      if (!mounted) return;
      debugPrint(
        '[DEBUG] Пользователь вернулся с экрана оплаты. Запускаем таймер.',
      );
      _startStatusTimer();
      _fetchSubscriptionStatus();
    });
  }

  Future<void> _registerOrder() async {
    setState(() {
      statusText = 'Регистрация подписки...';
      _isPaymentSuccess = false;
    });

    try {
      final data = {
        'orderNumber': _generateOrderNumber(),
        'amount': _subscriptionAmountKopecks.toString(),
        'returnUrl': returnUrl,
      };

      final response = await _sendPostRequest('register.do', data);
      _handleRegisterResponse(response);
    } catch (e) {
      setState(() => statusText = 'Ошибка сети. Проверьте подключение.');
      debugPrint('CATCHED ERROR: $e');
    }
  }

  void _onContinuePressed() {
    // TODO: замени на нужную навигацию в приложение
    Navigator.of(context).pop();
  }

  Future<void> _cancelSubscription() async {
    if (subscriptionPaymentOrderId == null || subscriptionPaymentOrderId!.isEmpty) {
      await _fetchSubscriptionStatus();
    }

    if (subscriptionPaymentOrderId == null || subscriptionPaymentOrderId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет активного заказа для отмены')),
      );
      return;
    }

    setState(() => statusText = 'Отмена подписки...');

    try {
      final data = {'orderId': subscriptionPaymentOrderId!};
      final response = await _sendPostRequest('reverse.do', data);

      final errorCode = response['errorCode']?.toString() ??
          response['ErrorCode']?.toString();
      final errorMessage = response['errorMessage']?.toString() ??
          response['ErrorMessage']?.toString() ??
          'Ошибка';

      if (_isBankSuccess(response)) {
        final bool dbUpdated = await _decreaseSubscriptionAfterCancel();
        if (!dbUpdated) {
          setState(() {
            statusText = 'Оплата отменена, но не удалось обновить подписку в БД';
          });
          return;
        }

        _statusTimer?.cancel();
        setState(() {
          _isPaymentSuccess = false;
          orderId = null;
          subscriptionPaymentOrderId = null;
          newSubscriptionStatusText = null;
          statusText = 'Подписка отменена';
        });
        _fetchSubscriptionStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подписка успешно отменена')),
        );
      } else {
        setState(() {
          statusText = 'Не удалось отменить подписку: $errorMessage';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отмены: $errorMessage')),
        );
      }
    } catch (e) {
      setState(() => statusText = 'Ошибка сети при отмене подписки');
      debugPrint('CANCEL ERROR: $e');
    }
  }

  Future<bool> _decreaseSubscriptionAfterCancel() async {
    if (userId <= 0) return false;

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/cancel_subscription.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'userId': userId.toString(),
          'days': _subscriptionDays.toString(),
        },
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('SUBSCRIPTION DB CANCEL ERROR: $e');
      return false;
    }
  }

  int userId = 0;
  Future<void> _fetchSubscriptionStatus() async {
    if (userId <= 0) {
      setState(() {
        subscriptionStatusText = 'Подписка не оформлялась';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${Config.baseUrl}/api/get_subscription.php?userId=$userId',
        ),
      );

      if (response.statusCode != 200) {
        setState(() {
          subscriptionStatusText = 'Не удалось получить данные подписки';
        });
        return;
      }

      final data = json.decode(response.body);
      final String? date = data['date']?.toString();
      final String? payment = data['payment']?.toString();
      final bool found = data['found'] == true;
      final DateTime? parsedDate = date != null ? DateTime.tryParse(date) : null;

      setState(() {
        if (found && date != null && date.isNotEmpty) {
          final bool isActive = parsedDate != null
              ? !parsedDate.isBefore(
                  DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  ),
                )
              : false;
          subscriptionStatusText = isActive
              ? 'Текущая подписка действует до $date'
              : 'Подписка истекла $date';
          _hasSubscriptionRecord = true;
          _subscriptionEndDate = parsedDate;
          subscriptionPaymentOrderId = payment;
        } else {
          subscriptionStatusText = 'Подписка не оформлялась';
          _hasSubscriptionRecord = false;
          _subscriptionEndDate = null;
          subscriptionPaymentOrderId = null;
          newSubscriptionStatusText = null;
        }
      });
    } catch (e) {
      setState(() {
        subscriptionStatusText = 'Ошибка при загрузке подписки';
      });
      debugPrint('SUBSCRIPTION LOAD ERROR: $e');
    }
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
        await _fetchSubscriptionStatus();
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<void> _fetchSubscriptionConfig() async {
    if (_isSubscriptionConfigLoading) return;
    _isSubscriptionConfigLoading = true;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/get_subscription_config.php'),
      );

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data['success'] != true) return;

      final int? days = int.tryParse(data['days']?.toString() ?? '');
      final int? priceRub = int.tryParse(data['price_rub']?.toString() ?? '');

      if (!mounted) return;
      setState(() {
        if (days != null && days > 0) {
          _subscriptionDays = days;
        }
        if (priceRub != null && priceRub > 0) {
          _subscriptionPriceRub = priceRub;
        }
      });
    } catch (e) {
      debugPrint('SUBSCRIPTION CONFIG ERROR: $e');
    } finally {
      _isSubscriptionConfigLoading = false;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionConfig();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Оформление подписки',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Подписка на доступ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_subscriptionDays дней',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Стоимость: $_subscriptionPriceRub ₽',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_isPaymentSuccess) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MyAppZakazScreen()));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Продолжить'),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _canPayOrExtend ? _registerOrder : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(_paymentButtonLabel),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _canCancelSubscription ? _cancelSubscription : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Отменить подписку'),
            ),

            const SizedBox(height: 24),
            Text(
              subscriptionStatusText,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            if (newSubscriptionStatusText != null) ...[
              const SizedBox(height: 8),
              Text(
                newSubscriptionStatusText!,
                style: const TextStyle(fontSize: 16, color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            if (statusText != null)
              Text(
                statusText!,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
