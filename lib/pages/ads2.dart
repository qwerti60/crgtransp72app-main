import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/changerol_page.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/list_predloj_na_obj_isp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

import '../config.dart';
import '../design/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const Ads2App());
}

class Ads2App extends StatelessWidget {
  const Ads2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Info',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State {
  String? _selectedType;
  int? bd;

  final List<String> _typeOptions = [
    'Ищу грузоперевозчика',
    'Ищу спецтехнику',
    'Ищу грузчика'
  ];

  int? idusers;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  @override
  void initState() {
    bd ??= 1;
    super.initState();
    getUserData();
    fetchAds(bd!);
  }

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
          idusers = data['idusers'];
          firstName = data['firstName'];
          lastName = data['lastName'];
          middleName = data['middleName'];
          city = data['city'];
          phone = data['phone'];
          email = data['email'];
          print(idusers);
        });

        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<List> fetchAds(int bd) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/zak_get_ads.php',
        queryParameters: {
          'idusers': idusers.toString(),
          'bd': bd
              .toString(), // Добавляем переменную bd как строку в параметры запроса
        },
      ),
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Пустой ответ от сервера');
      }
      try {
        final parsed = json.decode(response.body);
        return parsed;
      } catch (e) {
        print('Ошибка декодирования: $e');
        print('Ответ сервера: ${response.body}');
        throw Exception('Ошибка формата ответа');
      }
      // Это излишне, поскольку возвращение происходит в блоке try выше
      // return json.decode(response.body);
    } else {
      throw Exception('Failed to load ads');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Мои объявления4',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      // Добавление FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Действие, производимое при нажатии на кнопку
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const changerol1()));
          print('Нажата плавающая кнопка');
        },
        backgroundColor:
            Colors.blueAccent, // Поправил цвет на стандартный из Flutter
        child: const Icon(Icons.add), // Иконка на кнопке
      ),

      // Использование Column для размещения нескольких виджетов в body
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16), // Применение отступа
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              value: _selectedType,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedType = newValue;
                  print(_selectedType);
                  if (_selectedType == 'Ищу грузоперевозчика') bd = 1;
                  if (_selectedType == 'Ищу спецтехнику') bd = 2;
                  if (_selectedType == 'Ищу грузчика') bd = 3;
                  //'Грузоперевозчик',
                  //'Спецтехника',
                  //'Грузчик'
                  fetchAds(bd!);
                });
              },
              items: _typeOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              hint: const Text("Выберите тип"),
            ),
          ),

          // Второй виджет при необходимости
          // Пример с FutureBuilder
          Expanded(
            // Оборачиваем в Expanded, если это в Column/Row
            child: FutureBuilder(
              future: fetchAds(bd!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        var truck = snapshot.data![index];
                        List<Uint8List> images = [];

                        // Добавляем изображения в список images, только если они не null
                        for (var imgKey in ['img1', 'img2', 'img3', 'img4']) {
// В цикле forEach
                          if (truck[imgKey] != null) {
                            String base64String =
                                truck[imgKey]; // Получаем строку base64
                            Uint8List bytes = base64Decode(
                                base64String); // Декодируем строку в список байтов
                            images.add(
                                bytes); // Добавляем полученный список байтов в список изображений
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Для выравнивания содержимого в начале
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      20.0), // Добавление горизонтальных отступов слева и справа
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .end, // Равнение элементов в конце (справа)
                                children: [
                                  /*IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // Действия по редактированию
                                    },
                                  ),*/

                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDeleteDialog(
                                          context, int.parse(truck['id']), bd);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (images
                                .isNotEmpty) // Условие проверки наличия изображений
                              CarouselSlider.builder(
                                itemCount: images.length,
                                itemBuilder: (BuildContext context,
                                        int itemIndex, int pageViewIndex) =>
                                    SizedBox(
                                  width: MediaQuery.of(context)
                                      .size
                                      .width, // Задаем ширину равную ширине экрана
                                  child: Image.memory(
                                    images[itemIndex],
                                    fit: BoxFit
                                        .cover, // Измените здесь на BoxFit.fill, если хотите, чтобы картинка растягивалась без сохранения пропорций
                                  ),
                                ),
                                options: CarouselOptions(
                                  autoPlay: false,
                                  enlargeCenterPage: true,
                                  viewportFraction:
                                      1.0, // Уже установлено, позволяет заполнить всю доступную ширину
                                  aspectRatio:
                                      2.0, // Можно адаптировать в зависимости от желаемых пропорций
                                ),
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Создано :',
                                      style:
                                          DefaultTextStyle.of(context).style),
                                  Text('${truck['created_at']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if (truck['vidt'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Вид техники:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['vidt']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['maxgruz'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Грузоподъемность:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['maxgruz']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['city'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Откуда забрать:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['city']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((truck['startdate'] != '0000-00-00') &&
                                (truck['enddate'] != '0000-00-00'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Дата погрузки с:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['startdate']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((truck['startdate'] != '0000-00-00') &&
                                (truck['enddate'] != '0000-00-00'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Дата погрузки до:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['enddate']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((truck['startdate'] == '0000-00-00') &&
                                (truck['enddate'] == '0000-00-00'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Дата погрузки:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    const Text('Как можно быстрее',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((truck['startdate'] == '0000-00-00') &&
                                (truck['enddate'] != '0000-00-00'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Дата погрузки не позднее:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['enddate']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['city1'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Куда доставить:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['city1']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['vidk'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Вид кузова:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['vidk']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['zagr'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Загрузка:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['zagr']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['gruzch'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Кол-во грузчиков:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['gruzch']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['typepr'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Тип перевозки:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['typepr']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['cena'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Цена до:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['cena']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['about'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Подробнее о заказе:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['about']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['enddatez'] != '0000-00-00')
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Прием заявок до:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['enddatez']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((truck['offer'] != null) &&
                                (truck['offer'] != '0'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Откликов:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                list_predloj_na_obj_isp(
                                              nameImg: truck['id'].toString(),
                                              bd: bd!,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            blueaccentColor, // Это сделает кнопку синей
                                      ),
                                      child: Text('${truck['offer']}',
                                          style: const TextStyle(
                                            color: whiteprColor,
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            if ((truck['offer'] != null) &&
                                (truck['offer'] == '0'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Откликов:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['offer']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      });
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
// By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showDeleteDialog(BuildContext context, int truckId, bd) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить объявление безвозвратно?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Да'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      deleteTruck(truckId, context, bd);
    }
  }

  Future<void> deleteTruck(int truckId, context, int bd) async {
    print('bd'); // Url к вашему API
    print(bd); // Url к вашему API
    print(truckId.toString()); // Url к
    try {
      final response = await http.post(
        Uri.parse(Config.baseUrl).replace(path: '/api/delete_zakaz.php'),
        body: {
          'id': truckId.toString(),
          'bd': bd.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Успешно удалено, можно показать уведомление
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Объявление успешно удалёно!'),
          backgroundColor: Colors.green,
        ));

        ///initState();
        setState(() {
          fetchAds(bd);
        });
      } else {
        // Ошибка, можно показать сообщение об ошибке

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ошибка при удалении объявления!'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      // Обработка исключений при вызове http
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Возникла проблема при удалении объявления!'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
