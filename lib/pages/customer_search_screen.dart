import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/search_params.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/outputob.dart';
import 'package:crgtransp72app/search/search_counts_client.dart';
import 'package:crgtransp72app/search/search_counts_helpers.dart';
import 'package:crgtransp72app/services/location_service.dart';
import 'package:crgtransp72app/widgets/search_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Заказчик → поиск исполнителей (вкладка «Заказы»).
class CustomerSearchScreen extends StatefulWidget {
  final bool embedInCustomerShell;
  /// Своё нижнее меню (для экранов, открытых поверх shell через push).
  final bool showBottomNav;
  final String? initialCity;
  final String? initialServiceName;
  final String? initialPriceMax;
  final String? emptyResultsHint;

  const CustomerSearchScreen({
    super.key,
    this.embedInCustomerShell = false,
    this.showBottomNav = false,
    this.initialCity,
    this.initialServiceName,
    this.initialPriceMax,
    this.emptyResultsHint,
  });

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final _queryController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityToController = TextEditingController();

  /// Результаты открываются поверх shell (rootNavigator) — нужно своё меню.
  bool get _showNavOnResults =>
      widget.showBottomNav || widget.embedInCustomerShell;

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
  bool _nearMe = false;
  bool _nearMeLoading = false;
  double? _lat;
  double? _lng;
  int _radiusKm = 30;
  String? _nearMeStatus;

  @override
  void initState() {
    super.initState();
    selectedCityName = widget.initialCity?.trim().isNotEmpty == true
        ? widget.initialCity!.trim()
        : null;
    selectedServiceName = widget.initialServiceName?.trim().isNotEmpty == true
        ? widget.initialServiceName!.trim()
        : null;
    if (widget.initialPriceMax?.trim().isNotEmpty == true) {
      _priceController.text = widget.initialPriceMax!.trim();
    }
    fetchData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _priceController.dispose();
    _cityToController.dispose();
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
          .get(Uri.parse('${Config.apiBase}/getsearsh.php'))
          .timeout(kApiTimeout);
      if (responseServices.statusCode != 200) {
        throw Exception('Failed to load services.');
      }
      final decodedServices = json.decode(responseServices.body);

      final responseCities = await http
          .get(Uri.parse('${Config.apiBase}/cities.php'))
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
      debugPrint('CustomerSearchScreen fetchData: $e');
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
          .get(Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'))
          .timeout(kApiTimeout);
      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data is Map && data['idusers'] != null) {
        _userId = int.tryParse(data['idusers'].toString()) ?? 0;
      }
    } catch (e) {
      debugPrint('CustomerSearchScreen _loadUserId: $e');
    }
  }

  Future<void> _fetchCounts({bool servicesOnly = false}) async {
    if (!mounted) return;
    setState(() => _countsLoading = true);

    try {
      final result = await SearchCountsClient.fetch(
        userId: _userId,
        role: 'customer',
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
            isPerformer: false,
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
      debugPrint('CustomerSearchScreen _fetchCounts: $e');
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

  Future<void> _onNearMeChanged(bool enabled) async {
    if (!enabled) {
      setState(() {
        _nearMe = false;
        _lat = null;
        _lng = null;
        _nearMeStatus = null;
        if (_sort == 'distance') {
          _sort = 'relevance';
        }
      });
      return;
    }

    setState(() {
      _nearMeLoading = true;
      _nearMeStatus = 'Определяем местоположение…';
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _nearMe = true;
        _lat = pos.latitude;
        _lng = pos.longitude;
        _sort = 'distance';
        _nearMeStatus =
            'Местоположение получено (±${_radiusKm} км)';
        _nearMeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nearMe = false;
        _lat = null;
        _lng = null;
        _nearMeLoading = false;
        _nearMeStatus = null;
      });
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Геолокация'),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _submitSearch() {
    final query = _queryController.text.trim();
    final hasQuery = query.length >= 3;
    final hasCity = selectedCityName != null && selectedCityName!.isNotEmpty;
    final hasService =
        selectedServiceName != null && selectedServiceName!.isNotEmpty;
    final hasNearMe = _nearMe && _lat != null && _lng != null;
    final canSearch = hasQuery ||
        (hasCity && hasService) ||
        (hasNearMe && hasService);

    if (!canSearch) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text(
            hasNearMe
                ? 'Выберите услугу или введите запрос (от 3 символов).'
                : 'Введите запрос (от 3 символов), например «экскаватор в Тюмени», '
                    'или выберите город и услугу, либо включите «Рядом со мной».',
          ),
        ),
      );
      return;
    }

    final params = SearchParams(
      query: query,
      cityTo: _cityToController.text,
      priceMax: _priceController.text,
      sort: _sort,
      freeText: hasQuery && !((hasCity || hasNearMe) && hasService),
      nearMe: hasNearMe,
      lat: _lat,
      lng: _lng,
      radiusKm: _radiusKm,
    );

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => outputob(
          nameImg: selectedServiceName ?? '',
          city: hasNearMe ? '' : (selectedCityName ?? ''),
          showBottomNav: _showNavOnResults,
          customerBottomNavIndex: 1,
          useCustomerNavigation: true,
          searchParams: params,
          searchTitle: hasQuery
              ? query
              : (hasNearMe ? 'Рядом · ${_radiusKm} км' : null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Поиск исполнителей',
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
              'Ищете объявления исполнителей. Число у города — сумма по всем категориям.',
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
            SearchNearMePanel(
              enabled: _nearMe,
              radiusKm: _radiusKm,
              loading: _nearMeLoading,
              statusText: _nearMeStatus,
              onEnabledChanged: _onNearMeChanged,
              onRadiusChanged: (km) => setState(() {
                _radiusKm = km;
                if (_nearMe) {
                  _nearMeStatus = 'Местоположение получено (±$km км)';
                }
              }),
            ),
            SearchSortChips(
              selected: _sort,
              onSelected: (v) => setState(() => _sort = v),
            ),
            SearchFiltersExpansion(
              children: [
                SearchFieldLabel('Куда доставить (для грузоперевозок)'),
                SearchFieldBox(
                  child: TextField(
                    controller: _cityToController,
                    style: kSearchFieldTextStyle,
                    decoration: const InputDecoration(
                      hintText: 'Город назначения',
                      hintStyle: kSearchFieldTextStyle,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SearchFieldLabel('Бюджет до, ₽'),
                SearchFieldBox(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: kSearchFieldTextStyle,
                    decoration: const InputDecoration(
                      hintText: 'Максимальная цена',
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
          ? const CustomerBottomNav(currentIndex: 1)
          : null,
    );
  }
}
