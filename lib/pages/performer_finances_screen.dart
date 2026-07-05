import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PerformerFinancesScreen extends StatefulWidget {
  const PerformerFinancesScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<PerformerFinancesScreen> createState() =>
      _PerformerFinancesScreenState();
}

class _PerformerFinancesScreenState extends State<PerformerFinancesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  bool _incomeLoading = false;
  String? _error;

  String _period = 'month';
  DateTime? _customFrom;
  DateTime? _customTo;

  List<dynamic> _payments = [];
  int _paymentsTotalRub = 0;
  List<dynamic> _incomeItems = [];
  double _incomeTotalRub = 0;
  int _incomeCount = 0;
  String _periodLabel = 'За 30 дней';

  final _moneyFmt = NumberFormat('#,##0.##', 'ru_RU');
  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _apiDateFmt = DateFormat('yyyy-MM-dd');
  final _dateTimeFmt = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatRub(num value) => '${_moneyFmt.format(value)} ₽';

  String _formatDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _dateTimeFmt.format(parsed.toLocal());
  }

  String _dealSourceLabel(String? source) {
    if (source == 'performer_ad') return 'Объявление исполнителя';
    return 'Заказ заказчика';
  }

  Future<void> _loadData({bool incomeOnly = false}) async {
    if (incomeOnly) {
      if (!mounted) return;
      setState(() => _incomeLoading = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Войдите в аккаунт';
        });
        return;
      }

      final params = <String, String>{
        'token': token,
        'period': _period,
      };
      if (_period == 'custom') {
        if (_customFrom != null) {
          params['from'] = _apiDateFmt.format(_customFrom!);
        }
        if (_customTo != null) {
          params['to'] = _apiDateFmt.format(_customTo!);
        }
      }

      final uri = Uri.parse('${Config.baseUrl}/api/get_performer_finances.php')
          .replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        setState(() {
          if (!incomeOnly) _loading = false;
          _incomeLoading = false;
          if (!incomeOnly) {
            _error = 'Ошибка загрузки (${response.statusCode})';
          }
        });
        return;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) {
        setState(() {
          if (!incomeOnly) _loading = false;
          _incomeLoading = false;
          if (!incomeOnly) {
            _error = data['error']?.toString() ?? 'Не удалось загрузить данные';
          }
        });
        return;
      }

      final period = data['period'] as Map<String, dynamic>? ?? {};
      setState(() {
        _payments = (data['subscription_payments'] as List<dynamic>?) ?? [];
        _paymentsTotalRub = (data['subscription_total_rub'] as num?)?.toInt() ?? 0;
        _incomeItems = (data['income_items'] as List<dynamic>?) ?? [];
        _incomeTotalRub = (data['income_total_rub'] as num?)?.toDouble() ?? 0;
        _incomeCount = (data['income_count'] as num?)?.toInt() ?? 0;
        _periodLabel = period['label']?.toString() ?? '';
        _loading = false;
        _incomeLoading = false;
      });
    } catch (e) {
      setState(() {
        if (!incomeOnly) _loading = false;
        _incomeLoading = false;
        if (!incomeOnly) _error = 'Ошибка сети';
      });
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    var from = _customFrom ?? now.subtract(const Duration(days: 29));
    var to = _customTo ?? now;
    if (to.isBefore(from)) {
      final tmp = from;
      from = to;
      to = tmp;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickDate({required bool isFrom}) async {
              final initial = isFrom ? from : to;
              final picked = await _showSimpleDatePicker(
                initial: initial,
                firstDate: DateTime(2020),
                lastDate: now,
              );
              if (picked == null) return;
              setDialogState(() {
                if (isFrom) {
                  from = picked;
                  if (to.isBefore(from)) to = from;
                } else {
                  to = picked;
                  if (from.isAfter(to)) from = to;
                }
              });
            }

            return AlertDialog(
              title: const Text('Выберите период'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('С'),
                    subtitle: Text(_dateFmt.format(from)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(isFrom: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('По'),
                    subtitle: Text(_dateFmt.format(to)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => pickDate(isFrom: false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Показать'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _period = 'custom';
      _customFrom = from;
      _customTo = to;
    });
    await _loadData(incomeOnly: true);
  }

  static const List<String> _monthLabels = [
    'янв', 'фев', 'мар', 'апр', 'май', 'июн',
    'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
  ];

  Future<DateTime?> _showSimpleDatePicker({
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    var year = initial.year.clamp(firstDate.year, lastDate.year);
    var month = initial.month;
    var day = initial.day;

    int daysInMonth(int y, int m) => DateTime(y, m + 1, 0).day;

    void clampDay() {
      final maxDay = daysInMonth(year, month);
      if (day > maxDay) day = maxDay;
      final candidate = DateTime(year, month, day);
      if (candidate.isBefore(firstDate)) {
        year = firstDate.year;
        month = firstDate.month;
        day = firstDate.day;
      } else if (candidate.isAfter(lastDate)) {
        year = lastDate.year;
        month = lastDate.month;
        day = lastDate.day;
      }
    }

    clampDay();

    return showDialog<DateTime>(
      context: context,
      useRootNavigator: true,
      builder: (pickerContext) {
        return StatefulBuilder(
          builder: (pickerContext, setPickerState) {
            final years = List<int>.generate(
              lastDate.year - firstDate.year + 1,
              (i) => firstDate.year + i,
            );
            final months = List<int>.generate(12, (i) => i + 1);
            final maxDay = daysInMonth(year, month);
            final days = List<int>.generate(maxDay, (i) => i + 1);

            return AlertDialog(
              title: const Text('Дата'),
              content: Row(
                children: [
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: day,
                      items: days
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setPickerState(() => day = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: month,
                      items: months
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(_monthLabels[m - 1]),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setPickerState(() {
                          month = value;
                          clampDay();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: year,
                      items: years
                          .map(
                            (y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setPickerState(() {
                          year = value;
                          clampDay();
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(pickerContext).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    clampDay();
                    Navigator.of(pickerContext).pop(DateTime(year, month, day));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _setPeriod(String period) {
    if (_period == period && period != 'custom') return;
    setState(() => _period = period);
    if (period != 'custom') {
      _loadData(incomeOnly: true);
    }
  }

  Widget _periodChip(String key, String label) {
    final selected = _period == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _setPeriod(key),
        backgroundColor:
            selected ? blueaccentColor.withValues(alpha: 0.2) : null,
        labelStyle: TextStyle(
          color: selected ? blueaccentColor : TexticonsColor,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPeriodFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _periodChip('day', 'Сегодня'),
          _periodChip('week', '7 дней'),
          _periodChip('month', '30 дней'),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                _period == 'custom' && _customFrom != null && _customTo != null
                    ? '${_dateFmt.format(_customFrom!)} — ${_dateFmt.format(_customTo!)}'
                    : 'Период',
              ),
              onPressed: _pickCustomRange,
              backgroundColor: _period == 'custom'
                  ? blueaccentColor.withValues(alpha: 0.2)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Всего оплачено: ${_formatRub(_paymentsTotalRub)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TexticonsColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Обновить',
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _payments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'История оплат подписки появится после следующих платежей.\n'
                      'Ранее оплаченные подписки могли не попасть в журнал.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TexticonsColor),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = _payments[index] as Map<String, dynamic>;
                    final amount = (row['amount_rub'] as num?)?.toInt() ?? 0;
                    final days = (row['days_added'] as num?)?.toInt() ?? 0;
                    final until = row['subscription_until']?.toString() ?? '';
                    final orderId = row['order_id']?.toString() ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _formatRub(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: TexticonsColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_formatDateTime(row['paid_at']?.toString())),
                          if (days > 0) Text('+$days дн.'),
                          if (until.isNotEmpty) Text('Подписка до $until'),
                          if (orderId.isNotEmpty)
                            Text(
                              'Платёж: $orderId',
                              style: const TextStyle(
                                fontSize: 12,
                                color: grayprprColor,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildIncomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPeriodFilters(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Итого: ${_formatRub(_incomeTotalRub)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: GreenColor,
                      ),
                    ),
                    Text(
                      '$_periodLabel · $_incomeCount сделок',
                      style: const TextStyle(color: grayprprColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Обновить',
                onPressed: () => _loadData(incomeOnly: true),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              _incomeItems.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'За выбранный период выполненных сделок нет.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: TexticonsColor),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _incomeItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = _incomeItems[index] as Map<String, dynamic>;
                        final amount =
                            (row['amount_rub'] as num?)?.toDouble() ?? 0;
                        final counterparty =
                            row['counterparty']?.toString() ?? 'Заказчик';
                        final about = row['about']?.toString() ?? '';
                        final time = row['income_time']?.toString() ??
                            row['end_time']?.toString();

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _formatRub(amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: GreenColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(counterparty),
                              Text(_dealSourceLabel(
                                  row['deal_source']?.toString())),
                              if (about.isNotEmpty) Text(about),
                              Text(
                                _formatDateTime(time),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: grayprprColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              if (_incomeLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color.fromARGB(120, 255, 255, 255),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        title: const Text(
          'Финансы',
          style: TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
        iconTheme: const IconThemeData(color: whiteprColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: whiteprColor,
          unselectedLabelColor: Color.fromARGB(180, 255, 255, 255),
          indicatorColor: whiteprColor,
          tabs: const [
            Tab(text: 'Подписки'),
            Tab(text: 'Доходы'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPaymentsTab(),
                    _buildIncomeTab(),
                  ],
                ),
      bottomNavigationBar: widget.showBottomNav
          ? const PerformerBottomNav(currentIndex: 2)
          : null,
    );
  }
}
