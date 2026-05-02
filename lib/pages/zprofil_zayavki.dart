import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/OfferScreen.dart';
import 'package:crgtransp72app/pages/OfferScreen2.dart';
import 'package:crgtransp72app/pages/OrderExecutionScreen.dart';
import 'package:crgtransp72app/pages/changerol_page.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../design/colors.dart';
import 'customer_bottom_nav.dart';
import 'like_helper.dart';
import 'performer_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const zprofil_zayavki(
    nameImg: '',
    base: 1,
  ));
}

class zprofil_zayavki extends StatelessWidget {
  final String nameImg;
  final int base;
  final bool useCustomerMenu;
  const zprofil_zayavki({
    super.key,
    required this.nameImg,
    required this.base,
    this.useCustomerMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Info',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        nameImg: nameImg,
        base: base,
        useCustomerMenu: useCustomerMenu,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String nameImg;

  final int base;
  final bool useCustomerMenu;
  const MyHomePage({
    super.key,
    required this.nameImg,
    required this.base,
    required this.useCustomerMenu,
  });

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
  late Future<List> _adsFuture;

  @override
  void initState() {
    super
        .initState(); // Assign nameImg from widget to a local variable if needed:
    String nameImg = widget.nameImg;
    bd ??= widget.base;

    _adsFuture = Future.value(<dynamic>[]);
    getUserData();
    // Загрузка объявлений только после getUserData (id исполнителя), иначе useId=0 и список пустой.
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
        final int uid = int.tryParse(data['idusers']?.toString() ?? '') ?? 0;
        setState(() {
          userId = uid;
          _adsFuture = uid > 0 ? fetchAds(uid) : Future.value(<dynamic>[]);
        });
        print('вывод id: $userId');
        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<bool> checkOfferExists(
      dynamic performerUserId, dynamic truckId, int bd) async {
    final response = await http.get(Uri.parse(
        '${Config.baseUrl}/api/check_offer.php?iduser=${performerUserId.toString()}&truck=${truckId.toString()}&bd=$bd'));

    if (response.statusCode == 200) {
      return json.decode(response.body)['exists'];
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<bool> checkAcceptedOffer(
      dynamic orderId, int bd, dynamic performerUserId) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/check_isp.php'),
      body: {
        'idusers': orderId.toString(),
        'bd': bd.toString(),
        'iduserp': performerUserId.toString(),
      },
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to check offer acceptance');
    }

    final data = json.decode(response.body);
    final dynamic raw = data['isp'];
    if (raw is bool) return raw;
    if (raw is num) return raw == 1;
    if (raw is String) return raw == '1' || raw.toLowerCase() == 'true';
    return false;
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
          print('firstName');
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

  Future<bool> toggleLike(dynamic idUser, dynamic id, int bd) async {
    isLiked = await toggleLikeRequest(
      usersId: userId,
      idusers: idUser,
      id: id,
      bd: bd,
      usePerformerEndpoint: true,
    );
    return isLiked;
  }

  Future<List> fetchAds(int userId) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/getofferusern_new.php',
        queryParameters: {
          'useId': userId.toString(),
        },
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load ads');
    }
    if (response.body.isEmpty) {
      throw Exception('Пустой ответ от сервера');
    }
    final parsed = json.decode(response.body);
    if (parsed is! List) {
      throw Exception('Ошибка формата ответа');
    }
    print('Найдено заявок: ${parsed.length} для userId=$userId');
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Предложения',
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
          // Второй виджет при необходимости
          // Пример с FutureBuilder
          Expanded(
            // Оборачиваем в Expanded, если это в Column/Row
            child: FutureBuilder(
                future: _adsFuture,
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
                                            if (userId <= 0) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Не удалось определить пользователя. Перезайдите в аккаунт.',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }

                                            final String key =
                                                (truck['id'] ?? '').toString();
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
                                              bd!,
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              _likedOverrides[key] = updated;
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
                                              GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ReviewScreen(
                                                                userId: truck[
                                                                        'iduserp']
                                                                    .toString())),
                                                  );
                                                },
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Row(
                                                      children: List.generate(5,
                                                          (index) {
                                                        final double
                                                            parsedRating =
                                                            truck['avg_rating'] !=
                                                                    null
                                                                ? double.tryParse(
                                                                        truck['avg_rating']
                                                                            .toString()) ??
                                                                    0.0
                                                                : 0.0;
                                                        return Icon(
                                                          index < parsedRating
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
                                                      '${truck['avg_rating'] ?? 0.0}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons
                                                                .comment_outlined,
                                                            size: 16,
                                                            color: Colors.grey),
                                                        const SizedBox(
                                                            width: 2),
                                                        Text(
                                                          '${truck['reviewsCount'] ?? 0}',
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _makePhoneCall(truck['phone']);
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${truck['phone']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                    autoPlay: false,
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
                              if (truck['maxgruz'] != '')
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
                              Builder(
                                builder: (context) {
                                  final int cardBd = int.tryParse(
                                          truck['bd']?.toString() ?? '') ??
                                      (bd ?? widget.base);
                                  final int editBd = widget.base;
                                  final int deleteBd = widget.base;
                                  return Container(
                                    color:
                                        Colors.white, // По желанию добавьте фон
                                    padding: const EdgeInsets.all(
                                        8.0), // Добавьте отступы вокруг блока кнопок
                                    child: FutureBuilder<bool>(
                                      future: Future.value(true),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data!) {
                                          return Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                margin: const EdgeInsets.only(
                                                    top: 20.0),
                                                child: SizedBox(
                                                  width: double.infinity,
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
                                                      shape:
                                                          const BeveledRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    3)),
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              OfferScreen2(
                                                            userid: truck['id']
                                                                .toString(),
                                                            useridobj:
                                                                truck['iduser']
                                                                    .toString(),
                                                            bd: editBd, // как в outputobz: контекст текущего раздела
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text(
                                                        'Редактировать предложение'),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                margin: const EdgeInsets.only(
                                                    top: 20.0),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: TextButton(
                                                    style: TextButton.styleFrom(
                                                      fixedSize: const Size(
                                                          double.infinity, 50),
                                                      foregroundColor:
                                                          whiteprColor,
                                                      backgroundColor:
                                                          readColor, // Меняем фон кнопки на красный
                                                      disabledForegroundColor:
                                                          grayprprColor,
                                                      shape:
                                                          const BeveledRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    3)),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      bool confirmed =
                                                          await showDialog<
                                                                  bool>(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                  title: const Text(
                                                                      "Подтверждение удаления"),
                                                                  content:
                                                                      const Text(
                                                                          "Вы уверены, что хотите удалить предложение?"),
                                                                  actions: [
                                                                    TextButton(
                                                                      child: const Text(
                                                                          "Отмена"),
                                                                      onPressed: () => Navigator.pop(
                                                                          context,
                                                                          false),
                                                                    ),
                                                                    TextButton(
                                                                      child: const Text(
                                                                          "Да, удалить"),
                                                                      onPressed: () => Navigator.pop(
                                                                          context,
                                                                          true),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ) ??
                                                              false;

                                                      if (confirmed) {
                                                        // Отправляем запрос на удаление записи
                                                        var response =
                                                            await http.post(
                                                          Uri.parse(
                                                              '${Config.baseUrl}/api/deleteoffer.php'), // Здесь укажите ваш API адрес
                                                          body: {
                                                            'iduserp': userId
                                                                .toString(),
                                                            'iduser':
                                                                truck['id']
                                                                    .toString(),
                                                            'bd': deleteBd
                                                                .toString(),
                                                          },
                                                        );
                                                        print(
                                                            'truckid ${truck['id']}');
                                                        print(
                                                            'truckiduser ${userId}');
                                                        print('bd ${deleteBd}');
                                                        if (response
                                                                .statusCode ==
                                                            200) {
                                                          // Запись успешно удалена
                                                          setState(() {
                                                            _adsFuture =
                                                                fetchAds(
                                                                    userId);
                                                          });
                                                          print(
                                                              'Запись успешно удалена');
                                                        } else {
                                                          print(
                                                              'Ошибка при удалении записи');
                                                        }
                                                      }
                                                    },
                                                    child: const Text(
                                                        'Удалить предложение'),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0),
                                                margin: const EdgeInsets.only(
                                                    top: 20.0),
                                                child: FutureBuilder<bool>(
                                                  future: checkAcceptedOffer(
                                                      truck['id'],
                                                      cardBd,
                                                      userId),
                                                  builder: (context,
                                                      acceptedSnapshot) {
                                                    if (acceptedSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const SizedBox(
                                                        height: 50,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    }

                                                    final bool canStart =
                                                        acceptedSnapshot.data ??
                                                            false;
                                                    return SizedBox(
                                                      width: double.infinity,
                                                      child: TextButton(
                                                        style: TextButton
                                                            .styleFrom(
                                                          fixedSize: const Size(
                                                              double.infinity,
                                                              50),
                                                          foregroundColor:
                                                              whiteprColor,
                                                          backgroundColor:
                                                              canStart
                                                                  ? blueaccentColor
                                                                  : Colors.grey,
                                                          disabledForegroundColor:
                                                              grayprprColor,
                                                          shape:
                                                              const BeveledRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.all(
                                                                    Radius
                                                                        .circular(
                                                                            3)),
                                                          ),
                                                        ),
                                                        onPressed: canStart
                                                            ? () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            OrderExecutionScreen(
                                                                      userId: truck[
                                                                              'iduserp']
                                                                          .toString(),
                                                                      orderId: truck[
                                                                              'id']
                                                                          .toString(),
                                                                    ),
                                                                  ),
                                                                );
                                                                print(
                                                                    'trid ${truck['id']}');
                                                                print(
                                                                    'uid $userId');
                                                                print(
                                                                    'uid ${truck['iduser']}');
                                                              }
                                                            : null,
                                                        child: Text(canStart
                                                            ? 'Начать выполнение'
                                                            : 'Ожидает принятия заказчиком'),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0),
                                            margin: const EdgeInsets.only(
                                                top: 20.0),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: TextButton(
                                                style: TextButton.styleFrom(
                                                  fixedSize: const Size(
                                                      double.infinity, 50),
                                                  foregroundColor: whiteprColor,
                                                  backgroundColor:
                                                      blueaccentColor,
                                                  disabledForegroundColor:
                                                      grayprprColor,
                                                  shape:
                                                      const BeveledRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(3)),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OfferScreen2(
                                                        userid: truck['id']
                                                            .toString(),
                                                        useridobj:
                                                            truck['iduser']
                                                                .toString(),
                                                        bd: editBd,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: const Text(
                                                    'Предложить свои услуги'),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              )
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
      bottomNavigationBar: widget.useCustomerMenu
          ? const CustomerBottomNav(currentIndex: 1)
          : const PerformerBottomNav(currentIndex: 1),

      // нужное расположение
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
          _adsFuture = fetchAds(userId);
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
