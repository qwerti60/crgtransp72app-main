import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/review_screenz.dart';
import 'package:crgtransp72app/pages/sendNotification.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../design/colors.dart';

import 'changerol_page.dart';
import 'customer_bottom_nav.dart';
import 'like_helper.dart';

class list_predloj_na_obj_isp extends StatelessWidget {
  final String nameImg;
  final int bd; // добавляем параметр base
  final bool useCustomerMenu;
  final bool wrapInMaterialApp;

  const list_predloj_na_obj_isp({
    Key? key,
    required this.nameImg,
    required this.bd, // добавляем обязательное поле
    this.useCustomerMenu = false,
    this.wrapInMaterialApp = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final home = MyHomePage(
      nameImg: nameImg,
      bd: bd,
      useCustomerMenu: useCustomerMenu,
    );

    if (!wrapInMaterialApp) {
      return home;
    }

    return MaterialApp(
      title: 'Truck Info',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: home,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String nameImg;
  final int bd;
  final bool useCustomerMenu;
  const MyHomePage({
    super.key,
    required this.nameImg,
    required this.bd,
    required this.useCustomerMenu,
  });

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
    super.initState();
    _adsFuture = fetchAds(widget.bd, widget.nameImg);
    getUserData();
  }

  int userId = 0;
  late Future<List<dynamic>> _adsFuture;
  final Map<String, bool> _likedOverrides = {};

  // id исполнителя, чьё предложение уже принято заказчиком (или null, если ни одного).
  // Пока одно предложение принято — кнопки «Принять» у остальных неактивны.
  int? _acceptedPerformerId;
  bool _offersStatusLoading = true;

  bool _isLikedValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  String _likeKey(Map truck) {
    return (_listingIdForTruck(truck) ?? 0).toString();
  }

  bool _likedForTruck(Map truck) {
    final String key = _likeKey(truck);
    if (_likedOverrides.containsKey(key)) {
      return _likedOverrides[key]!;
    }
    return _isLikedValue(truck['success']);
  }

  int? _listingIdForTruck(Map truck) {
    final dynamic raw = truck['listing_id'] ?? truck['id'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  int? _performerIdForTruck(Map truck) {
    final dynamic raw = truck['iduserp'] ?? truck['idusers'] ?? truck['iduser'];
    if (raw == null) return null;
    return int.tryParse(raw.toString());
  }

  Future<bool> _ensureUserId() async {
    if (userId > 0) return true;
    await getUserData();
    return userId > 0;
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token();
    if (token == null) {
      print('Token is null');
      return;
    }
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
        return;
      }
      setState(() {
        userId = int.tryParse(data['idusers'].toString()) ?? 0;
        _adsFuture = fetchAds(widget.bd, widget.nameImg);
      });
      print('вывод id: $userId');
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<void> getUserDataAds(idUser) async {
    print(idUser);
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/getuserinfoads.php?idusers=$idUser'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          idUser = data['idusers'];
          firstName = data['firstName']?.toString() ?? "Нет имени";
          lastName = data['lastName']?.toString() ?? "Нет фамилии";
          middleName = data['middleName']?.toString() ?? "Нет отчества";
          city = data['city']?.toString() ?? "Нет города";
          phone = data['phone']?.toString() ?? "Нет телефона";
          email = data['email']?.toString() ?? "Нет email";
          namefirm = data['namefirm']?.toString() ?? "Нет назвония фирмы";
          innStr = data['innStr']?.toString() ?? "Нет ИНН";
          ogrnStr = data['ogrnStr']?.toString() ?? "Нет ОГРН";
          kppStr = data['kppStr']?.toString() ?? "Нет КПП";
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
        path: '/api/list_predloj_na_obj_isp_new.php',
        queryParameters: {
          'usersid': userId.toString(),
          'idusers': (idUser ?? '').toString(),
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
        if (parsed is! List) {
          throw Exception('Ошибка формата ответа');
        }
        print(nameImg);
        print(bd);
        await _computeAcceptedPerformer(parsed, bd);
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

  /// Определяет, чьё предложение уже принято (isp = 1) среди всех предложений.
  /// Принятым может быть только одно предложение за раз.
  Future<void> _computeAcceptedPerformer(List offers, int bd) async {
    int? accepted;
    for (final t in offers) {
      final performerId =
          int.tryParse((t['iduserp'] ?? '').toString()) ?? 0;
      if (performerId <= 0) continue;
      try {
        if (await checkIsp(widget.nameImg, bd, performerId)) {
          accepted = performerId;
          break;
        }
      } catch (_) {
        // игнорируем ошибку проверки отдельного предложения
      }
    }
    _acceptedPerformerId = accepted;
    _offersStatusLoading = false;
  }

  Future<bool> checkIsp(String idUser, int bd, int idUserP) async {
    final response = await http.post(
      Uri.parse('https://ivnovav.ru/api/check_isp.php'),
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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Предложения исполнителей',
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
              future: _adsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final offers = snapshot.data!;
                  if (offers.isEmpty) {
                    return const Center(
                      child: Text(
                        'В этом разделе нет предложений',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return ListView.builder(
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        var truck = offers[index];
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
                        // Проверяем существует ли изображение fotouser
                        if (truck['fotouser'] != null) {
                          base64Stringf =
                              truck['fotouser']; // Получаем строку base64
                          truckImage = base64Decode(
                              base64Stringf); // Декодируем строку в список байтов
                        }
                        final double rating = _toDouble(truck['rating']);
                        final int reviewsCount = _toInt(truck['reviewsCount']);
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
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                            if (!await _ensureUserId()) return;

                                            final listingId =
                                                _listingIdForTruck(truck);
                                            final performerId =
                                                _performerIdForTruck(truck);
                                            if (listingId == null ||
                                                listingId <= 0 ||
                                                performerId == null ||
                                                performerId <= 0) {
                                              return;
                                            }

                                            final String key =
                                                _likeKey(truck);
                                            final bool currentLiked =
                                                _likedForTruck(truck);
                                            setState(() {
                                              _likedOverrides[key] =
                                                  !currentLiked;
                                            });

                                            final int likeBd = int.tryParse(
                                                    truck['bd']?.toString() ??
                                                        '') ??
                                                widget.bd;

                                            final bool updated =
                                                await toggleLike(
                                              performerId,
                                              listingId,
                                              likeBd,
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              _likedOverrides[key] = updated;
                                              truck['success'] =
                                                  updated ? 'true' : 'false';
                                              _adsFuture = fetchAds(
                                                  widget.bd, widget.nameImg);
                                            });
                                          },
                                        ),
                                        if (truck['firstName'] != null)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${truck['firstName']} ${truck['lastName']}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Wrap(
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  spacing: 4,
                                                  children: [
                                                    ...List.generate(5,
                                                        (index) {
                                                      return Icon(
                                                        index < rating
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      );
                                                    }),
                                                    Text(
                                                      rating.toStringAsFixed(1),
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                ReviewScreenz(
                                                              userId: truck[
                                                                      'iduserp']
                                                                  .toString(),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .comment_outlined,
                                                            size: 16,
                                                            color: Colors.grey,
                                                          ),
                                                          const SizedBox(
                                                              width: 2),
                                                          Text(
                                                            '$reviewsCount',
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
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: GestureDetector(
                                      onTap: () {
                                        _makePhoneCall(truck['phone']);
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone),
                                          const SizedBox(width: 4),
                                          Flexible(
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
                            if (truck['cena'] != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Прелагаемая стоимость:',
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Предлагаю:',
                                        style:
                                            DefaultTextStyle.of(context).style),
                                    const SizedBox(height: 4),
                                    Text('${truck['about']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            Builder(
                              builder: (context) {
                                final int performerId = int.tryParse(
                                        truck['iduserp'].toString()) ??
                                    0;
                                // Это предложение принято?
                                final bool hasOffer =
                                    _acceptedPerformerId != null &&
                                        _acceptedPerformerId == performerId;
                                // Какое-то ДРУГОЕ предложение уже принято?
                                final bool acceptedElsewhere =
                                    _acceptedPerformerId != null && !hasOffer;
                                // «Принять» неактивна, пока статусы грузятся
                                // или уже принято другое предложение.
                                final bool disabled = !hasOffer &&
                                    (_offersStatusLoading || acceptedElsewhere);

                                // Цвета под состояние кнопки.
                                final Color bgColor = hasOffer
                                    ? Colors.red.shade600 // активная «Отказаться»
                                    : disabled
                                        ? Colors.grey.shade300 // неактивная
                                        : blueaccentColor; // активная «Принять»
                                final Color fgColor = disabled
                                    ? Colors.grey.shade600
                                    : whiteprColor;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  margin: const EdgeInsets.only(top: 20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                            fixedSize:
                                                const Size(double.infinity, 50),
                                            foregroundColor: fgColor,
                                            backgroundColor: bgColor,
                                            disabledForegroundColor:
                                                Colors.grey.shade600,
                                            disabledBackgroundColor:
                                                Colors.grey.shade300,
                                            side: disabled
                                                ? BorderSide(
                                                    color: Colors.grey.shade400,
                                                    width: 1)
                                                : BorderSide.none,
                                            shape: const BeveledRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(3))),
                                          ),
                                          onPressed: disabled
                                              ? null
                                              : () async {
                                                  await _handleOfferToggle(
                                                    performerId: performerId,
                                                    iduserp: truck['iduserp'],
                                                    accept: !hasOffer,
                                                  );
                                                },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                hasOffer
                                                    ? Icons.close
                                                    : disabled
                                                        ? Icons.lock_outline
                                                        : Icons.check,
                                                size: 18,
                                                color: fgColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  hasOffer
                                                      ? 'Отказаться от предложения'
                                                      : 'Принять предложение',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (disabled && !_offersStatusLoading)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Вы уже приняли другое предложение',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            )
                          ],
                        );
                      });
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.useCustomerMenu
          ? const CustomerBottomNav(currentIndex: 1)
          : null,
    );
  }

  Future<void> _handleOfferToggle({
    required int performerId,
    required dynamic iduserp,
    required bool accept,
  }) async {
    // Переключаем статус на сервере (isp 0<->1).
    await updateOffer(widget.bd, widget.nameImg, userId, iduserp);

    if (!mounted) return;
    // Локально обновляем состояние: при принятии блокируем остальные,
    // при отказе — снова разрешаем «Принять» у всех.
    setState(() {
      _acceptedPerformerId = accept ? performerId : null;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/notification.php'),
        body: {'iduserp': iduserp.toString()},
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body : ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['fcm_token'] != null) {
          try {
            await sendNotificationV1(
              deviceToken: data['fcm_token'],
              title: 'Привет от crgtransp72app!',
              body: accept
                  ? 'Ваше предложение принято исполнителем!'
                  : 'От вашего предложения исполнитель отказался!',
            );
            print('Уведомление отправлено');
          } catch (e) {
            print('Ошибка при отправке уведомления: $e');
          }
        } else if (mounted) {
          _showSnack(context, 'Токен не найден в ответе');
        }
      } else if (mounted) {
        _showSnack(context, 'Сервер вернул: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка сети: $e');
    }
  }

  Future<void> updateOffer(int bd, String nameImg, int userID, iduserp) async {
    final uri =
        Uri.parse('https://ivnovav.ru/api/updatePriemZak.php'); // Новый endpoint

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
