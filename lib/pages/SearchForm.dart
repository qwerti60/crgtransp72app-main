import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/network/api_timeout.dart';
import 'package:crgtransp72app/pages/HistortScreen1z.dart';
import 'package:crgtransp72app/pages/bmenucopy.dart';
import 'package:crgtransp72app/pages/scrmenu.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/widgets/async_list_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchForm extends StatefulWidget {
  final bool showBottomNav;

  const SearchForm({super.key, this.showBottomNav = true});

  @override
  _SearchFormState createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> cities = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  String? selectedServiceName;
  String? selectedCityName;

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
      debugPrint('SearchForm fetchData: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Поиск заявок',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Город(населенный пункт)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: AsyncListPlaceholder(
                isLoading: _isLoading,
                loadFailed: _loadFailed,
                isEmpty: cities.isEmpty,
                onRetry: fetchData,
                failedMessage: 'Не удалось загрузить города',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton(
                      isExpanded: true,
                      hint: const Text(
                        'Выберите город(населенный пункт)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black38,
                          fontSize: 16.0,
                        ),
                      ),
                      dropdownColor: grayprprColor,
                      value: selectedCityName,
                      onChanged: (newValue) {
                        setState(() {
                          selectedCityName = newValue;
                        });
                      },
                      items: cities
                          .map<DropdownMenuItem<String>>((dynamic city) {
                        return DropdownMenuItem(
                          value: city['name'],
                          child: Text(
                            city['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Услуги',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: AsyncListPlaceholder(
                isLoading: _isLoading,
                loadFailed: _loadFailed,
                isEmpty: services.isEmpty,
                onRetry: fetchData,
                failedMessage: 'Не удалось загрузить услуги',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton(
                      isExpanded: true,
                      hint: const Text(
                        'Выберите услугу',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black38,
                          fontSize: 16.0,
                        ),
                      ),
                      dropdownColor: grayprprColor,
                      value: selectedServiceName,
                      onChanged: (newValue) {
                        setState(() {
                          selectedServiceName = newValue;
                        });
                      },
                      items: services
                          .map<DropdownMenuItem<String>>((dynamic service) {
                        return DropdownMenuItem(
                          value: service['name'],
                          child: Text(
                            service['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 30.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    fixedSize: const Size(double.infinity, 50),
                    foregroundColor: whiteprColor,
                    backgroundColor: blueaccentColor,
                    disabledForegroundColor: grayprprColor,
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                  onPressed: () {
                    if (selectedServiceName != null &&
                        selectedCityName != null) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => outputobz(
                            nameImg: selectedServiceName!,
                            city: selectedCityName!,
                            showBottomNav: widget.showBottomNav,
                          ),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Ошибка'),
                          content:
                              const Text('Нужно выбрать и услугу, и город.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Найти'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const PerformerBottomNav(currentIndex: 1) : null,
    );
  }
}
