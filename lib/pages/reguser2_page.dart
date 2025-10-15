import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/dimension.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import 'loginpage.dart';

class creguser2_name extends StatefulWidget {
  final int statNum;
  final int rollNum;
  final String firstName;
  final String middleName;
  final String lastName;
  final String city;
  final String phone;
  final String email;
  final String password;
  final String namefirm;
  final String innStr;
  final String ogrnStr;
  final String kppStr;
  final String vidt;
  final String marka;
  final String godv;
  final String maxgruz;
  final String dkuzov;
  final String shkuzov;
  final String vidk;

  const creguser2_name({
    super.key,
    required this.statNum,
    required this.rollNum,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.city,
    required this.phone,
    required this.email,
    required this.password,
    required this.namefirm,
    required this.ogrnStr,
    required this.innStr,
    required this.kppStr,
    required this.vidt,
    required this.marka,
    required this.godv,
    required this.maxgruz,
    required this.dkuzov,
    required this.shkuzov,
    required this.vidk,
  });

  @override
  _creguser2_nameForm createState() => _creguser2_nameForm();
}

class _creguser2_nameForm extends State<creguser2_name> {
  late int statNum;
  late int rollNum;
  late String firstName;
  late String middleName;
  late String lastName;
  late String city;
  late String phone;
  late String email;
  late String password;
  late String namefirm;
  late String innStr;
  late String ogrnStr;
  late String kppStr;
  late String vidt;
  late String marka;
  late String godv;
  late String maxgruz;
  late String dkuzov;
  late String shkuzov;
  late String vidk;
  @override
  void initState() {
    super.initState();

    // Инициализация переменных значениями, переданными через виджет
    statNum = widget.statNum;
    rollNum = widget.rollNum;
    firstName = widget.firstName;
    middleName = widget.middleName;
    lastName = widget.lastName;
    city = widget.city;
    phone = widget.phone;
    email = widget.email;
    password = widget.password;
    namefirm = widget.namefirm;
    innStr = widget.innStr;
    ogrnStr = widget.ogrnStr;
    kppStr = widget.kppStr;
    vidt = widget.vidt;
    marka = widget.marka;
    godv = widget.godv;
    maxgruz = widget.maxgruz;
    dkuzov = widget.dkuzov;
    shkuzov = widget.shkuzov;
    vidk = widget.vidk;

    printProperties();
  }

  void printProperties() {
    print('statNum: $statNum');
    print('rollNum: $rollNum');
    print('firstName: $firstName');
    print('middleName: $middleName');
    print('lastName: $lastName');
    print('city: $city');
    print('phone: $phone');
    print('email: $email');
    print('password: $password');
    print('namefirm: $namefirm');
    print('ogrnStr: $ogrnStr');
    print('innStr: $innStr');
    print('kppStr: $kppStr');
    print('vidt: $vidt');
    print('marka: $marka');
    print('godv: $godv');
    print('maxgruz: $maxgruz');
    print('dkuzov: $dkuzov');
    print('shkuzov: $shkuzov');
    print('vidk: $vidk');
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController cenahaursController = TextEditingController();
    final TextEditingController cenasmenaController = TextEditingController();
    final TextEditingController cenakmController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Регистрация',
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
            const SizedBox(height: 50.0),
            Image.asset(
              'assets/images/logo.png', // путь к изображению
              width: 189, // ширина изображения
              height: 119, // высота изображения
            ),
            const Text('Регистрация',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: blackprColor,
                  fontSize: fontSize30,
                )),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Час',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: cenahaursController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  fillColor: grayprprColor,
                  filled: true,
                  hintText: '1000',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Смена',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: cenasmenaController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  fillColor: grayprprColor,
                  filled: true,
                  hintText: '10 000',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'За км',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: cenakmController,
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
                      String cenahaurs = cenahaursController.text;
                      String cenasmena = cenasmenaController.text;
                      String cenakm = cenakmController.text;

                      if (cenahaurs.isEmpty || cenasmena.isEmpty) {
// Если хотя бы одно поле пустое, показываем осведомительное сообщение
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пожалуйста, заполните все поля.'),
                          ),
                        );
                        return;
                      }
                      //`rollNum`, `statNum`, `firstName`, `lastName`, `middleName`, `city`, `phone`, `email`, `password`, `namefirm`, `innStr`, `ogrnStr`, `kppStr`, `vidt`, `marka`, `godv`, `maxgruz`, `dkuzov`, `shkuzov`, `vidk`, `cenahaurs`, `cenasmena`, `cenakm`7
                      if ((rollNum == 2 && statNum == 1) ||
                          (rollNum == 2 && statNum == 2) ||
                          (rollNum == 3 && statNum == 1) ||
                          (rollNum == 3 && statNum == 2)) {
                        final response = await http.post(
                          Uri.parse(Config.baseUrl)
                              .replace(path: '/api/register1.php'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'rollNum': rollNum,
                            'statNum': statNum,
                            'firstName': firstName,
                            'lastName': lastName,
                            'middleName': middleName,
                            'city': city,
                            'phone': phone,
                            'email': email,
                            'password': password,
                            'namefirm': namefirm,
                            'innStr': innStr,
                            'ogrnStr': ogrnStr,
                            'kppStr': kppStr,
                            'vidt': vidt,
                            'marka': marka,
                            'godv': godv,
                            'maxgruz': maxgruz,
                            'dkuzov': dkuzov,
                            'shkuzov': shkuzov,
                            'vidk': vidk,
                            'cenahaurs': cenahaursController.text,
                            'cenasmena': cenasmenaController.text,
                            'cenakm': cenakmController.text
                          }),
                        );

                        print(marka);
                        print(godv);
                        print(maxgruz);
                        print(dkuzov);
                        print(shkuzov);

                        if (response.statusCode == 200) {
                          print(response.body);
                          final data = json.decode(response.body);

                          if (data['status'] == 'success') {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Регистрация успешна!')));
// Перейти на экран авторизации
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Ошибка: ${data['message']}')));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ошибка сервера')));
                        }
                      }
                    },
                    child: const Text('Продолжить')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
