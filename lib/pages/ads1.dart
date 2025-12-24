import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/list_predloj_na_obj_isp.dart';
import 'package:crgtransp72app/pages/list_predloj_na_zayavki.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

import '../config.dart';
import '../design/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'changerol_page.dart';

void main() {
  runApp(const Ads1App());
}

class Ads1App extends StatelessWidget {
  const Ads1App({super.key});

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
    'Грузоперевозчик',
    'Спецтехника',
    'Грузчик'
  ];

  int idusers = 0;
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
    fetchAds(bd!, idusers);
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
          //userId = data['idusers'];
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

  Future<List> fetchAds(int bd, int idusers) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/get_ads.php',
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
          'Мои заявки8',
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
              MaterialPageRoute(builder: (context) => const changerol()));
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
                  if (_selectedType == 'Грузоперевозчик') bd = 1;
                  if (_selectedType == 'Спецтехника') bd = 2;
                  if (_selectedType == 'Грузчик') bd = 3;
                  //'Грузоперевозчик',
                  //'Спецтехника',
                  //'Грузчик'
                  fetchAds(bd!, idusers);
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
              future: fetchAds(bd!, idusers),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator()); // пока загружаются данные, показываем индикатор загрузки
                } else if (snapshot.data!.length > 0) {
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
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // Действия по редактированию
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDeleteDialog(
                                          context, int.parse(truck['id']), bd);
                                    },
                                  ),
                                  Expanded(
                                    // Добавлено, чтобы текст "На проверке/Опубликовано" не сжимал иконки
                                    child: Align(
                                      alignment: Alignment
                                          .centerRight, // Выравниваем текст справа
                                      child: Text(
                                        int.parse(truck['flag'].toString()) == 0
                                            ? "На проверке"
                                            : "Опубликовано",
                                        style: TextStyle(
                                          color: int.parse(truck['flag']
                                                      .toString()) ==
                                                  0
                                              ? Colors.red
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
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
                            if (truck['marka'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Марка:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['marka']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['godv'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Год выпуска:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['godv']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Город:',
                                      style:
                                          DefaultTextStyle.of(context).style),
                                  Text('${truck['city']}',
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
                                    Text('Макс. грузоподъемность:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['maxgruz']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['dkuzov'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Длинна кузова:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['dkuzov']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['shkuzov'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Ширина кузова:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['shkuzov']}',
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
                            if (truck['cenahaurs'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Цена за час:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['cenahaurs']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['cenasmena'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Цена за смену:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['cenasmena']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['cenakm'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Цена за км:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['cenakm']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((truck['offerf'] != null) &&
                                (truck['offerf'] != '0'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Заказов:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context,
                                                rootNavigator: true)
                                            .push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                list_predloj_na_zayavki(
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
                                      child: Text('${truck['offerf']}',
                                          style: const TextStyle(
                                            color: whiteprColor,
                                          )),
                                    ),
                                  ],
                                ),
                              ),
                            if ((truck['offerf'] != null) &&
                                (truck['offerf'] == '0'))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Заказов:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['offerf']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      });
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'Ошибка: ${snapshot.error}')); // обработка ошибок
                } else if (snapshot.data!.length == 0) {
                  return Center(
                      child: Text(
                          'Нет отзывов на заявки')); // если данных нет или массив пустой
                }
// By default, show a loading spinner.
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
    print(bd); // Url к вашему API
    try {
      final response = await http.post(
        Uri.parse(Config.baseUrl).replace(path: '/api/delete_truck.php'),
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
          fetchAds(bd, idusers);
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
