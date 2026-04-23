import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/outputob.dart';
import 'package:crgtransp72app/pages/scrmenu.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchFormisp extends StatefulWidget {
  const SearchFormisp({super.key});

  @override
  _SearchFormispState createState() => _SearchFormispState();
}

class _SearchFormispState extends State<SearchFormisp> {
  late List<Map<String, dynamic>> services = [];
  late List<Map<String, dynamic>> cities = [];

  String? selectedServiceName;
  String? selectedCityName;

  Future<void> fetchData() async {
    try {
      final responseServices =
          await http.get(Uri.parse(Config.baseUrl + '/api/getsearsh.php'));
      if (responseServices.statusCode == 200) {
        final decodedServices = json.decode(responseServices.body);
        print('Services: $decodedServices');
        setState(() {
          services = List<Map<String, dynamic>>.from(decodedServices);
        });
      } else {
        throw Exception('Failed to load services.');
      }

      final responseCities =
          await http.get(Uri.parse(Config.baseUrl + '/api/cities.php'));
      if (responseCities.statusCode == 200) {
        final decodedCities = json.decode(responseCities.body);
        print('Cities: $decodedCities');
        setState(() {
          cities = List<Map<String, dynamic>>.from(decodedCities);
        });
      } else {
        throw Exception('Failed to load cities.');
      }
    } catch (e) {
      print(e.toString()); // Логирование ошибки
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Загружаем данные при создании виджета
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
              child: cities.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
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
              child: services.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
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
                    print(selectedCityName);
                    print(selectedServiceName);
                    if (selectedServiceName != null &&
                        selectedCityName != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => /* HistortScreen1(
                              pageProfile: 'SearchFormisp',
                              userId1: selectedServiceName!,
                              orderId: selectedServiceName!,
                              parsedUserIdOk: ''),

                          */
                                  outputob(
                            // или outputobz, если класс с маленькой буквы
                            nameImg: selectedServiceName!,
                            city: selectedCityName!,
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
    );
  }
}
