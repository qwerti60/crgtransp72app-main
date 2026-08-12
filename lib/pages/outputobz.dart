import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/OfferScreen.dart';
import 'package:crgtransp72app/pages/SearchForm.dart';
import 'package:crgtransp72app/pages/ads1.dart';
import 'package:crgtransp72app/pages/changerol_page.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/get_vt_z.dart';
import 'package:crgtransp72app/pages/chat_thread_screen.dart';
import 'package:crgtransp72app/pages/support_create_screen.dart';
import 'package:crgtransp72app/widgets/profile_contact_row.dart';
import 'package:crgtransp72app/pages/loginpage.dart';
import 'package:crgtransp72app/pages/review_screen.dart';
import 'package:crgtransp72app/pages/zprofil_page2.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/offer_check.dart';
import '../config.dart';
import '../customer_ad_category.dart';
import '../design/colors.dart';
import '../models/search_params.dart';
import '../services/search_services_api.dart';
import 'customer_bottom_nav.dart';
import 'like_helper.dart';
import 'performer_bottom_nav.dart';
import 'performer_search_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class outputobz extends StatelessWidget {
  final String nameImg;
  final String city;
  final bool showBottomNav;
  final SearchParams? searchParams;
  final String? searchTitle;

  /// Индекс вкладки [PerformerBottomNav] (0 — услуги, 1 — заявки, 2 — профиль).
  final int performerBottomNavIndex;

  /// Если быстрый подбор из «Мои объявления» пуст — открыть форму поиска.
  final bool openSearchOnEmpty;

  const outputobz(
      {super.key,
      required this.nameImg,
      required this.city,
      this.showBottomNav = true,
      this.searchParams,
      this.searchTitle,
      this.performerBottomNavIndex = 0,
      this.openSearchOnEmpty = false});

  @override
  Widget build(BuildContext context) {
    return MyHomePage(
      nameImg: nameImg,
      city: city,
      showBottomNav: showBottomNav,
      searchParams: searchParams,
      searchTitle: searchTitle,
      performerBottomNavIndex: performerBottomNavIndex,
      openSearchOnEmpty: openSearchOnEmpty,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String nameImg;

  final String city;
  final bool showBottomNav;
  final SearchParams? searchParams;
  final String? searchTitle;
  final int performerBottomNavIndex;
  final bool openSearchOnEmpty;

  const MyHomePage(
      {super.key,
      required this.nameImg,
      required this.city,
      this.showBottomNav = true,
      this.searchParams,
      this.searchTitle,
      this.performerBottomNavIndex = 0,
      this.openSearchOnEmpty = false});

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
  bool _emptySearchRedirectDone = false;

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

  @override
  void initState() {
    super.initState();
    _resolveBd();
    _adsFuture = _bootstrapAds();
  }

  Future<List> _bootstrapAds() async {
    await getUserData();
    final ads = await fetchAds(widget.city, widget.nameImg, userId);
    _maybeOpenSearchOnEmpty(ads);
    return ads;
  }

  void _maybeOpenSearchOnEmpty(List ads) {
    if (!widget.openSearchOnEmpty ||
        ads.isNotEmpty ||
        _emptySearchRedirectDone ||
        !mounted) {
      return;
    }
    _emptySearchRedirectDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PerformerSearchScreen(
            embedInPerformerShell: true,
            showBottomNav: widget.showBottomNav,
            initialCity: widget.city,
            initialServiceName: widget.nameImg,
            emptyResultsHint:
                'По параметрам объявления заявки не найдены. Уточните поиск.',
          ),
        ),
      );
    });
  }

  int _bdForTruck(Map truck) {
    return int.tryParse(truck['bd']?.toString() ?? '') ?? bd ?? 1;
  }

  Future<void> _openOfferScreen(Map<dynamic, dynamic> truck) async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OfferScreen(
          userid: truck['id'].toString(),
          useridobj: truck['iduser'],
          bd: _bdForTruck(truck),
          showBottomNav: true,
          performerBottomNavIndex: widget.performerBottomNavIndex,
        ),
      ),
    );
  }

  Future<void> _confirmDeletePerformerOffer(Map<dynamic, dynamic> truck) async {
    final listingId = int.tryParse(truck['id']?.toString() ?? '') ?? 0;
    final bdVal = _bdForTruck(truck);
    if (userId <= 0 || listingId <= 0) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить предложение?'),
        content: const Text(
          'Ваше предложение по этой заявке будет удалено. '
          'При необходимости вы сможете оформить новое.',
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

    try {
      final response = await http.post(
        Uri.parse('${Config.apiBase}/deleteoffer.php'),
        body: {
          'iduserp': userId.toString(),
          'iduser': listingId.toString(),
          'bd': bdVal.toString(),
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _adsFuture = fetchAds(widget.city, widget.nameImg, userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Предложение удалено')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось удалить предложение')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка сети при удалении')),
      );
    }
  }

  Widget _offerActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          fixedSize: const Size(double.infinity, 50),
          foregroundColor: whiteprColor,
          backgroundColor: color,
          disabledForegroundColor: grayprprColor,
          shape: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(3)),
          ),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Future<void> _resolveBd() async {
    if (bd != null && bd! > 0) return;
    try {
      final response = await http.get(
        Uri.parse('${Config.apiBase}/get_cities.php').replace(
          queryParameters: {
            'namex': widget.nameImg,
            'useId': '0',
          },
        ),
      );
      if (response.statusCode != 200) return;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final resolved = bdFromPerformerServiceMeta(
        lookupTable: data['lookup_table']?.toString(),
        mainTable: data['main_table']?.toString(),
      );
      if (mounted) {
        setState(() => bd = resolved);
      }
    } catch (e) {
      print('outputobz _resolveBd: $e');
    }
  }

  int userId = 0;
  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'));

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

  /// [performerUserId] — id залогиненного исполнителя (кто смотрит список), не iduser заказчика в объявлении.
  Future<bool> checkOfferExists(
      dynamic performerUserId, dynamic truckId, int bd) async {
    final response = await http.get(Uri.parse(
        '${Config.apiBase}/check_offer.php?iduser=${performerUserId.toString()}&truck=${truckId.toString()}&bd=$bd'));

    if (response.statusCode == 200) {
      return json.decode(response.body)['exists'];
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> getUserDataAds(idUser) async {
    print(idUser);
    final response = await http.get(
        Uri.parse('${Config.apiBase}/getuserinfoads.php?idusers=$idUser'));

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

  Future<List> fetchAds(String city, String nameImg, int userId) async {
    if (widget.searchParams != null) {
      final parsed = await SearchServicesApi.tryFetch(
        role: 'performer',
        nameImg: nameImg,
        city: city,
        userId: userId,
        params: widget.searchParams!,
      );
      if (parsed != null) {
        if (parsed.isNotEmpty) {
          final rowBd = int.tryParse(parsed[0]['bd']?.toString() ?? '');
          if (rowBd != null && rowBd > 0 && mounted) {
            setState(() => bd = rowBd);
          }
        }
        return parsed;
      }
      if (widget.searchParams!.freeText) {
        return [];
      }
      debugPrint('[outputobz] search_services unavailable, fallback to getads3');
    }

    if (nameImg.isEmpty ||
        (city.isEmpty && !(widget.searchParams?.hasGeo ?? false))) {
      return [];
    }

    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '${Config.apiPrefix}/getads3.php',
        queryParameters: {
          'nameImg': nameImg,
          'city': city, // Преобразуем в строку
          // Поддержка обоих вариантов параметра на бэкенде.
          'useId': userId.toString(),
          'usersid': userId.toString(),
        },
      ),
    );
    print('uu77${userId}');
    print('uu77${nameImg}');
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Пустой ответ от сервера');
      }
      try {
        final parsed = json.decode(response.body);
        print(parsed);
        if (parsed is List && parsed.isNotEmpty) {
          final rowBd = int.tryParse(parsed[0]['bd']?.toString() ?? '');
          if (rowBd != null && rowBd > 0 && mounted) {
            setState(() => bd = rowBd);
          }
        }
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
      backgroundColor: whiteprColor,
      appBar: AppBar(
        title: Text(
          widget.searchTitle ?? 'Объявления',
          style: const TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
      ),
      // Использование Column для размещения нескольких виджетов в body
      body: Column(
        children: [
          // основная часть экрана

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
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final bool isNarrow =
                                        constraints.maxWidth < 380;

                                    final Widget infoBlock = Row(
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
                                                    truck['idusers'];
                                            if (ownerId == null) return;
                                            final bool currentLiked =
                                                _likedForTruck(truck);
                                            setState(() {
                                              _likedOverrides[key] =
                                                  !currentLiked;
                                            });
                                            final bool updated =
                                                await toggleLike(ownerId,
                                                    truck['id'], _bdForTruck(truck));
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
                                                  final reviewUserId =
                                                      truck['review_user_id'] ??
                                                          truck['idusers'] ??
                                                          truck['iduser'];
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            ReviewScreen(
                                                                userId: reviewUserId
                                                                    .toString(),
                                                                showBottomNav:
                                                                    true)),
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
                                    );

                                    final Widget phoneBlock = Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ProfileContactRow(
                                          phone: '${truck['phone'] ?? ''}',
                                          onChatTap: () =>
                                              _openChatForTruck(truck),
                                        ),
                                        TextButton(
                                          onPressed: () => _reportTruck(truck),
                                          child: const Text(
                                            'Пожаловаться',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ),
                                      ],
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
                              if (truck['distance_km'] != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Расстояние:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      Text(
                                          '${truck['distance_km']} км',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: blueaccentColor)),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Подробнее о заказе:',
                                          style: DefaultTextStyle.of(context)
                                              .style),
                                      const SizedBox(height: 4),
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
                                color: Colors.white,
                                padding: const EdgeInsets.all(8.0),
                                child: FutureBuilder<OfferCheckResult>(
                                  future: userId > 0
                                      ? fetchOfferCheckState(
                                          performerUserId: userId,
                                          orderId: int.tryParse(
                                                  truck['id'].toString()) ??
                                              0,
                                          bd: _bdForTruck(truck),
                                        )
                                      : Future.value(OfferCheckResult.empty),
                                  builder: (context, snapshot) {
                                    final state =
                                        snapshot.data ?? OfferCheckResult.empty;

                                    if (state.refused) {
                                      return Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(top: 20),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.red.shade300,
                                          ),
                                        ),
                                        child: const Text(
                                          'Заказчик отказался от вашего предложения. '
                                          'Удалите предложение в разделе «Предложения», '
                                          'чтобы откликнуться снова.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      );
                                    }

                                    if (state.editable) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        margin:
                                            const EdgeInsets.only(top: 20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _offerActionButton(
                                              label: 'Редактировать предложение',
                                              color: blueaccentColor,
                                              onPressed: () {
                                                if (!_isAuthorized) {
                                                  _showAuthRequiredDialog();
                                                  return;
                                                }
                                                _openOfferScreen(truck);
                                              },
                                            ),
                                            const SizedBox(height: 12),
                                            _offerActionButton(
                                              label: 'Удалить предложение',
                                              color: Colors.red.shade700,
                                              onPressed: () {
                                                if (!_isAuthorized) {
                                                  _showAuthRequiredDialog();
                                                  return;
                                                }
                                                _confirmDeletePerformerOffer(
                                                    truck);
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0),
                                        margin:
                                            const EdgeInsets.only(top: 20.0),
                                        child: SizedBox(
                                          width: double.infinity,
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
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(3)),
                                              ),
                                            ),
                                            onPressed: () {
                                              if (!_isAuthorized) {
                                                _showAuthRequiredDialog();
                                                return;
                                              }

                                              _openOfferScreen(truck);
                                            },
                                            child: const Text(
                                                'Предложить свои услуги'),
                                          ),
                                        ),
                                      );
                                  },
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
      bottomNavigationBar: widget.showBottomNav
          ? PerformerBottomNav(currentIndex: widget.performerBottomNavIndex)
          : null,
    );
  }

  Future<void> _openChatForTruck(Map truck) async {
    final customerId = int.tryParse(
      '${truck['iduser'] ?? truck['idusers'] ?? ''}',
    );
    final adId = int.tryParse('${truck['id'] ?? ''}');
    if (customerId == null || adId == null || customerId <= 0 || adId <= 0) {
      return;
    }
    final name = [
      truck['lastName'],
      truck['firstName'],
    ].where((e) => e != null && '$e'.trim().isNotEmpty).join(' ');
    await ChatThreadScreen.openDeal(
      context: context,
      counterpartUserId: customerId,
      bd: _bdForTruck(truck),
      adId: adId,
      title: name.isNotEmpty ? name : 'Заказчик',
      currentUserId: userId,
      showBottomNav: true,
      isPerformer: true,
    );
  }

  Future<void> _reportTruck(Map truck) async {
    final adId = int.tryParse('${truck['id'] ?? ''}') ?? 0;
    final adBd = _bdForTruck(truck);
    if (adId <= 0 || adBd <= 0) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportCreateScreen(
          showBottomNav: false,
          isPerformer: true,
          initialCategory: 'ad_moderation',
          initialSubject: 'Жалоба на заявку #$adId',
          lockCategory: true,
          contextJson: {
            'bd': adBd,
            'ad_id': adId,
            'side': 'demand',
          },
        ),
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
        Uri.parse(Config.baseUrl).replace(path: '${Config.apiPrefix}/delete_truck.php'),
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
          fetchAds(widget.city, widget.nameImg, userId);
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
