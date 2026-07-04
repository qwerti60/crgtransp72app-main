import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/search_params.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/widgets/search_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Исполнитель → поиск заказов (вкладка «Заявки»).
class PerformerSearchScreen extends StatefulWidget {
  final bool showBottomNav;
  final String? initialCity;
  final String? initialServiceName;
  final String? emptyResultsHint;

  const PerformerSearchScreen({
    super.key,
    this.showBottomNav = true,
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

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> cities = [];
  bool _isLoading = true;
  bool _loadFailed = false;

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
    } catch (e) {
      debugPrint('PerformerSearchScreen fetchData: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
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

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => outputobz(
          nameImg: selectedServiceName ?? '',
          city: selectedCityName ?? '',
          showBottomNav: true,
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
              isLoading: _isLoading,
              loadFailed: _loadFailed,
              isEmpty: cities.isEmpty,
              onRetry: fetchData,
              failedMessage: 'Не удалось загрузить города',
              hint: 'Выберите город или укажите в запросе',
              value: selectedCityName,
              onChanged: (v) => setState(() => selectedCityName = v),
              items: cities
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city['name'] as String,
                      child: Text(city['name'], style: kSearchFieldTextStyle),
                    ),
                  )
                  .toList(),
            ),
            SearchFieldLabel('Услуга (необязательно)'),
            SearchDropdownField<String>(
              isLoading: _isLoading,
              loadFailed: _loadFailed,
              isEmpty: services.isEmpty,
              onRetry: fetchData,
              failedMessage: 'Не удалось загрузить услуги',
              hint: 'Выберите услугу или укажите в запросе',
              value: selectedServiceName,
              onChanged: (v) => setState(() => selectedServiceName = v),
              items: services
                  .map(
                    (service) => DropdownMenuItem<String>(
                      value: service['name'] as String,
                      child:
                          Text(service['name'], style: kSearchFieldTextStyle),
                    ),
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
