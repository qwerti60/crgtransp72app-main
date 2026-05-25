import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/outputobz.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // Для HTTP запросов
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Для форматирования чисел

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CityScreen(indexName: 'Эксковаторы'),
    );
  }
}

class CityScreen extends StatefulWidget {
  final String indexName;

  const CityScreen({super.key, required this.indexName});

  @override
  _CityScreenState createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  List<Map<String, dynamic>> cities = [];
  bool _isLoadingCities = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      await getUserData();
      await fetchCities();
    } catch (e) {
      debugPrint('Ошибка при получении данных: $e');
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
          _loadFailed = true;
        });
      }
    }
  }

  Future<void> fetchCities() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${Config.baseUrl}/api/get_cities.php',
        queryParameters: {
          'namex': widget.indexName,
          'useId': userId.toString(),
        },
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['cities'] != null) {
        var loadedCities =
            List<Map<String, dynamic>>.from(response.data['cities']);
        loadedCities.sort(
          (a, b) => a['city'].toString().compareTo(b['city'].toString()),
        );
        setState(() {
          cities = loadedCities;
          _isLoadingCities = false;
          _loadFailed = false;
        });
      } else {
        setState(() {
          _isLoadingCities = false;
          _loadFailed = true;
        });
      }
    } catch (e) {
      debugPrint('fetchCities error: $e');
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
          _loadFailed = true;
        });
      }
    }
  }

  int userId = 0;
  Future<void> getUserData() async {
    final token = await getSecurefcm_token();
    if (token == null) {
      return;
    }
    try {
      final response = await http
          .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'))
          .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          userId = data['idusers'];
        });
        print('вывод id: $userId');
        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
    } catch (e) {
      debugPrint('getUserData error: $e');
    }
  }

  Widget _buildBodyContent() {
    if (_isLoadingCities) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Не удалось загрузить список городов. Проверьте подключение к интернету.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoadingCities = true;
                    _loadFailed = false;
                  });
                  loadInitialData();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }
    if (cities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            Config.emptyCityListPlaceholder,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final halfWidth = width / 2;

                  return Row(children: [
                    // Левая колонка
                    Flexible(
                      flex: 1,
                      child: _buildGroupedList(halfWidth, leftHalf: true),
                    ),
                    // Правая колонка
                    Flexible(
                      flex: 1,
                      child: _buildGroupedList(halfWidth, leftHalf: false),
                    )
                  ]);
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Список городов ${widget.indexName}',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SafeArea(
        child: _buildBodyContent(),
      ),
      bottomNavigationBar: const PerformerBottomNav(currentIndex: 0),
    );
  }

  /// Виджет для группировки городов по первой букве
  Widget _buildGroupedList(double width, {required bool leftHalf}) {
    final filteredCities = leftHalf
        ? _whereIndexed(cities, (index, _) => index.isEven).toList()
        : _whereIndexed(cities, (index, _) => index.isOdd).toList();

    final groupedCities =
        groupBy(filteredCities, (Map<String, dynamic> city) => city['city'][0])
            .entries;

    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(height: 16),
      padding: const EdgeInsets.all(8.0),
      physics: BouncingScrollPhysics(),
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      primary: false,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      clipBehavior: Clip.none,
      addSemanticIndexes: true,
      itemCount: groupedCities.length,
      itemBuilder: (context, index) {
        final entry = groupedCities.elementAt(index);
        final firstLetter = entry.key.toUpperCase();
        final items = entry.value;

        return Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(firstLetter, // Первая буква крупной
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 24)), // Увеличили шрифт
            ),
            ...items
                .map((city) => Center(
                        child: InkWell(
                      onTap: city['city'] != Config.emptyCityListPlaceholder
                          ? () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => outputobz(
                                    nameImg: widget.indexName,
                                    city: city['city'],
                                    showBottomNav: true,
                                  ),
                                ),
                              );
                            }
                          : null, // Плейсхолдер «нет объявлений» — без перехода
                      child: Text(
                        city['city'] == Config.emptyCityListPlaceholder
                            ? city['city'].toString()
                            : "${city['city']} (${city['cnt']})",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )))
                .toList()
          ],
        );
      },
    );
  }

  static Map<K, List<V>> groupBy<V, K>(
      Iterable<V> iterable, K Function(V value) keyFunction) {
    final map = <K, List<V>>{};
    for (final v in iterable) {
      final k = keyFunction(v);
      map.putIfAbsent(k, () => [])..add(v);
    }
    return map;
  }

  // Метод фильтрации по индексам (перенесён в класс)
  List<E> _whereIndexed<E>(
      List<E> list, bool Function(int index, E element) test) {
    final result = <E>[];
    for (var i = 0; i < list.length; i++) {
      if (test(i, list[i])) result.add(list[i]);
    }
    return result;
  }
}

// Третье окно, куда передаются выбранные город и название индекса
class ThirdScreen extends StatelessWidget {
  final String indexName;
  final String city;

  const ThirdScreen({super.key, required this.indexName, required this.city});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Выбранный город")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Имя индекса: ${indexName}",
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(thickness: 2),
              Text("Город: ${city}",
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
