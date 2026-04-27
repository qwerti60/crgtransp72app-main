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
  void initState() {
    super.initState();
    loadInitialData(); // Новый метод, объединяющий загрузку данных
  }

  Future<void> loadInitialData() async {
    try {
      await getUserData(); // Сначала получаем данные пользователя
      await fetchCities(); // Затем загружаем города
    } catch (e) {
      // Обработка возможных ошибок
      debugPrint('Ошибка при получении данных: $e');
    }
  }

  Future<void> fetchCities() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://ivnovav.ru/api/get_cities.php',
        queryParameters: {
          'namex': widget.indexName,
          'useId': userId.toString()
        }, // имя параметра
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['cities'] != null) {
        setState(() {
          cities = List.from(response.data['cities'])
            ..sort((a, b) => a['city']
                .toString()
                .compareTo(b['city'].toString())); // Сортируем по алфавиту
        });
      }
    } catch (e) {
      print('fetchCities error: $e');
    }

    print('d123 ${widget.indexName}');
    print('d123 ${cities}');
    print('d123 ${userId.toString()}');
  }

  int userId = 0;
  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Список городов ${widget.indexName}',
          style: const TextStyle(
            color: Colors.white, // цвет текста
          ),
        ),
        backgroundColor: Colors.blue.shade700, // цвет панели
      ),
      body: SafeArea(
        // Безопасная зона только для содержимого
        child: cities.isEmpty
            ? Center(
                child:
                    CircularProgressIndicator()) // Пока загружается показываем индикатор загрузки
            : LayoutBuilder(
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
              ),
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
                      onTap: city['city'] != 'Город не найден'
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => outputobz(
                                          nameImg: widget.indexName,
                                          city: city['city'],
                                        )),
                              );
                            }
                          : null, // Исключаем onTap для записи "Город не найден"
                      child: Text(
                        "${city['city']} (${city['cnt']})",
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
