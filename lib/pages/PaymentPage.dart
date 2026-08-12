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
  static final String proxyUrl = '${Config.apiBase}/payment-proxy.php';
  static const String returnUrl =
      'intent://success#Intent;scheme=myapp;package=com.newunique.crgtransp72app;end';

  // Настройки подписки (приходят из БД через API)
  int _subscriptionDays = 30;
  int _subscriptionPriceRub = 300;
  int _basePriceRub = 300;
  int _discountRub = 0;
  int _selectedPackageId = 0;
  List<Map<String, dynamic>> _packages = [];
  final _promoController = TextEditingController();
  String? _promoStatus;
  bool _promoLoading = false;
  bool _isSubscriptionConfigLoading = false;
  int statNum = 0;
  String? _invoiceStatusText;
  bool _invoiceRequestLoading = false;

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
        Uri.parse('${Config.apiBase}/update_subscription.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'userId': userId.toString(),
          'orderId': orderId!,
          'days': _subscriptionDays.toString(),
          'amountRub': _subscriptionPriceRub.toString(),
          if (_selectedPackageId > 0)
            'packageId': _selectedPackageId.toString(),
          if (_promoController.text.trim().isNotEmpty)
            'promoCode': _promoController.text.trim().toUpperCase(),
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
    // Ответ вида {"error":"..."} без errorCode — это тоже ошибка
    final genericError = response['error']?.toString();
    if (genericError != null && genericError.isNotEmpty) {
      return false;
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
        response['error']?.toString() ??
        'Ошибка банка';

    if (!_isBankSuccess(response)) {
      setState(() {
        statusText = 'Ошибка #${errorCode ?? '—'}: $errorMessage';
      });
      return;
    }

    final formUrl = response['formUrl'];
    final registeredOrderId = response['orderId']?.toString();

    if (formUrl == null || formUrl.toString().isEmpty) {
      setState(() {
        statusText =
            'Банк не вернул ссылку на оплату (orderId: ${registeredOrderId ?? '—'}). Проверьте api_test/payment-proxy.php';
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
        Uri.parse('${Config.apiBase}/cancel_subscription.php'),
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
          '${Config.apiBase}/get_subscription.php?userId=$userId',
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
        .get(Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем состояние класса и UI
        setState(() {
          userId = data['idusers'];
          statNum = int.tryParse('${data['statNum'] ?? 0}') ?? 0;
        });
        await _fetchSubscriptionStatus();
        if (statNum == 1) {
          await _fetchInvoiceStatus();
        }
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<void> _fetchSubscriptionConfig() async {
    if (_isSubscriptionConfigLoading) return;
    _isSubscriptionConfigLoading = true;

    try {
      final packagesRes = await http.get(
        Uri.parse('${Config.apiBase}/get_subscription_packages.php'),
      );
      if (packagesRes.statusCode == 200) {
        final data = json.decode(packagesRes.body);
        if (data['success'] == true && data['packages'] is List) {
          final list = (data['packages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (list.isNotEmpty && mounted) {
            setState(() {
              _packages = list;
              _selectPackage(list.first);
            });
            return;
          }
        }
      }

      final response = await http.get(
        Uri.parse('${Config.apiBase}/get_subscription_config.php'),
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
          _basePriceRub = priceRub;
          _subscriptionPriceRub = priceRub;
          _discountRub = 0;
        }
      });
    } catch (e) {
      debugPrint('SUBSCRIPTION CONFIG ERROR: $e');
    } finally {
      _isSubscriptionConfigLoading = false;
    }
  }

  void _selectPackage(Map<String, dynamic> pkg) {
    final id = int.tryParse('${pkg['id'] ?? 0}') ?? 0;
    final days = int.tryParse('${pkg['days'] ?? 0}') ?? 30;
    final price = int.tryParse('${pkg['price_rub'] ?? 0}') ?? 300;
    _selectedPackageId = id;
    _subscriptionDays = days > 0 ? days : 30;
    _basePriceRub = price > 0 ? price : 300;
    _subscriptionPriceRub = _basePriceRub;
    _discountRub = 0;
    _promoStatus = null;
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountRub = 0;
        _subscriptionPriceRub = _basePriceRub;
        _promoStatus = null;
      });
      return;
    }
    setState(() {
      _promoLoading = true;
      _promoStatus = null;
    });
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBase}/validate_promo.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'package_id': _selectedPackageId,
          'userId': userId,
        }),
      );
      final data = json.decode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        final amount = int.tryParse('${data['amount_rub'] ?? ''}') ?? _basePriceRub;
        final discount =
            int.tryParse('${data['discount_rub'] ?? ''}') ?? 0;
        setState(() {
          _subscriptionPriceRub = amount;
          _discountRub = discount;
          _promoStatus = discount > 0
              ? 'Скидка $discount ₽ применена'
              : 'Промокод принят';
        });
      } else {
        setState(() {
          _subscriptionPriceRub = _basePriceRub;
          _discountRub = 0;
          _promoStatus = '${data['error'] ?? 'Промокод недействителен'}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _promoStatus = 'Не удалось проверить промокод';
      });
    } finally {
      if (mounted) setState(() => _promoLoading = false);
    }
  }

  Future<void> _fetchInvoiceStatus() async {
    final token = await getSecurefcm_token();
    if (token == null || !mounted) return;
    try {
      final response = await http.get(
        Uri.parse(
          '${Config.apiBase}/get_subscription_invoices.php?token=$token',
        ),
      );
      if (response.statusCode != 200 || !mounted) return;
      final data = json.decode(response.body);
      if (data['success'] != true) return;
      final active = data['active'];
      String? statusText;
      if (active is Map) {
        final st = '${active['status'] ?? ''}';
        final num = active['invoice_number'];
        statusText = switch (st) {
          'requested' => 'Заявка на счёт принята, ожидайте выставления.',
          'issued' => num != null && '$num'.isNotEmpty
              ? 'Счёт №$num выставлен. Оплатите по реквизитам.'
              : 'Счёт выставлен. Оплатите по реквизитам.',
          _ => null,
        };
      }
      setState(() => _invoiceStatusText = statusText);
    } catch (e) {
      debugPrint('INVOICE STATUS ERROR: $e');
    }
  }

  Future<void> _requestInvoice() async {
    if (!_canPayOrExtend || _selectedPackageId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите пакет подписки')),
      );
      return;
    }
    final token = await getSecurefcm_token();
    if (token == null) return;
    setState(() => _invoiceRequestLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBase}/request_subscription_invoice.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'package_id': _selectedPackageId,
          'promo_code': _promoController.text.trim(),
        }),
      );
      final data = json.decode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${data['message'] ?? 'Заявка на счёт принята'}',
            ),
          ),
        );
        await _fetchInvoiceStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['error'] ?? 'Не удалось создать заявку'}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети при запросе счёта')),
      );
    } finally {
      if (mounted) setState(() => _invoiceRequestLoading = false);
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _promoController.dispose();
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
      body: SingleChildScrollView(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Подписка на доступ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_packages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Выберите пакет',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _packages.map((pkg) {
                          final id = int.tryParse('${pkg['id'] ?? 0}') ?? 0;
                          final title = '${pkg['title'] ?? ''}';
                          final days = pkg['days'] ?? '';
                          final price = pkg['price_rub'] ?? '';
                          final selected = id == _selectedPackageId;
                          return ChoiceChip(
                            label: Text('$title · $days дн. · $price ₽'),
                            selected: selected,
                            onSelected: (_) {
                              setState(() => _selectPackage(pkg));
                            },
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        '$_subscriptionDays дней',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (_discountRub > 0)
                      Text(
                        'Без скидки: $_basePriceRub ₽',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    Text(
                      'Стоимость: $_subscriptionPriceRub ₽',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Промокод',
                        border: const OutlineInputBorder(),
                        suffixIcon: TextButton(
                          onPressed: _promoLoading ? null : _applyPromo,
                          child: _promoLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('OK'),
                        ),
                      ),
                    ),
                    if (_promoStatus != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _promoStatus!,
                        style: TextStyle(
                          color: _discountRub > 0
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
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
            if (statNum == 1) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: (_canPayOrExtend &&
                        !_invoiceRequestLoading &&
                        _invoiceStatusText == null)
                    ? _requestInvoice
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _invoiceRequestLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Запросить счёт (юр. лицо)'),
              ),
              if (_invoiceStatusText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _invoiceStatusText!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
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
