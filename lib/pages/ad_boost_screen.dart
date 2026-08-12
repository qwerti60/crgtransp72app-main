import 'dart:async';
import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/payment_webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdBoostScreen extends StatefulWidget {
  final int adId;
  final int bd;
  final String adTitle;

  const AdBoostScreen({
    super.key,
    required this.adId,
    required this.bd,
    required this.adTitle,
  });

  @override
  State<AdBoostScreen> createState() => _AdBoostScreenState();
}

class _AdBoostScreenState extends State<AdBoostScreen> {
  static final _proxyUrl = '${Config.apiBase}/payment-proxy.php';
  static const _returnUrl =
      'intent://success#Intent;scheme=myapp;package=com.newunique.crgtransp72app;end';

  List<Map<String, dynamic>> _tariffs = [];
  int _selectedTariffId = 0;
  bool _loading = true;
  bool _paying = false;
  String? _error;
  Timer? _statusTimer;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTariffs());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTariffs() async {
    try {
      final resp = await http
          .get(Uri.parse('${Config.apiBase}/get_boost_tariffs.php'))
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (data['success'] == true && data['tariffs'] is List) {
        final list = (data['tariffs'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        setState(() {
          _tariffs = list;
          _selectedTariffId = list.isNotEmpty ? (list.first['id'] as int? ?? 0) : 0;
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'Не удалось загрузить тарифы';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка сети: $e';
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? get _selectedTariff {
    for (final t in _tariffs) {
      if ((t['id'] as int? ?? 0) == _selectedTariffId) return t;
    }
    return _tariffs.isNotEmpty ? _tariffs.first : null;
  }

  Future<Map<String, dynamic>> _bankPost(
    String method,
    Map<String, dynamic> data,
  ) async {
    // Шлюз Альфа-Банка: register.do / getOrderStatus.do (суффикс .do обязателен)
    final bankMethod = method.endsWith('.do') ? method : '$method.do';
    data['method'] = bankMethod;
    final body = data.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );
    final raw = response.body.trim();
    if (raw.isEmpty || raw.startsWith('<!') || raw.startsWith('<html')) {
      throw FormatException(
        'Ответ не JSON (HTTP ${response.statusCode}): '
        '${raw.length > 120 ? raw.substring(0, 120) : raw}',
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Неожиданный формат ответа банка');
    }
    return decoded;
  }

  bool _bankOk(Map<String, dynamic> r) {
    if (r['success'] == true || r['success'] == 'true') return true;
    final genericError = r['error']?.toString();
    if (genericError != null && genericError.isNotEmpty) return false;
    final code = r['errorCode']?.toString() ?? r['ErrorCode']?.toString();
    // Успех: errorCode отсутствует или 0 (как в PaymentPage)
    return code == null || code == '0';
  }

  Future<int> _resolveUserId() async {
    final token = await getSecurefcm_token();
    if (token == null) return 0;
    final resp = await http.get(
      Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'),
    );
    if (resp.statusCode != 200) return 0;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return int.tryParse(data['idusers']?.toString() ?? '') ?? 0;
  }

  Future<void> _applyBoost(String orderId) async {
    final token = await getSecurefcm_token();
    final uid = await _resolveUserId();
    final body = {
      'token': token ?? '',
      'userId': uid.toString(),
      'bd': widget.bd.toString(),
      'adId': widget.adId.toString(),
      'tariffId': _selectedTariffId.toString(),
      'orderId': orderId,
    };
    await http.post(
      Uri.parse('${Config.apiBase}/apply_ad_boost.php'),
      body: body,
    );
  }

  Future<void> _startPayment() async {
    final tariff = _selectedTariff;
    if (tariff == null) return;

    setState(() {
      _paying = true;
      _error = null;
    });

    final orderId =
        'boost_${widget.adId}_${DateTime.now().millisecondsSinceEpoch}';
    _orderId = orderId;
    final amountKopecks = ((tariff['price_rub'] as int? ?? 0) * 100).toString();

    try {
      final reg = await _bankPost('register', {
        'orderNumber': orderId,
        'amount': amountKopecks,
        'returnUrl': _returnUrl,
        'description': 'Поднятие объявления: ${widget.adTitle}',
      });

      if (!_bankOk(reg)) {
        throw Exception(
          reg['errorMessage']?.toString() ??
              reg['ErrorMessage']?.toString() ??
              reg['error']?.toString() ??
              'Ошибка регистрации платежа',
        );
      }

      final formUrl = reg['formUrl']?.toString();
      if (formUrl == null || formUrl.isEmpty) {
        throw Exception('Не получена ссылка на оплату');
      }

      // Статус оплаты проверяем по orderId банка, не по локальному номеру
      final bankOrderId = reg['orderId']?.toString();
      if (bankOrderId != null && bankOrderId.isNotEmpty) {
        _orderId = bankOrderId;
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(paymentUrl: formUrl),
        ),
      );

      _statusTimer?.cancel();
      _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (_orderId == null) return;
        try {
          final st =
              await _bankPost('getOrderStatus', {'orderId': _orderId!});
          if (!_bankOk(st)) return;
          final status = st['orderStatus'] ?? st['OrderStatus'];
          if (status == 2 || status == '2') {
            _statusTimer?.cancel();
            await _applyBoost(_orderId!);
            if (!mounted) return;
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Объявление поднято в топ')),
            );
          }
        } catch (_) {
          // следующий тик таймера
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tariff = _selectedTariff;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поднять в топ'),
        backgroundColor: blueaccentColor,
        foregroundColor: whiteprColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.adTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Объявление будет выше в выдаче на выбранный срок.'),
                  const SizedBox(height: 16),
                  ..._tariffs.map((t) {
                    final id = t['id'] as int? ?? 0;
                    return RadioListTile<int>(
                      value: id,
                      groupValue: _selectedTariffId,
                      onChanged: _paying
                          ? null
                          : (v) => setState(() => _selectedTariffId = v ?? id),
                      title: Text('${t['title']} — ${t['price_rub']} ₽'),
                      subtitle: Text('${t['hours']} ч в топе'),
                    );
                  }),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueaccentColor,
                      foregroundColor: whiteprColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _paying || tariff == null ? null : _startPayment,
                    child: _paying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Оплатить ${tariff?['price_rub'] ?? 0} ₽',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
