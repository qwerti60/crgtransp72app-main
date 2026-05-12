import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/OfferScreen2.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:crgtransp72app/pages/review_screenz.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../design/colors.dart';

import 'changerol_page.dart';
import 'like_helper.dart';
import 'loginpage.dart';

class outputob extends StatelessWidget {
  final String nameImg;
  final String city;
  final bool showBottomNav;

  /// Если `true` — меню заказчика; если `false` — меню грузоперевозчика.
  final bool useCustomerNavigation;

  /// Запрос объявлений без фильтра по городу (`all_cities=1` в get_ads2_new.php).
  final bool ignoreCityFilter;

  const outputob(
      {super.key,
      required this.nameImg,
      required this.city,
      this.showBottomNav = false,
      this.useCustomerNavigation = true,
      this.ignoreCityFilter = false});

  @override
  Widget build(BuildContext context) {
    return MyHomePage(
      nameImg: nameImg,
      city: city,
      showBottomNav: showBottomNav,
      useCustomerNavigation: useCustomerNavigation,
      ignoreCityFilter: ignoreCityFilter,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String city;
  final String nameImg;
  final bool showBottomNav;
  final bool useCustomerNavigation;
  final bool ignoreCityFilter;

  const MyHomePage(
      {super.key,
      required this.nameImg,
      required this.city,
      this.showBottomNav = false,
      this.useCustomerNavigation = true,
      this.ignoreCityFilter = false});

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

  int? idUser;
  Uint8List? fotouser;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  bool _invalidResponseSnackShown = false;
  final Map<String, bool> _likedOverrides = {};
  late Future<List> _adsFuture;

  bool get _isAuthorized => userId > 0;

  Future<void> _showAuthRequiredDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Требуется авторизация'),
          content: const Text(
            'Эта функция доступна только для зарегистрированных пользователей.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text('Авторизация'),
            ),
          ],
        );
      },
    );
  }

  void _showInvalidResponseSnack() {
    if (_invalidResponseSnackShown || !mounted) return;
    _invalidResponseSnackShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сервер вернул некорректный ответ. Попробуйте позже.'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  bool _isLikedValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  bool _likedForTruck(Map truck) {
    final key = (truck['id'] ?? '').toString();
    if (_likedOverrides.containsKey(key)) {
      return _likedOverrides[key]!;
    }
    return _isLikedValue(truck['success']);
  }

  String namefirm = '';
  String innStr = '';
  String ogrnStr = '';
  String kppStr = '';

  @override
  void initState() {
    super
        .initState(); // Assign nameImg from widget to a local variable if needed:
    String nameImg = widget.nameImg;
    bd = 1;
    String city = widget.city;

    _adsFuture = Future.value(<dynamic>[]);
    getUserData();
    _adsFuture = fetchAds(city, nameImg, userId);
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
          _adsFuture = fetchAds(widget.city, widget.nameImg, userId);
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

  Future<bool> checkOfferExists(int userId, dynamic truckId, int bd) async {
    final response = await http.get(Uri.parse(
        '${Config.baseUrl}/api/check_offer_zakaz.php?iduser=$userId&truck=${truckId.toString()}&bd=$bd'));

    if (response.statusCode == 200) {
      return json.decode(response.body)['exists'];
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _confirmDeleteOfferZakaz(
    BuildContext context,
    int listingId,
    int bdVal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить заявку?'),
        content: const Text(
          'Ваше предложение по этому объявлению будет удалено. При необходимости вы сможете оформить новое.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить пользователя.')),
      );
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/delete_offer_zakaz.php'),
        body: {
          'iduserp': userId.toString(),
          'iduser': listingId.toString(),
          'bd': bdVal.toString(),
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка удалена')),
        );
        setState(() {
          _adsFuture = fetchAds(widget.city, widget.nameImg, userId);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сервера: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<List> fetchAds(String city, String nameImg, int userId) async {
    final queryParameters = <String, String>{
      'nameImg': nameImg,
      'city': city,
      'useId': userId.toString(),
      'usersid': userId.toString(),
    };
    if (widget.ignoreCityFilter) {
      queryParameters['all_cities'] = '1';
    }
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '/api/get_ads2_new.php',
        queryParameters: queryParameters,
      ),
    );
    if (response.statusCode == 200) {
      final String body = response.body.trim();
      if (body.isEmpty) {
        throw Exception('Пустой ответ от сервера');
      }
      try {
        if (!(body.startsWith('{') || body.startsWith('['))) {
          debugPrint('Non-JSON response from get_ads2_new.php: $body');
          _showInvalidResponseSnack();
          return [];
        }
        final parsed = json.decode(body);

        print('uu77${userId}');
        print('uu77${nameImg}');

        print('uu77${userId}');
        print('uu77${city}');
        return parsed;

        //getUserDataAds(idusers1);
      } catch (e) {
        print('Ошибка декодирования: $e');
        print('Ответ сервера: $body');
        _showInvalidResponseSnack();
        return [];
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
          'Исполнители',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      // Добавление FloatingActionButton
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_isAuthorized) {
            await _showAuthRequiredDialog();
            return;
          }

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
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );

                if (snapshot.hasData) {
                  return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) {
                        var truck = snapshot.data![index];
                        if (truck == null)
                          Text(
                            'В этом разделе нет объявлений',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          );
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
                        //bool isLiked = false; // Состояние кнопки like
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
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isNarrow =
                                      constraints.maxWidth < 380;

                                  final Widget infoBlock = Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                          final key =
                                              (truck['id'] ?? '').toString();
                                          final currentLiked =
                                              _likedForTruck(truck);
                                          setState(() {
                                            _likedOverrides[key] =
                                                !currentLiked;
                                          });
                                          final updated = await toggleLike(
                                            truck['iduser'],
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
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                final reviewUserId = truck[
                                                        'iduserp'] ??
                                                    truck['review_user_id'] ??
                                                    truck['idusers'] ??
                                                    truck['iduser'];
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          ReviewScreenz(
                                                            userId: reviewUserId
                                                                .toString(),
                                                            showBottomNav:
                                                                widget.showBottomNav,
                                                          )),
                                                );
                                              },
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: List.generate(5,
                                                        (index) {
                                                      final double parsedRating = truck[
                                                                  'avg_rating'] !=
                                                              null
                                                          ? double.tryParse(truck[
                                                                      'avg_rating']
                                                                  .toString()) ??
                                                              0.0
                                                          : 0.0;
                                                      return Icon(
                                                        index < parsedRating
                                                            ? Icons.star
                                                            : Icons.star_border,
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
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        '${truck['reviewsCount'] ?? truck['review_count'] ?? 0}',
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                    ],
                                  );

                                  final Widget phoneBlock = GestureDetector(
                                    onTap: () {
                                      _makePhoneCall(truck['phone']);
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 130,
                                          child: Text(
                                            '${truck['phone']}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        infoBlock,
                                        const SizedBox(height: 8),
                                        Center(child: phoneBlock),
                                      ],
                                    );
                                  }

                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      infoBlock,
                                      phoneBlock,
                                    ],
                                  );
                                },
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
                            if (truck['namefirm'] == null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('Частное лицо',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['namefirm'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Компания:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['namefirm']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['innStr'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('ИНН:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['innStr']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['ogrnStr'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('ОГРН:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['ogrnStr']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if (truck['kppStr'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('КПП:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    Text('${truck['kppStr']}',
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
                            Container(
                              color: Colors.white, // По желанию добавьте фон
                              padding: const EdgeInsets.all(
                                  8.0), // Добавьте отступы вокруг FutureBuilder
                              child: FutureBuilder<bool>(
                                future:
                                    checkOfferExists(userId, truck['id'], bd!),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data!) {
                                    return Container(
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
                                            backgroundColor:
                                                Colors.red.shade700,
                                            disabledForegroundColor:
                                                grayprprColor,
                                            shape: const BeveledRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(3)),
                                            ),
                                          ),
                                          onPressed: () async {
                                            if (!_isAuthorized) {
                                              await _showAuthRequiredDialog();
                                              return;
                                            }
                                            final listingId = int.tryParse(
                                                    truck['id'].toString()) ??
                                                0;
                                            if (listingId <= 0) return;
                                            await _confirmDeleteOfferZakaz(
                                              context,
                                              listingId,
                                              bd!,
                                            );
                                          },
                                          child:
                                              const Text('Удалить заявку'),
                                        ),
                                      ),
                                    );
                                  } else {
                                    // Если записи нет
                                    return Container(
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
                                            disabledForegroundColor:
                                                grayprprColor,
                                            shape: const BeveledRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(3)),
                                            ),
                                          ),
                                          onPressed: () async {
                                            if (!_isAuthorized) {
                                              await _showAuthRequiredDialog();
                                              return;
                                            }

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OfferScreen2(
                                                        userid: truck['id']
                                                            .toString(),
                                                        useridobj:
                                                            truck['iduser'],
                                                        bd: bd,
                                                        useCustomerNavigation:
                                                            true),
                                              ),
                                            );
                                          },
                                          child: const Text('Предложить заказ'),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )
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
      bottomNavigationBar: widget.showBottomNav
          ? (widget.useCustomerNavigation
              ? const CustomerBottomNav(currentIndex: 0)
              : const PerformerBottomNav(currentIndex: 0))
          : null,
      // нужное расположение
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Future<bool> toggleLike(dynamic idUser, dynamic id, int bd) async {
    return toggleLikeRequest(
      usersId: userId,
      idusers: idUser,
      id: id,
      bd: bd,
      usePerformerEndpoint: false,
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
          _adsFuture = fetchAds(widget.city, widget.nameImg, userId);
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
