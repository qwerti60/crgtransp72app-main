import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/OfferScreenZ.dart';
import 'package:crgtransp72app/pages/changerol_page.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../design/colors.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const outputobzlikes1(
    nameImg: '',
    base: 1,
  ));
}

class outputobzlikes1 extends StatelessWidget {
  final String nameImg;
  final int base;
  const outputobzlikes1({super.key, required this.nameImg, required this.base});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Info',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(nameImg: nameImg, base: base),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String nameImg;

  final int base;
  const MyHomePage({super.key, required this.nameImg, required this.base});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Ensure you specify MyHomePage as the generic type for State
  String? _selectedType;
  int? bd;

  final List<String> _typeOptions = [
    'Грузоперевозчик',
    'Спецтехника',
    'Грузчик'
  ];

  // No need for a separate nameImg declaration here since it's coming from the widget
  int? db;
  int? idUser;
  Uint8List? fotouser;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';

  @override
  void initState() {
    super
        .initState(); // Assign nameImg from widget to a local variable if needed:
    String nameImg = widget.nameImg;
    bd ??= widget.base;

    //super.initState();
    //   getUserData();
    getUserData();
    fetchAds(bd!, nameImg);
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

  Future<void> getUserDataAds(idUser) async {
    print(idUser);
    final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfoads.php?idusers=$idUser'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          idUser = data['idusers'] ?? "default_id";
          firstName = data['firstName'] ?? "Нет имени";
          lastName = data['lastName'] ?? "Нет фамилии";
          middleName = data['middleName'] ?? "Нет отчества";
          city = data['city'] ?? "Нет города";
          phone = data['phone'] ?? "Нет телефона";
          email = data['email'] ?? "Нет email";
          print(firstName);
        });

        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

//bool? isLiked = false;

  bool isLiked = false;

  Future<bool> toggleLike(String idUser, String id, int bd) async {
    //   final response = await http.get(Uri.parse(
    //     'http://yourdomain.com/toggle_like.php?idusers=$idUser&id=$id&bd=$bd'));
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/toggle_like1.php',
        queryParameters: {
          'idusers': idUser,
          'id': id,
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
        isLiked = parsed['success'];
        return isLiked;

        //getUserDataAds(idusers1);
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

  Future<List> fetchAds(int bd, String nameImg) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/getads_likes.php',
        queryParameters: {
          'idusers': idUser.toString(),
          'nameImg': nameImg,
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
        print('789');
        print(userId);
        print(bd);
        print(nameImg);
        return parsed;

        //getUserDataAds(idusers1);
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
          'Избранные объявления 1 ',
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
                  fetchAds(bd!, widget.nameImg);
                });
              },
              items: _typeOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              hint: const Text("Выберите раздел объявлений"),
            ),
          ),

          // Второй виджет при необходимости
          // Пример с FutureBuilder
          Expanded(
            // Оборачиваем в Expanded, если это в Column/Row
            child: FutureBuilder(
                future: fetchAds(bd!, widget.nameImg),
                builder: (context, snapshot) {
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('name', style: DefaultTextStyle.of(context).style),
                        Text(lastName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child:
                            CircularProgressIndicator()); // Показываем индикатор загрузки
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Произошла ошибка')); // Ошибка загрузки
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(
                        child: Text(
                            'В этом разделе нет объявлений')); // Данные загружены, но они пусты
                  } else {
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
                          String base64Stringf = '';
                          Uint8List? truckImage;
                          //checkLike(truck['iduser'], truck['id'], bd!);

                          // Проверяем существует ли изображение fotouser
                          if (truck['fotouser'] != null) {
                            base64Stringf =
                                truck['fotouser']; // Получаем строку base64
                            truckImage = base64Decode(
                                base64Stringf); // Декодируем строку в список байтов
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .stretch, // Для выравнивания содержимого в начале

                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 10, // Отступ сверху
                                  bottom: 10, // Отступ снизу
                                ),
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: base64Stringf != ''
                                      ? Image.memory(
                                          truckImage!,
                                          //truckImage=null;
                                          //fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/fotouser.png', // Путь к вашему изображению
                                          width: 100, // Ширина 100
                                          height: 100, // Высота 100
                                        ), //ндартное изображение
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center, // Выравнивание по центру
                                      children: <Widget>[
                                        IconButton(
                                          icon: Icon(
                                            truck['success'] == 'true'
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: truck['success'] == 'true'
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          onPressed: () async {
                                            await toggleLike(truck['iduser'],
                                                truck['id'], bd!);

                                            setState(() {
                                              // После асинхронной операции обновляем UI
                                            });
                                          },
                                        ),
                                        if (truck['firstName'] != null)
                                          Text(
                                            '${truck['firstName']} ${truck['lastName']}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _makePhoneCall(truck['phone']);
                                      },
                                      child: Row(
                                        children: <Widget>[
                                          const Icon(
                                              Icons.phone), // Иконка телефона
                                          const SizedBox(
                                              width:
                                                  4), // небольшой промежуток между иконкой и текстом
                                          Text(
                                            '${truck['phone']}', // текст, допустим, номер телефона
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
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
                                    autoPlay: true,
                                    enlargeCenterPage: true,
                                    viewportFraction:
                                        1.0, // Уже установлено, позволяет заполнить всю доступную ширину
                                    aspectRatio:
                                        2.0, // Можно адаптировать в зависимости от желаемых пропорций
                                  ),
                                ),
                              if (truck['maxgruz'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Создано :',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['created_at']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['vidt'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Вид техники:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['vidt']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['maxgruz'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Грузоподъемность:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['maxgruz']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['city'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Откуда забрать:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['city']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if ((truck['startdate'] != '0000-00-00') &&
                                  (truck['enddate'] != '0000-00-00'))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Дата погрузки с:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['startdate']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if ((truck['startdate'] != '0000-00-00') &&
                                  (truck['enddate'] != '0000-00-00'))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Дата погрузки до:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['enddate']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if ((truck['startdate'] == '0000-00-00') &&
                                  (truck['enddate'] == '0000-00-00'))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Дата погрузки:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      const Text('Как можно быстрее',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if ((truck['startdate'] == '0000-00-00') &&
                                  (truck['enddate'] != '0000-00-00'))
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Дата погрузки не позднее:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['enddate']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['city1'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Куда доставить:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['city1']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['vidk'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Вид кузова:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['vidk']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['zagr'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Загрузка:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['zagr']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['gruzch'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Кол-во грузчиков:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['gruzch']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['typepr'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Тип перевозки:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['typepr']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['cena'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Цена до:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['cena']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['about'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Подробнее о заказе:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['about']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              if (truck['enddatez'] != '0000-00-00')
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Прием заявок до:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text('${truck['enddatez']}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                margin: const EdgeInsets.only(top: 20.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                      style: TextButton.styleFrom(
                                        fixedSize:
                                            const Size(double.infinity, 50),
                                        foregroundColor: whiteprColor,
                                        backgroundColor: blueaccentColor,
                                        disabledForegroundColor: grayprprColor,
                                        shape: const BeveledRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(3))),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OfferScreenZ(
                                                userid: truck['id'], bd: bd),
                                          ),
                                        );
                                      },
                                      child: const Text('Предложить заказ')),
                                ),
                              ),
                            ],
                          );
                        });
                  }
                  if (snapshot.hasError) {
                    return Text("${snapshot.error}");
                  }
// By default, show a loading spinner.
                  return const CircularProgressIndicator();
                }),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  Future<void> showDeleteDialog(BuildContext context, int truckId) async {
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
      deleteTruck(truckId, context);
    }
  }

  Future<void> deleteTruck(int truckId, context) async {
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
          fetchAds(bd!, widget.nameImg);
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
