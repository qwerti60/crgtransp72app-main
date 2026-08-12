import 'dart:convert';
import 'dart:typed_data';
import 'package:crgtransp72app/pages/ad_boost_screen.dart';
import 'package:crgtransp72app/pages/changerol_page2.dart';
import 'package:crgtransp72app/pages/edit_ob_gp1.dart';
import 'package:crgtransp72app/pages/edit_ob_gr.dart';
import 'package:crgtransp72app/pages/edit_ob_vidt.dart';
import 'package:crgtransp72app/pages/editn_ob_gp1.dart';
//import 'package:crgtransp72app/pages/editn_ob_vidt.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/list_predloj_na_obj_isp.dart';
import 'package:crgtransp72app/pages/list_predloj_na_zayavki.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:carousel_slider/carousel_slider.dart';

import '../config.dart';
import '../customer_ad_category.dart';
import '../design/app_theme.dart';
import '../design/colors.dart';
import '../search/ad_match.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'changerol_page.dart';

void main() {
  runApp(const Ads1App());
}

class Ads1App extends StatelessWidget {
  final bool showBottomNav;

  const Ads1App({super.key, this.showBottomNav = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truck Info',
      theme: crgAppTheme(),
      home: showBottomNav
          ? const Ads1Shell()
          : const MyHomePage(showBottomNav: false),
    );
  }
}

/// «Мои объявления» исполнителя с нижним меню: редактирование во вложенном Navigator.
class Ads1Shell extends StatelessWidget {
  const Ads1Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => const MyHomePage(showBottomNav: false),
            settings: settings,
          );
        },
      ),
      bottomNavigationBar: const PerformerBottomNav(currentIndex: 2),
    );
  }
}

/// Экран «Мои объявления» исполнителя внутри [HistortScreen] (меню снаружи).
class Ads1Page extends StatelessWidget {
  const Ads1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyHomePage(showBottomNav: false);
  }
}

class MyHomePage extends StatefulWidget {
  final bool showBottomNav;

  const MyHomePage({super.key, this.showBottomNav = true});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
  Future<List>? _adsFuture;

  @override
  void initState() {
    bd ??= 1;
    super.initState();
    // Сначала userId, потом список — иначе get_adstest?idusers=0 → пусто
    _adsFuture = _loadAdsForCurrentUser();
  }

  Future<List> _loadAdsForCurrentUser() async {
    await getUserData();
    if (idusers <= 0) {
      return [];
    }
    return fetchAds(bd!, idusers);
  }

  Future<void> getUserData() async {
    final token = await getSecurefcm_token();
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
        final parsedId = int.tryParse(data['idusers']?.toString() ?? '') ?? 0;
        setState(() {
          idusers = parsedId;
          firstName = data['firstName']?.toString() ?? '';
          lastName = data['lastName']?.toString() ?? '';
          middleName = data['middleName']?.toString() ?? '';
          city = data['city']?.toString() ?? '';
          phone = data['phone']?.toString() ?? '';
          email = data['email']?.toString() ?? '';
        });
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future<List> fetchAds(int bd, int idusers) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl).replace(
        path: '${Config.apiPrefix}/get_adstest.php',
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

  Future<void> showDeleteConfirmationDialog(
      BuildContext context, int truckId, bd) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Подтверждение удаления'),
          content: Text('Вы уверены, что хотите удалить этот элемент?'),
          actions: <Widget>[
            TextButton(
              child: Text('Отмена'),
              onPressed: () {
                Navigator.pop(context, false); // Закрываем диалог
              },
            ),
            TextButton(
              child: Text('Удалить'),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.red),
              ),
              onPressed: () {
                deleteTruck(truckId, context,
                    bd); // Удаляем запись, если выбран вариант "Да"
                // Здесь логика удаления элемента
                print('Элемент удалён!');
                Navigator.pop(context, true); // Закрываем диалог
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeleteDialog(BuildContext context, int truckId, bd) async {
    try {
      // Используем правильный контекст
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Диалог нельзя закрыть свайпом
        builder: (context) {
          // Обратите внимание на использование внутреннего контекста
          return AlertDialog(
            title: const Text('Удалить объявление безвозвратно?'),
            content: Text(
                'Вы уверены, что хотите удалить объявление ?'), // Дополнительное сообщение
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                    context, false), // Важно использовать внутренний контекст
                child: const Text('Нет'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                    context, true), // Важно использовать внутренний контекст
                child: const Text('Да'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        deleteTruck(
            truckId, context, bd); // Удаляем запись, если выбран вариант "Да"
      }
    } catch (e) {
      print("Error showing dialog: $e"); // Логируем возможные ошибки
    }
  }

  Future<void> editTruck(int id, BuildContext context, String tableName) async {
    try {
      bool? updated;
      switch (tableName) {
        case 'add_ob_gr':
          updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => edit_ob_gr(
                        id: id,
                      )));
          break;
        case 'add_ob_vidt':
          updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => edit_ob_vidt(
                        id: id,
                      )));
          break;
        case 'add_ob_gp':
          updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => editn_ob_gp(
                        id: id,
                      )));
          break;
        default:
          print('Unknown table name');
      }
      if (updated == true && mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Ошибка при редактировании: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        title: const Text(
          'Мои объявления ',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      // Добавление FloatingActionButton
/*      floatingActionButton: FloatingActionButton(
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
*/
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator()); // пока загружаются данные, показываем индикатор загрузки
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'Ошибка: ${snapshot.error}')); // обработка ошибок
                }
                final ads = snapshot.data;
                if (ads == null || ads.isEmpty) {
                  return const Center(
                      child: Text(
                          'У вас пока нет объявлений')); // данных нет или пустой массив
                }
                return ListView.builder(
                      itemCount: ads.length,
                      itemBuilder: (context, index) {
                        var truck = ads[index];
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
                                    icon: const Icon(Icons.vertical_align_top),
                                    tooltip: 'Поднять в топ',
                                    onPressed: int.parse(truck['flag'].toString()) == 1
                                        ? () async {
                                            final bdVal = bd ?? int.tryParse('${truck['bd'] ?? 1}') ?? 1;
                                            final title = truck['marka']?.toString() ??
                                                truck['vidt']?.toString() ??
                                                'Объявление';
                                            final ok = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AdBoostScreen(
                                                  adId: int.parse('${truck['id']}'),
                                                  bd: bdVal,
                                                  adTitle: title,
                                                ),
                                              ),
                                            );
                                            if (ok == true && mounted) {
                                              setState(() {
                                                _adsFuture = fetchAds(bd!, idusers);
                                              });
                                            }
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      print(
                                          "ID: ${truck['id']}, Table Name: ${truck['tableName']}"); // Посмотрите, что реально приходит
                                      editTruck(truck['id'], context,
                                          truck['tableName']);
                                    },
                                  ),
                                  // Ваш исходный виджет кнопки
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      showDeleteDialog(
                                          context, truck['id'], bd);
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
                                  Text('Создано/изменено :',
                                      style:
                                          DefaultTextStyle.of(context).style),
                                  Text('${truck['created_at']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            if ((truck['marka'] != null) &&
                                (truck['marka'] != ''))
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
                            if ((truck['godv'] != null) &&
                                (truck['godv'] != ''))
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
                            if ((truck['vidt'] != null) &&
                                (truck['vidt'] != ''))
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
                            if ((truck['maxgruz'] != null) &&
                                (truck['maxgruz'] != ''))
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
                            if ((truck['dkuzov'] != null) &&
                                (truck['dkuzov'] != ''))
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
                            if ((truck['shkuzov'] != null) &&
                                (truck['shkuzov'] != ''))
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
                            if ((truck['vidk'] != null) &&
                                (truck['vidk'] != ''))
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
                            if ((truck['cenahaurs'] != null) &&
                                (truck['cenahaurs'] != ''))
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
                            if ((truck['cenasmena'] != null) &&
                                (truck['cenasmena'] != ''))
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
                            if ((truck['cenakm'] != null) &&
                                (truck['cenakm'] != ''))
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
                            if ((int.tryParse(truck['offerf']?.toString() ?? '0') ??
                                    0) >
                                0)
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
                                    SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final adBd = bdFromPerformerAd(
                                              Map<String, dynamic>.from(truck));
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  list_predloj_na_zayavki(
                                                nameImg:
                                                    truck['id'].toString(),
                                                bd: adBd,
                                                showBottomNav:
                                                    widget.showBottomNav,
                                              ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: blueaccentColor,
                                          foregroundColor: whiteprColor,
                                          shape: const CircleBorder(),
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(42, 42),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          '${truck['offerf']}',
                                          style: const TextStyle(
                                            color: whiteprColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((int.tryParse(truck['offerf']?.toString() ?? '0') ??
                                    0) ==
                                0)
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
                                    Text('0',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            if ((int.tryParse(truck['flag'].toString()) ?? 0) ==
                                1)
                              AdMatchSearchButton(
                                label: 'Найти заявки',
                                onPressed: () => openOrdersForPerformerAd(
                                  context,
                                  Map<String, dynamic>.from(truck),
                                ),
                              ),
                          ],
                        );
                      });
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Future<void> deleteTruck(int truckId, context, int bd) async {
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

        if (mounted) {
          setState(() {
            _adsFuture = fetchAds(bd, idusers);
          });
        }
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
