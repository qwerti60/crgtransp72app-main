import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/search_params.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/search/search_counts_client.dart';
import 'package:crgtransp72app/search/search_counts_helpers.dart';
import 'package:crgtransp72app/widgets/search_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Исполнитель → поиск заказов (вкладка «Заявки»).
class PerformerSearchScreen extends StatefulWidget {
  final bool showBottomNav;
  /// Внутри [zakaz_screen2] — меню снаружи; на результатах нужно своё.
  final bool embedInPerformerShell;
  final String? initialCity;
  final String? initialServiceName;
  final String? emptyResultsHint;

  const PerformerSearchScreen({
    super.key,
    this.showBottomNav = true,
    this.embedInPerformerShell = false,
    this.initialCity,
    this.initialServiceName,
    this.emptyResultsHint,
  });

  @override
  State<PerformerSearchScreen> createState() => _PerformerSearchScreenState();
}

class _PerformerSearchScreenState extends State<PerformerSearchScreen> {
  final _queryController = TextEditingController();
  final _priceController = TextEditingController();

  bool get _showNavOnResults =>
      widget.showBottomNav || widget.embedInPerformerShell;

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> cities = [];
  Map<String, int> _cityCounts = {};
  Map<String, int> _serviceCounts = {};
  String? _categoriesHint;
  int _userId = 0;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _countsLoading = false;

  String? selectedServiceName;
  String? selectedCityName;
  String _sort = 'relevance';

  @override
  void initState() {
    super.initState();
    selectedCityName = widget.initialCity?.trim().isNotEmpty == true
        ? widget.initialCity!.trim()
        : null;
    selectedServiceName = widget.initialServiceName?.trim().isNotEmpty == true
        ? widget.initialServiceName!.trim()
        : null;
    fetchData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });
    try {
      await _loadUserId();

      final responseServices = await http
          .get(Uri.parse('${Config.baseUrl}/api/getsearsh.php'))
          .timeout(kApiTimeout);
      if (responseServices.statusCode != 200) {
        throw Exception('Failed to load services.');
      }
      final decodedServices = json.decode(responseServices.body);

      final responseCities = await http
          .get(Uri.parse('${Config.baseUrl}/api/cities.php'))
          .timeout(kApiTimeout);
      if (responseCities.statusCode != 200) {
        throw Exception('Failed to load cities.');
      }
      final decodedCities = json.decode(responseCities.body);

      if (!mounted) return;
      setState(() {
        services = List<Map<String, dynamic>>.from(decodedServices);
        cities = List<Map<String, dynamic>>.from(decodedCities);
        _isLoading = false;
        _loadFailed = false;
      });

      await _fetchCounts();
    } catch (e) {
      debugPrint('PerformerSearchScreen fetchData: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _loadUserId() async {
    try {
      final token = await getSecurefcm_token();
      if (token == null || token.isEmpty) return;

      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/getuserinfo_order.php?token=$token'))
          .timeout(kApiTimeout);
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data is Map && data['idusers'] != null) {
        _userId = int.tryParse(data['idusers'].toString()) ?? 0;
      }
    } catch (e) {
      debugPrint('PerformerSearchScreen _loadUserId: $e');
    }
  }

  Future<void> _fetchCounts({bool servicesOnly = false}) async {
    if (!mounted || _userId <= 0) return;
    setState(() => _countsLoading = true);

    try {
      final result = await SearchCountsClient.fetch(
        userId: _userId,
        role: 'performer',
        city: selectedCityName,
        breakdown: true,
      );

      if (!mounted || result == null) {
        if (mounted) setState(() => _countsLoading = false);
        return;
      }

      final breakdownNames = selectedCityName != null
          ? result.servicesWithCountInCity(selectedCityName)
          : <String>[];

      if (!mounted) return;
      setState(() {
        if (!servicesOnly) {
          _cityCounts = result.cities;
        }
        if (selectedCityName != null && selectedCityName!.isNotEmpty) {
          _serviceCounts = result.services;
          _categoriesHint = searchOtherCategoriesHint(
            isPerformer: true,
            cityName: selectedCityName,
            cityCounts: _cityCounts,
            serviceCounts: _serviceCounts,
            breakdownNames: breakdownNames,
          );
        } else {
          _serviceCounts = {};
          _categoriesHint = null;
        }
        _countsLoading = false;
      });
    } catch (e) {
      debugPrint('PerformerSearchScreen _fetchCounts: $e');
      if (mounted) {
        setState(() => _countsLoading = false);
      }
    }
  }

  String _labelWithCount(String name, Map<String, int> counts) {
    final count = searchLookupCount(counts, name);
    return '$name ($count)';
  }

  List<Map<String, dynamic>> get _sortedServices =>
      searchSortServicesByCount(services, _serviceCounts);

  void _onCityChanged(String? value) {
    setState(() {
      selectedCityName = value;
      selectedServiceName = null;
      _serviceCounts = {};
      _categoriesHint = null;
    });
    if (value != null && value.isNotEmpty) {
      _fetchCounts(servicesOnly: true);
    }
  }

  void _submitSearch() {
    final query = _queryController.text.trim();
    final hasQuery = query.length >= 3;
    final hasCity = selectedCityName != null && selectedCityName!.isNotEmpty;
    final hasService =
        selectedServiceName != null && selectedServiceName!.isNotEmpty;

    if (!hasQuery && !(hasCity && hasService)) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Ошибка'),
          content: Text(
            'Введите запрос (от 3 символов), например «экскаватор в Тюмени», '
            'или выберите город и услугу.',
          ),
        ),
      );
      return;
    }

    final params = SearchParams(
      query: query,
      priceMax: _priceController.text,
      sort: _sort,
      freeText: hasQuery && !(hasCity && hasService),
    );

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => outputobz(
          nameImg: selectedServiceName ?? '',
          city: selectedCityName ?? '',
          showBottomNav: _showNavOnResults,
          performerBottomNavIndex: 1,
          searchParams: params,
          searchTitle: hasQuery ? query : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Поиск заявок',
          style: TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.emptyResultsHint != null)
              SearchInfoBanner(widget.emptyResultsHint!),
            const SearchInfoBanner(
              'Ищете заявки заказчиков. Число у города — сумма по всем категориям; '
              'у каждой услуги — только заявки этой категории.',
            ),
            const SearchInfoBanner(
              'Можно ввести запрос целиком, например «экскаватор в Тюмени», '
              'или выбрать город и услугу отдельно.',
            ),
            SearchFieldLabel('Поисковый запрос'),
            SearchQueryField(
              controller: _queryController,
              hint: 'Например: экскаватор в Тюмени',
            ),
            SearchFieldLabel('Город (необязательно)'),
            SearchDropdownField<String>(
              isLoading: _isLoading || _countsLoading,
              loadFailed: _loadFailed,
              isEmpty: cities.isEmpty,
              onRetry: fetchData,
              failedMessage: 'Не удалось загрузить города',
              hint: 'Выберите город или укажите в запросе',
              value: selectedCityName,
              onChanged: _onCityChanged,
              items: cities
                  .map(
                    (city) {
                      final name = city['name'] as String;
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(
                          _labelWithCount(name, _cityCounts),
                          style: kSearchFieldTextStyle,
                        ),
                      );
                    },
                  )
                  .toList(),
            ),
            SearchFieldLabel('Услуга (необязательно)'),
            if (_categoriesHint != null) SearchInfoBanner(_categoriesHint!),
            SearchDropdownField<String>(
              isLoading: _isLoading || _countsLoading,
              loadFailed: _loadFailed,
              isEmpty: services.isEmpty,
              onRetry: fetchData,
              failedMessage: 'Не удалось загрузить услуги',
              hint: selectedCityName == null || selectedCityName!.isEmpty
                  ? 'Сначала выберите город'
                  : 'Выберите услугу или укажите в запросе',
              value: selectedServiceName,
              onChanged: (v) => setState(() => selectedServiceName = v),
              items: _sortedServices
                  .map(
                    (service) {
                      final name = service['name'] as String;
                      final count = (selectedCityName != null &&
                              selectedCityName!.isNotEmpty)
                          ? searchLookupCount(_serviceCounts, name)
                          : 0;
                      return DropdownMenuItem<String>(
                        value: name,
                        child: SearchServiceCountLabel(
                          name: name,
                          count: count,
                        ),
                      );
                    },
                  )
                  .toList(),
            ),
            SearchSortChips(
              selected: _sort,
              onSelected: (v) => setState(() => _sort = v),
            ),
            SearchFiltersExpansion(
              children: [
                SearchFieldLabel('Бюджет заказа до, ₽'),
                SearchFieldBox(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: kSearchFieldTextStyle,
                    decoration: const InputDecoration(
                      hintText: 'Максимальная цена заказа',
                      hintStyle: kSearchFieldTextStyle,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            SearchPrimaryButton(onPressed: _submitSearch),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const PerformerBottomNav(currentIndex: 1)
          : null,
    );
  }
}
