// TODO Implement this library.
import 'package:crgtransp72app/pages/change_user.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/sendNotification.dart';
import 'package:crgtransp72app/pages/zprofil_zakaz.dart';
import 'package:crgtransp72app/pages/zprofil_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'decimal_text_input_formatter.dart';
import 'customer_bottom_nav.dart';
import 'performer_bottom_nav.dart';

import '../design/colors.dart';
//import 'reguser1_name.dart';
import '../config.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OfferScreen2 extends StatefulWidget {
  final String userid;

  final dynamic bd;

  final dynamic useridobj;
  final bool useCustomerNavigation;

  /// Нижнее меню только если экран открыт без родительского shell (иначе дублируется с CityScreenIsp / профилем).
  final bool showBottomNav;

  /// Вкладка [CustomerBottomNav] при useCustomerNavigation (1 — заказы/заявки).
  final int customerBottomNavIndex;

  /// Пустая форма для новой заявки (после завершения/отмены или первого отклика).
  final bool forceNewOffer;

  const OfferScreen2({
    super.key,
    required this.userid,
    required this.bd,
    required this.useridobj,
    this.useCustomerNavigation = false,
    this.showBottomNav = false,
    this.customerBottomNavIndex = 1,
    this.forceNewOffer = false,
  });

  @override

  // ignore: library_private_types_in_public_api

  _OfferscreenForm createState() => _OfferscreenForm();
}

class _OfferscreenForm extends State<OfferScreen2> {
  final TextEditingController _cenakmController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  bool _hasExistingOffer = false;
  late String useridobj,
      userid; // Используйте правильные типы данных для вашей переменной
  late int bd;
  int userIdp = 0;
  @override
  void initState() {
    super.initState();
    userid = widget.userid;
    useridobj = widget.useridobj.toString();
    bd = widget.bd;

    getUserData();
  }

  /// Заказчик: [iduserp] — id заказчика, [listingId] — id объявления. Таблица **offer_dataf**.
  Future<void> _fetchOfferDataCustomer(String iduserp, String listingId) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/fetch_offer_zakaz.php'),
      body: {
        'iduserp': iduserp,
        'userId': listingId,
        'bd': bd.toString(),
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      final String cena = (data['cena'] ?? '').toString();
      final String about = (data['about'] ?? '').toString();
      _cenakmController.text = cena;
      _aboutController.text = about;
      if (mounted) {
        setState(() {
          _hasExistingOffer = cena.trim().isNotEmpty || about.trim().isNotEmpty;
        });
      }
      print(_cenakmController.text);
      print(_aboutController.text);
    } else {
      if (mounted) {
        setState(() {
          _hasExistingOffer = false;
        });
      }
      print(
          'Ошибка при получении данных пользователя: Статус-код: ${response.statusCode}, Тело: ${response.body}');
    }
  }

  /// Исполнитель: [iduserp] — id исполнителя, [listingId] — id объявления. Таблица **offer_data**.
  Future<void> _fetchOfferDataPerformer(
      int iduserp, String listingId, int bdVal) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/fetch_offer.php'),
      body: {
        'iduserp': iduserp.toString(),
        'userId': listingId,
        'bd': bdVal.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String cena = (data['cena'] ?? '').toString();
      final String about = (data['about'] ?? '').toString();
      _cenakmController.text = cena;
      _aboutController.text = about;
      if (mounted) {
        setState(() {
          _hasExistingOffer = cena.trim().isNotEmpty || about.trim().isNotEmpty;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasExistingOffer = false;
        });
      }
      print(
          'fetch_offer (исполнитель): ${response.statusCode} ${response.body}');
    }
  }

  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city1 = '';
  String phone = '';
  String email = '';
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
        final int idp = int.tryParse(data['idusers'].toString()) ?? 0;
        setState(() {
          userIdp = idp;
          firstName = data['firstName'];
          lastName = data['lastName'];
          middleName = data['middleName'];
          city1 = data['city'];
          phone = data['phone'];
          email = data['email'];
        });
        print('вывод id: $userIdp');
        if (idp > 0) {
          if (widget.forceNewOffer) {
            _cenakmController.clear();
            _aboutController.clear();
            if (mounted) {
              setState(() => _hasExistingOffer = false);
            }
          } else if (widget.useCustomerNavigation) {
            await _fetchOfferDataCustomer(idp.toString(), userid);
          } else {
            await _fetchOfferDataPerformer(idp, userid, bd);
          }
        }
        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  /// true, если данные успешно отправлены на сервер.
  Future<bool> uploadData() async {
    if (userIdp <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось определить пользователя.')));
      }
      return false;
    }
    if (widget.useCustomerNavigation) {
      return _uploadCustomerOffer();
    }
    return _uploadPerformerOffer();
  }

  Future<bool> _uploadCustomerOffer() async {
    final uri = Uri.parse('${Config.baseUrl}/api/add_offerzakaz.php');
    var request = http.MultipartRequest('POST', uri)
      ..fields['cena'] = _cenakmController.text
      ..fields['about'] = _aboutController.text
      ..fields['iduserp'] = userIdp.toString()
      ..fields['iduser'] = userid
      ..fields['bd'] = bd.toString();
    final response = await request.send();
    if (response.statusCode == 200) {
      print('Uploaded offer_dataf');
      return true;
    }
    print('add_offerzakaz failed');
    return false;
  }

  Future<bool> _uploadPerformerOffer() async {
    final uri = Uri.parse('${Config.baseUrl}/api/add_offer.php');
    var request = http.MultipartRequest('POST', uri)
      ..fields['cena'] = _cenakmController.text
      ..fields['about'] = _aboutController.text
      ..fields['iduserp'] = userIdp.toString()
      ..fields['iduser'] = userid
      ..fields['bd'] = bd.toString();
    final response = await request.send();
    if (response.statusCode == 200) {
      print('Uploaded offer_data');
      return true;
    }
    print('add_offer failed');
    return false;
  }

  Future<bool> checkOfferExists(int userId, String truckId, int bdVal) async {
    final path = widget.useCustomerNavigation
        ? 'check_offer_zakaz.php'
        : 'check_offer.php';
    final response = await http.get(Uri.parse(
        '${Config.baseUrl}/api/$path?iduser=$userId&truck=$truckId&bd=$bdVal'));

    if (response.statusCode == 200) {
      return json.decode(response.body)['exists'];
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.useCustomerNavigation
              ? (_hasExistingOffer ? 'Редактировать заказ' : 'Предложить заказ')
              : (_hasExistingOffer
                  ? 'Редактировать услугу'
                  : 'Предложить услугу'),
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Цена',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              // padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: _cenakmController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalTextInputFormatter()],
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  hintText: '150',
                  fillColor: grayprprColor,
                  filled: true,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: Text(
                widget.useCustomerNavigation ? 'Условия заявки' : 'Текст предложения',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.black38,
                  width: 2,
                ),
                color: grayprprColor, // Используйте вашу переменную цвета здесь
              ),
              child: TextField(
                controller: _aboutController,
                keyboardType:
                    TextInputType.multiline, // Делаем поле многострочным
                maxLines: null, // Без ограничения на количество строк
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
                  border: InputBorder.none, // Убираем внутреннюю рамку
                  // Добавьте другие настройки декорации здесь, если это необходимо
                ),
                // Добавьте другие настройки TextField здесь, если это необходимо
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 30.0),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                    style: TextButton.styleFrom(
                      fixedSize: const Size(double.infinity, 50),
                      foregroundColor: whiteprColor,
                      backgroundColor: blueaccentColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () async {
                      String about = _aboutController.text;
                      String cena = _cenakmController.text;

                      if (about.isEmpty || cena.isEmpty) {
                        // Проверяем оба поля на пустоту
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Пожалуйста, заполните все поля.')));
                        return;
                      }

                      final ok = await uploadData();
                      if (!ok || !mounted) return;

                      // Уведомление заказчику (id заказчика — widget.useridobj)
                      try {
                        final response1 = await http.post(
                          Uri.parse('${Config.baseUrl}/api/notification.php'),
                          body: {'iduserp': widget.useridobj.toString()},
                          headers: {
                            'Content-Type': 'application/x-www-form-urlencoded'
                          },
                        );
                        debugPrint('listing id: $userid');
                        debugPrint('заказчик id: ${widget.useridobj}');
                        debugPrint('исполнитель id: $userIdp');

                        debugPrint('Status: ${response1.statusCode}');
                        debugPrint('Body : ${response1.body}');
                        debugPrint('userid : ${userIdp}');

                        if (response1.statusCode == 200) {
                          final Map<String, dynamic> datafdcm =
                              jsonDecode(response1.body);

                          if (datafdcm['fcm_token'] != null) {
                            try {
                              await sendNotificationV1(
                                  deviceToken: datafdcm['fcm_token'],
                                  title: 'Привет от crgtransp72app!',
                                  body:
                                      'Исполнитель откликнулся на предложение!');

                              print('Уведомление отправлено');
                              print(datafdcm['fcm_token']);
                            } catch (e) {
                              print('Ошибка при отправке уведомления: $e');
                            }
                          } else {
                            _showSnack(context, 'Токен не найден в ответе');
                          }
                        } else {
                          _showSnack(context,
                              'Ошибка отправки уведомления (${response1.statusCode})');
                        }
                      } catch (err) {
                        print('Общая ошибка: $err');
                      }

                      if (!mounted) return;
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => widget.useCustomerNavigation
                              ? zprofil_zakaz(
                                  nameImg: userid,
                                  base: bd,
                                  useCustomerMenu: true,
                                )
                              : zprofil_zayavki(
                                  nameImg: '',
                                  base: bd,
                                  useCustomerMenu: false,
                                ),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text(
                      widget.useCustomerNavigation
                          ? 'Сохранить заявку'
                          : 'Отправить предложение',
                    )),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? (widget.useCustomerNavigation
              ? CustomerBottomNav(
                  currentIndex: widget.customerBottomNavIndex,
                )
              : const PerformerBottomNav(currentIndex: 0))
          : null,
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
