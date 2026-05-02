import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/menuzak.dart';
import 'package:crgtransp72app/pages/review_screen.dart';
import 'package:crgtransp72app/pages/sendNotification.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../design/colors.dart';
import 'like_helper.dart';

import 'changerol_page.dart';
import 'sendNotification.dart';

class list_predloj_na_zayavki extends StatelessWidget {
  final String nameImg;
  final int bd; // добавляем параметр base

  const list_predloj_na_zayavki({
    Key? key,
    required this.nameImg,
    required this.bd, // добавляем обязательное поле
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Info',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(nameImg: nameImg, bd: bd),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String nameImg;
  final int bd;
  const MyHomePage({super.key, required this.nameImg, required this.bd});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Ensure you specify MyHomePage as the generic type for State
  String? _selectedType;

  final List<String> _typeOptions = [
    'Грузоперевозчик',
    'Спецтехника',
    'Грузчик'
  ];

  // No need for a separate nameImg declaration here since it's coming from the widget

  int? idUser;
  Uint8List? fotouser;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  String namefirm = '';
  String innStr = '';
  String ogrnStr = '';
  String kppStr = '';

  @override
  void initState() {
    super
        .initState(); // Assign nameImg from widget to a local variable if needed:
    String nameImg = widget.nameImg;
    int bd = widget.bd;
    //super.initState();
    getUserData();
    fetchAds(bd, nameImg);
  }

  int userId = 0;
  final Map<String, bool> _likedOverrides = {};

  bool _isLikedValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  bool _likedForTruck(Map truck) {
    final String key = (truck['id'] ?? '').toString();
    if (_likedOverrides.containsKey(key)) {
      return _likedOverrides[key]!;
    }
    return _isLikedValue(truck['success']);
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('https://ivnovav.ru/api/getuserinfo.php?token=$token'));

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
        Uri.parse('https://ivnovav.ru/api/getuserinfoads.php?idusers=$idUser'));

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
          namefirm = data['namefirm'] ?? "Нет назвония фирмы";
          innStr = data['innStr'] ?? "Нет ИНН";
          ogrnStr = data['ogrnStr'] ?? "Нет ОГРН";
          kppStr = data['kppStr'] ?? "Нет КПП";
          print(namefirm);
        });

        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<List> fetchAds(int bd, String nameImg) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/list_predloj_na_zayavki_new.php',
        queryParameters: {
          'usersid': userId.toString(),
          'idusers': idUser,
          'nameImg': nameImg,
          'debug': '1',
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
        if (parsed is List) {
          return parsed;
        }
        if (parsed is Map<String, dynamic>) {
          final debug = parsed['debug'];
          if (debug != null) {
            print('[list_predloj_na_zayavki][debug] $debug');
          }
          final data = parsed['data'];
          if (data is List) {
            return data;
          }
        }
        throw Exception('Неожиданный формат ответа');

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

// 1. Обновлённая сигнатура
  Future<void> uploadData(int bd, String nameImg, int userID) async {
    final uri = Uri.parse('http://ivnovav.ru/api/updatePriemZak.php');

    try {
      final response = await http.post(uri,
          body: {'idusers': userID.toString(), 'nameImg': nameImg, 'bd': bd});

      if (response.statusCode == 200) {
        print(userId.toString());
        print(widget.nameImg);
        print(idUser);
        print(bd);
        _showSnack(context, 'Данные успешно загружены!!!');
        // _showDialog(context, 'Успех', 'Данные успешно загружены!');
      } else {
        _showSnack(context,
            'Ошибка загрузки: ${response.statusCode}\n${response.body}');
        // _showDialog(context, 'Ошибка',
        //     'Код: ${response.statusCode}\n${response.body}');
      }
    } catch (err) {
      _showSnack(context, 'Ошибка сети: $err');
      // _showDialog(context, 'Ошибка сети', err.toString());
    }
  }

  Future<void> updateOffer(int bd, String nameImg, int userID, iduserp) async {
    final uri =
        Uri.parse('http://ivnovav.ru/api/updatePriemZak.php'); // Новый endpoint

    try {
      final response = await http.post(uri, body: {
        'idusers': widget.nameImg, // Пользовательский ID
        'bd': bd.toString(), // Поле bd
        'iduserp': iduserp.toString() // Поле bd
      });
      print('ttt');
      print(userId.toString());
      print(widget.nameImg);
      //       print(idUser);
      print(iduserp);
      //  print(id);
      if (response.statusCode == 200) {
        _showSnack(context, 'Данные успешно загружены!!!');
        setState(() {
          //raw = data['isp']; // что-то, приходящее с сервера
        });
      } else {
        _showSnack(context,
            'Ошибка обновления: ${response.statusCode}\n${response.body}');
      }
    } catch (err) {
      _showSnack(context, 'Ошибка сети: $err');
    }
  }

// SnackBar
  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  //Future<bool> checkIsp(String userId, Db bd, String idUserP) async {

  Future<bool> checkIsp(String idUser, int bd, int idUserP) async {
    final response = await http.post(
      Uri.parse('http://ivnovav.ru/api/check_isp.php'),
      body: {
        'idusers': idUser.toString(),
        'bd': bd.toString(),
        'iduserp': idUserP.toString(),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load data');
    }

    final data = json.decode(response.body); // Map<String, dynamic>

    final dynamic raw = data['isp']; // что-то, приходящее с сервера
    print(raw);
    print('Это текст idUser.toString(): ${idUser.toString()}');
    print('Это текст bd.toString(): ${bd.toString()}');
    print('Это текст idUserP.toString(): ${idUserP.toString()}');
    print('Это текст api: ${raw}');

    // Приводим к bool
    if (raw is bool) return raw; // true / false
    if (raw is int) return raw != 0; // 1 / 0
    if (raw is String) return raw == '1' || raw.toLowerCase() == 'true';

    // Если формат неожиданный – сигнализируем об ошибке
    throw Exception('Unexpected value of "isp": $raw');
  }

// Функция для отправки пуш-уведомления пользователю

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Предложения заказчиков',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),

      // Использование Column для размещения нескольких виджетов в body
      body: Column(
        children: [
          // Второй виджет при необходимости
          // Пример с FutureBuilder
          Expanded(
            // Оборачиваем в Expanded, если это в Column/Row
            child: FutureBuilder(
              future: fetchAds(widget.bd, widget.nameImg),
              builder: (context, snapshot) {
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('name', style: DefaultTextStyle.of(context).style),
                      Text(lastName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );

                if (snapshot.hasData) {
                  final items = (snapshot.data as List).cast<dynamic>();
                  print(
                      '[list_predloj_na_zayavki] Найдено предложений: ${items.length}');
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'В этом разделе нет предложений',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              var truck = items[index];
                              if (truck is! Map) {
                                return const SizedBox.shrink();
                              }
                              if (truck == null)
                                Text(
                                  'В этом разделе нет объявлений',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                );
                              List<Uint8List> images = [];

                              // Добавляем изображения в список images, только если они не null
                              for (var imgKey in [
                                'img1',
                                'img2',
                                'img3',
                                'img4'
                              ]) {
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
                              // Проверяем существует ли изображение fotouser
                              if (truck['fotouser'] != null) {
                                base64Stringf =
                                    truck['fotouser']; // Получаем строку base64
                                try {
                                  truckImage = base64Decode(base64Stringf);
                                } catch (_) {
                                  truckImage = null;
                                }
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
                                      child: (base64Stringf != '' &&
                                              truckImage != null)
                                          ? Image.memory(
                                              truckImage,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                _likedForTruck(truck)
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: _likedForTruck(truck)
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                              onPressed: () async {
                                                if (userId <= 0) return;
                                                final String key =
                                                    (truck['id'] ?? '')
                                                        .toString();
                                                final dynamic ownerId =
                                                    truck['iduser'] ??
                                                        truck['idusers'] ??
                                                        truck['iduserp'];
                                                if (ownerId == null) return;

                                                final bool currentLiked =
                                                    _likedForTruck(truck);
                                                setState(() {
                                                  _likedOverrides[key] =
                                                      !currentLiked;
                                                });

                                                final bool updated =
                                                    await toggleLike(
                                                  ownerId,
                                                  truck['id'],
                                                  widget.bd,
                                                );
                                                if (!mounted) return;
                                                setState(() {});
                                                setState(() {
                                                  _likedOverrides[key] =
                                                      updated;
                                                });
                                              },
                                            ),
                                            if (truck['firstName'] != null)
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${truck['firstName']} ${truck['lastName']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Row(
                                                        children: List.generate(
                                                            5, (index) {
                                                          return Icon(
                                                            index <
                                                                    (truck['rating'] ??
                                                                        0)
                                                                ? Icons.star
                                                                : Icons
                                                                    .star_border,
                                                            color: Colors.amber,
                                                            size: 16,
                                                          );
                                                        }),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${truck['rating'] ?? 0.0}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  ReviewScreen(
                                                                userId: truck[
                                                                        'iduserp']
                                                                    .toString(),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: Row(
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .comment_outlined,
                                                              size: 16,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            const SizedBox(
                                                                width: 2),
                                                            Text(
                                                              '${truck['reviewsCount'] ?? 0}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _makePhoneCall(
                                                (truck['phone'] ?? '')
                                                    .toString());
                                          },
                                          child: Row(
                                            children: [
                                              const Icon(Icons.phone),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${truck['phone'] ?? ''}',
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
                                              int itemIndex,
                                              int pageViewIndex) =>
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
                                  if (truck['namefirm'] == null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('',
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style),
                                          Text('Частное лицо',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (truck['namefirm'] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Компания:',
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style),
                                          Text('${truck['namefirm']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (truck['innStr'] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('ИНН:',
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style),
                                          Text('${truck['innStr']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (truck['ogrnStr'] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('ОГРН:',
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style),
                                          Text('${truck['ogrnStr']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  if (truck['kppStr'] != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('КПП:',
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style),
                                          Text('${truck['kppStr']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Город:',
                                            style: DefaultTextStyle.of(context)
                                                .style),
                                        Text('${truck['city']}',
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
                                          Text('Прелагаемая стоимость:',
                                              style:
                                                  DefaultTextStyle.of(context)
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
                                          Text('Предлагаю:',
                                              style:
                                                  DefaultTextStyle.of(context)
                                                      .style),
                                          Text('${truck['about']}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    margin: const EdgeInsets.only(top: 20.0),
                                    child: FutureBuilder<bool>(
                                      future: checkIsp(
                                          widget.nameImg,
                                          widget.bd,
                                          truck[
                                              'iduserp']), // Функция проверки наличия оферты
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const SizedBox(
                                              height: 50,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()));
                                        }

                                        final bool hasOffer =
                                            snapshot.data ?? false;

                                        Widget buttonWidget = SizedBox(
                                          width: double
                                              .infinity, // Кнопка растянута на всю доступную ширину
                                          child: TextButton(
                                            style: TextButton.styleFrom(
                                              fixedSize: const Size(
                                                  double.infinity, 50),
                                              foregroundColor: whiteprColor,
                                              backgroundColor: blueaccentColor,
                                              disabledForegroundColor:
                                                  grayprprColor,
                                              shape:
                                                  const BeveledRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  3))),
                                            ),
                                            onPressed: () async {
                                              if (hasOffer) {
                                                await updateOffer(
                                                    widget.bd,
                                                    widget.nameImg,
                                                    userId,
                                                    truck['iduserp']);
                                                try {
                                                  final response =
                                                      await http.post(
                                                    Uri.parse(
                                                        '${Config.baseUrl}/api/notification.php'),
                                                    body: {
                                                      'iduserp':
                                                          truck['iduserp']
                                                              .toString(),
                                                    },
                                                    headers: {
                                                      'Content-Type':
                                                          'application/x-www-form-urlencoded', // явно указываем тип данных
                                                    },
                                                  );
                                                  print(truck['iduserp']);
                                                  debugPrint(
                                                      'Status: ${response.statusCode}'); // 2. Лог кода ответа
                                                  debugPrint(
                                                      'Body : ${response.body}'); // 3. Лог тела ответа

                                                  if (response.statusCode ==
                                                      200) {
                                                    final Map data = jsonDecode(
                                                        response.body) as Map;
                                                    if (data['fcm_token'] !=
                                                        null) {
                                                      try {
                                                        await sendNotificationV1(
                                                          //'', // первый позиционный параметр data
                                                          deviceToken: data[
                                                              'fcm_token'], // обязательный именованный параметр
                                                          title:
                                                              'Привет от crgtransp72app!',
                                                          body:
                                                              'Исполнитель откакзался от предложения!',
                                                        );
                                                        print(
                                                            'Уведомление отправлено');
                                                      } catch (e) {
                                                        print(
                                                            'Ошибка при отправке: $e');
                                                      }
                                                    } else {
                                                      _showSnack(context,
                                                          'Токен не найден в ответе');
                                                    }
                                                  } else {
                                                    _showSnack(context,
                                                        'Сервер вернул: ${response.statusCode}');
                                                  }
                                                } catch (e, s) {
                                                  debugPrint(
                                                      'Ошибка сети: $e\n$s'); // 4. Ловим исключения
                                                  _showSnack(
                                                      context, 'Ошибка: $e');
                                                }
                                              } else {
                                                await updateOffer(
                                                    widget.bd,
                                                    widget.nameImg,
                                                    userId,
                                                    truck['iduserp']);

                                                try {
                                                  final response =
                                                      await http.post(
                                                    Uri.parse(
                                                        '${Config.baseUrl}/api/notification.php'),
                                                    body: {
                                                      'iduserp':
                                                          truck['iduserp']
                                                              .toString(),
                                                    },
                                                    headers: {
                                                      'Content-Type':
                                                          'application/x-www-form-urlencoded', // явно указываем тип данных
                                                    },
                                                  );
                                                  print(truck['iduserp']);
                                                  debugPrint(
                                                      'Status: ${response.statusCode}'); // 2. Лог кода ответа
                                                  debugPrint(
                                                      'Body : ${response.body}'); // 3. Лог тела ответа

                                                  if (response.statusCode ==
                                                      200) {
                                                    final Map data = jsonDecode(
                                                        response.body) as Map;
                                                    if (data['fcm_token'] !=
                                                        null) {
                                                      try {
                                                        await sendNotificationV1(
                                                          //'', // первый позиционный параметр data
                                                          deviceToken: data[
                                                              'fcm_token'], // обязательный именованный параметр
                                                          title:
                                                              'Привет от crgtransp72app!',
                                                          body:
                                                              'Ваш зкакз принят исполнителем!',
                                                        );
                                                        print(
                                                            'Уведомление отправлено');
                                                      } catch (e) {
                                                        print(
                                                            'Ошибка при отправке: $e');
                                                      }
                                                    } else {
                                                      _showSnack(context,
                                                          'Токен не найден в ответе');
                                                    }
                                                  } else {
                                                    _showSnack(context,
                                                        'Сервер вернул: ${response.statusCode}');
                                                  }
                                                } catch (e, s) {
                                                  debugPrint(
                                                      'Ошибка сети: $e\n$s'); // 4. Ловим исключения
                                                  _showSnack(
                                                      context, 'Ошибка: $e');
                                                }
                                              }
                                            },
                                            child: Text(hasOffer
                                                ? 'Отказаться от предложения'
                                                : 'Принять предложение'),
                                          ),
                                        );

                                        if (hasOffer) {
                                          buttonWidget = Column(children: [
                                            buttonWidget,
                                            Container(
                                              margin: const EdgeInsets.only(
                                                  top: 20.0),
                                              child: SizedBox(
                                                width: double
                                                    .infinity, // Вторая кнопка также имеет полную ширину
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    fixedSize: const Size(
                                                        double.infinity, 50),
                                                    foregroundColor:
                                                        whiteprColor,
                                                    backgroundColor:
                                                        blueaccentColor,
                                                    disabledForegroundColor:
                                                        grayprprColor,
                                                    shape: const BeveledRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    3))),
                                                  ),

                                                  onPressed: () async {
                                                    debugPrint(
                                                        'Нажали на кнопку'); // 1. Проверяем вызов

                                                    try {
                                                      final response =
                                                          await http.post(
                                                        Uri.parse(
                                                            '${Config.baseUrl}/api/notification.php'),
                                                        body: {
                                                          'iduserp':
                                                              truck['iduserp']
                                                                  .toString()
                                                        },
                                                        headers: {
                                                          'Content-Type':
                                                              'application/x-www-form-urlencoded'
                                                        },
                                                      );

                                                      print(truck['iduserp']);
                                                      debugPrint(
                                                          'Status: ${response.statusCode}'); // 2. Лог кода ответа
                                                      debugPrint(
                                                          'Body : ${response.body}'); // 3. Лог тела ответа

                                                      if (response.statusCode ==
                                                          200) {
                                                        final Map<String,
                                                                dynamic> data =
                                                            jsonDecode(
                                                                response.body);

                                                        if (data['fcm_token'] !=
                                                            null) {
                                                          // Отправляем уведомление, если токен есть
                                                          try {
                                                            await sendNotificationV1(
                                                              deviceToken: data[
                                                                  'fcm_token'],
                                                              title:
                                                                  'Привет от crgtransp72app!',
                                                              body:
                                                                  'Ваш заказ начали выполнять!',
                                                            );
                                                            print(
                                                                'Уведомление отправлено');
                                                          } catch (e) {
                                                            print(
                                                                'Ошибка при отправке уведомления: $e');
                                                          }
                                                        } else {
                                                          _showSnack(context,
                                                              'Токен не найден в ответе');
                                                        }
                                                      } else {
                                                        _showSnack(context,
                                                            'Сервер вернул: ${response.statusCode}');
                                                      }

                                                      // Переход выполняем вне зависимости от наличия токена
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                            builder: (_) =>
                                                                //HistortScreen(
                                                                OrderExecutionScreen(
                                                                  //pageProfile:
                                                                  //  'OrderExecutionScreen',
                                                                  userId: truck[
                                                                          'iduserp']
                                                                      .toString(),
                                                                  orderId: widget
                                                                          .nameImg ??
                                                                      '', // Обеспечиваем значение по умолчанию
                                                                )),
                                                      );
                                                      print(
                                                          'userIdiii111 : ${truck['iduserp'].toString()}');
                                                      print(
                                                          'orderIdiii111  : ${widget.nameImg}');
                                                    } catch (e, s) {
                                                      debugPrint(
                                                          'Ошибка сети: $e\n$s'); // 4. Ловим исключения
                                                      _showSnack(context,
                                                          'Ошибка: $e');
                                                    }
                                                  }, // ───────────────────────────────────────────────────────── child
                                                  child: const Text(
                                                      'Начать выполнение'),
                                                ),
                                              ),
                                            ),
                                          ]);
                                        }

                                        return buttonWidget;
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }),
                      ),
                    ],
                  );
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

  Future<bool> toggleLike(dynamic idUser, dynamic id, int bd) async {
    return toggleLikeRequest(
      usersId: userId,
      idusers: idUser,
      id: id,
      bd: bd,
      usePerformerEndpoint: true,
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
    print(widget.bd); // Url к вашему API
    try {
      final response = await http.post(
        Uri.parse(Config.baseUrl).replace(path: '/api/delete_truck.php'),
        body: {
          'id': truckId.toString(),
          'bd': widget.bd.toString(),
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
          fetchAds(widget.bd, widget.nameImg);
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
