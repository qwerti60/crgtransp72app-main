import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/navigation/zakaz_ad_deal.dart';
import 'package:crgtransp72app/pages/HistortScreen1z.dart';
import 'package:crgtransp72app/pages/OfferScreen2.dart';
import 'package:crgtransp72app/pages/OrderExecutionScreenzak.dart';
import 'package:crgtransp72app/pages/changerol_page.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/review_screenz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../design/app_theme.dart';
import '../design/colors.dart';
import 'customer_bottom_nav.dart';
import 'like_helper.dart';
import 'performer_bottom_nav.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const zprofil_zakaz(
    nameImg: '',
    base: 1,
  ));
}

class zprofil_zakaz extends StatelessWidget {
  final String nameImg;
  final int base;
  final bool useCustomerMenu;
  const zprofil_zakaz({
    super.key,
    required this.nameImg,
    required this.base,
    this.useCustomerMenu = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Info',
      theme: crgAppTheme(),
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
  Future<List<dynamic>>? _offersFuture;

  /// true если список пуст из‑за того, что не удалось получить id по FCM (не путать с «нет заявок»).
  bool _couldNotResolveUser = false;

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
    super.initState();
    _offersFuture = _loadAllOffers();
  }

  Future<int> _resolveCurrentUserId() async {
    final token = await getSecurefcm_token();
    if (token == null) return 0;
    final response = await http.get(
      Uri.parse('${Config.apiBase}/getuserinfo.php?token=$token'),
    );
    if (response.statusCode != 200) return 0;
    final data = json.decode(response.body);
    if (data is! Map || data['error'] != null) return 0;
    final raw = data['idusers'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  Future<List<dynamic>> _loadAllOffers() async {
    final uid = await _resolveCurrentUserId();
    if (!mounted) return [];
    if (uid <= 0) {
      setState(() {
        _couldNotResolveUser = true;
        userId = 0;
      });
      return [];
    }
    setState(() {
      _couldNotResolveUser = false;
      userId = uid;
    });
    return fetchAllUserOffers(uid);
  }

  void _reloadOffers() {
    setState(() {
      _offersFuture = _loadAllOffers();
    });
  }

  /// Категория объявления для API (1 / 2 / 3); задаётся при объединении списков.
  int _bdForTruck(Map<dynamic, dynamic> truck) {
    // offer_dataf_bd — bd из строки offer_dataf; offer_bd — шард, где нашли объявление (для fetch/update нельзя).
    final dynamic v =
        truck['offer_dataf_bd'] ?? truck['bd'] ?? truck['offer_bd'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? widget.base;
    return widget.base;
  }

  int _intFromDynamic(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Рейтинг из JSON (число или строка вроде "4,5") — для звёзд и текста без ошибки типов.
  double _doubleFromDynamic(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().replaceAll(',', '.');
      return double.tryParse(s) ?? 0;
    }
    return 0;
  }

  int _reviewsCountFromDynamic(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? 0;
    return 0;
  }

  /// Рейтинг как в ленте исполнителей (get_ads2_new): avg_rating, иначе rating.
  double _avgRatingForTruck(Map<dynamic, dynamic> truck) {
    if (truck['avg_rating'] != null) {
      return _doubleFromDynamic(truck['avg_rating']);
    }
    return _doubleFromDynamic(truck['rating']);
  }

  String _reviewUserIdForTruck(Map<dynamic, dynamic> truck) {
    final dynamic v =
        truck['review_user_id'] ?? truck['iduser'] ?? truck['idusers'];
    return (v ?? '').toString();
  }

  /// Загрузка заявок: новый API (как лента исполнителей), при пустом ответе — getofferuserz_new.php.
  Future<List<dynamic>> fetchAllUserOffers(int uid) async {
    List<Map<String, dynamic>> normalizeList(List<dynamic> rawList) {
      final out = <Map<String, dynamic>>[];
      for (final raw in rawList) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        if (!m.containsKey('avg_rating') && m['rating'] != null) {
          m['avg_rating'] = m['rating'];
        }
        m.putIfAbsent('review_count', () => m['reviewsCount']);
        m.putIfAbsent(
            'review_user_id', () => m['review_user_id'] ?? m['idusers'] ?? m['iduser']);
        out.add(m);
      }
      out.sort((a, b) {
        final ai = _intFromDynamic(a['id']);
        final bi = _intFromDynamic(b['id']);
        return bi.compareTo(ai);
      });
      return out.where((m) {
        final owner = _intFromDynamic(m['iduser']);
        return owner <= 0 || owner != uid;
      }).toList();
    }

    List<Map<String, dynamic>> tryParse(http.Response response) {
      if (response.statusCode != 200) return [];
      final trimmed = response.body.trim();
      if (trimmed.isEmpty) return [];
      if (!(trimmed.startsWith('[') || trimmed.startsWith('{'))) return [];
      try {
        final parsed = json.decode(trimmed);
        if (parsed is! List) return [];
        return normalizeList(parsed);
      } catch (_) {
        return [];
      }
    }

    try {
      final primary = await http.get(
        Uri.parse(Config.baseUrl).replace(
          path: '${Config.apiPrefix}/get_ads_zakaz_customer.php',
          queryParameters: {
            'useId': uid.toString(),
            'usersid': uid.toString(),
          },
        ),
      );
      var list = tryParse(primary);
      if (list.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'get_ads_zakaz_customer пусто или недоступен (${primary.statusCode}), пробуем getofferuserz_new',
          );
        }
        final legacy = await http.get(
          Uri.parse(Config.baseUrl).replace(
            path: '${Config.apiPrefix}/getofferuserz_new.php',
            queryParameters: {
              'all': '1',
              'useId': uid.toString(),
              'usersid': uid.toString(),
            },
          ),
        );
        list = tryParse(legacy);
      }
      if (list.isEmpty && kDebugMode) {
        debugPrint('Список заявок пуст для uid=$uid');
      }
      return list;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('fetchAllUserOffers: $e\n$st');
      }
      rethrow;
    }
  }

  int userId = 0;

  int _performerIdForTruck(Map<dynamic, dynamic> truck) {
    return _intFromDynamic(
      truck['iduser'] ?? truck['idusers'] ?? truck['review_user_id'],
    );
  }

  Future<ZakazAdDealInfo> _fetchDealForTruck(
    Map<dynamic, dynamic> truck,
    int rowBd,
  ) {
    return fetchZakazAdDeal(
      customerId: userId,
      adId: _intFromDynamic(truck['id']),
      bd: rowBd,
      performerId: _performerIdForTruck(truck),
    );
  }

  Widget _zakazActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
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
      ),
    );
  }

  Widget _buildZakazOfferActions(
    BuildContext context,
    Map<dynamic, dynamic> truck,
    int rowBd,
    ZakazAdDealInfo deal,
  ) {
    final performerId = _performerIdForTruck(truck).toString();
    final adId = _intFromDynamic(truck['id']).toString();

    if (deal.isExecuting) {
      return Column(
        children: [
          _zakazActionButton(
            label: 'Выполняется',
            color: Colors.orange.shade700,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderExecutionScreenzak(
                    userId: performerId,
                    orderId: adId,
                    showBottomNav: widget.useCustomerMenu,
                    orderSource: 'performer_ad',
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    if (deal.isCompleted) {
      return Column(
        children: [
          _zakazActionButton(
            label: 'Выполнен',
            color: Colors.green.shade700,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistortScreen1z(
                    pageProfile: 'hist',
                    userId1: performerId,
                    orderId: adId,
                    parsedUserIdOk: userId.toString(),
                    adBd: rowBd,
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return Column(
      children: [
        _zakazActionButton(
          label: 'Удалить заявку',
          color: Colors.red.shade700,
          onPressed: () async {
            if (userId <= 0) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Не удалось определить пользователя.'),
                ),
              );
              return;
            }
            final listingId = _intFromDynamic(truck['id']);
            if (listingId <= 0) return;
            await _confirmDeleteOfferZakaz(context, listingId, rowBd);
          },
        ),
        const SizedBox(height: 12),
        _zakazActionButton(
          label: 'Редактировать заказ',
          color: blueaccentColor,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => OfferScreen2(
                  userid: truck['id'].toString(),
                  useridobj: truck['iduser'],
                  bd: rowBd,
                  useCustomerNavigation: true,
                  showBottomNav: true,
                  customerBottomNavIndex: 1,
                ),
              ),
            ).then((_) {
              if (mounted) _reloadOffers();
            });
          },
        ),
      ],
    );
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
        Uri.parse('${Config.apiBase}/delete_offer_zakaz.php'),
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
        _reloadOffers();
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

  bool _likedForTruck(Map<dynamic, dynamic> truck) {
    final String key = (truck['id'] ?? '').toString();
    if (_likedOverrides.containsKey(key)) {
      return _likedOverrides[key] ?? false;
    }
    return _isLikedValue(truck['success']);
  }

  Future<bool> toggleLike(dynamic idUser, dynamic id, int bd) async {
    isLiked = await toggleLikeRequest(
      usersId: userId,
      idusers: idUser,
      id: id,
      bd: bd,
      usePerformerEndpoint: false,
    );
    return isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        title: const Text(
          'Объявления заявки',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
        actions: [
          IconButton(
            tooltip: 'Обновить',
            onPressed: _reloadOffers,
            icon: const Icon(Icons.refresh, color: whiteprColor),
          ),
        ],
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
          Expanded(
            child: FutureBuilder<List<dynamic>>(
                future: _offersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Произошла ошибка: ${snapshot.error}'));
                  }
                  if (snapshot.data == null || snapshot.data!.isEmpty) {
                    if (_couldNotResolveUser) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Не удалось определить ваш аккаунт по сохранённому токену. '
                            'Выйдите и войдите снова либо перезапустите приложение, затем откройте этот раздел.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const Center(
                      child: Text(
                        'Нет объявлений, на которые вы оставили заявку',
                      ),
                    );
                  }
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final truck = snapshot.data![index] as Map<dynamic, dynamic>;
                        final rowBd = _bdForTruck(truck);

                        List<Uint8List> images = [];

                        for (var imgKey in ['img1', 'img2', 'img3', 'img4']) {
                          if (truck[imgKey] != null) {
                            try {
                              final String base64String =
                                  truck[imgKey].toString();
                              if (base64String.isEmpty) continue;
                              images.add(base64Decode(base64String));
                            } catch (_) {
                              // пропускаем битое изображение
                            }
                          }
                        }
                        Uint8List? truckImage;
                        if (truck['fotouser'] != null) {
                          try {
                            final s = truck['fotouser'].toString();
                            if (s.isNotEmpty) {
                              truckImage = base64Decode(s);
                            }
                          } catch (_) {
                            truckImage = null;
                          }
                        }
                        final double screenW =
                            MediaQuery.sizeOf(context).width;
                        final double galleryHeight =
                            (screenW / 2).clamp(120.0, 400.0).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                  top: 10,
                                  bottom: 10,
                                ),
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: truckImage != null
                                      ? Image.memory(
                                          truckImage,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/images/fotouser.png',
                                          width: 100,
                                          height: 100,
                                        ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: truck['phone'] != null &&
                                              '${truck['phone']}'
                                                  .trim()
                                                  .isNotEmpty
                                          ? () {
                                              _makePhoneCall(
                                                  truck['phone'].toString());
                                            }
                                          : null,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.phone),
                                          const SizedBox(width: 4),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 132,
                                            ),
                                            child: Text(
                                              truck['phone'] != null
                                                  ? '${truck['phone']}'
                                                  : '—',
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
                                              if (userId <= 0) {
                                                if (!mounted) return;
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Не удалось определить пользователя. Перезайдите в аккаунт.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.red,
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
                                                rowBd,
                                              );
                                              if (!mounted) return;
                                              setState(() {
                                                _likedOverrides[key] =
                                                    updated;
                                              });
                                            },
                                          ),
                                          if (truck['firstName'] != null)
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${truck['firstName']} ${truck['lastName']}',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Row(
                                                        children:
                                                            List.generate(
                                                                5, (index) {
                                                          final double
                                                              parsedRating =
                                                              _avgRatingForTruck(
                                                                  truck);
                                                          return Icon(
                                                            index <
                                                                    parsedRating
                                                                ? Icons.star
                                                                : Icons
                                                                    .star_border,
                                                            color:
                                                                Colors.amber,
                                                            size: 16,
                                                          );
                                                        }),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _avgRatingForTruck(
                                                                truck)
                                                            .toStringAsFixed(1),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      GestureDetector(
                                                        onTap: () {
                                                          final rid =
                                                              _reviewUserIdForTruck(
                                                                  truck);
                                                          if (rid.isEmpty) {
                                                            return;
                                                          }
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  ReviewScreenz(
                                                                userId: rid,
                                                                showBottomNav:
                                                                    widget
                                                                        .useCustomerMenu,
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
                                                              '${_reviewsCountFromDynamic(truck['reviewsCount'] ?? truck['review_count'])}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 14,
                                                                color: Colors
                                                                    .grey,
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
                                  ],
                                ),
                              ),
                              if (images.isNotEmpty)
                                SizedBox(
                                  height: galleryHeight,
                                  width: double.infinity,
                                  child: images.length == 1
                                      ? Image.memory(
                                          images[0],
                                          width: screenW,
                                          height: galleryHeight,
                                          fit: BoxFit.cover,
                                        )
                                      : PageView.builder(
                                          itemCount: images.length,
                                          itemBuilder: (context, itemIndex) {
                                            return Image.memory(
                                              images[itemIndex],
                                              width: screenW,
                                              height: galleryHeight,
                                              fit: BoxFit.cover,
                                            );
                                          },
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
                                child: FutureBuilder<ZakazAdDealInfo>(
                                  future: _fetchDealForTruck(truck, rowBd),
                                  builder: (context, dealSnapshot) {
                                    if (dealSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    if (dealSnapshot.hasError ||
                                        !dealSnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    return _buildZakazOfferActions(
                                      context,
                                      truck,
                                      rowBd,
                                      dealSnapshot.data!,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
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

  Future<void> showDeleteDialog(
      BuildContext context, int truckId, int rowBd) async {
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
      deleteTruck(truckId, rowBd, context);
    }
  }

  Future<void> deleteTruck(int truckId, int rowBd, dynamic context) async {
    try {
      final response = await http.post(
        Uri.parse(Config.baseUrl).replace(path: '${Config.apiPrefix}/delete_truck.php'),
        body: {
          'id': truckId.toString(),
          'bd': rowBd.toString(),
        },
      );

      if (response.statusCode == 200) {
        // Успешно удалено, можно показать уведомление
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Объявление успешно удалёно!'),
          backgroundColor: Colors.green,
        ));

        _reloadOffers();
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
