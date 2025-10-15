import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/dimension.dart';
//import 'reguser1_name.dart';
import 'reguser2_page.dart';
import '../config.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class creguser_name extends StatefulWidget {
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

  const creguser_name(
      {super.key,
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
      required this.vidt});

  @override

  // ignore: library_private_types_in_public_api

  _creguser_nameForm createState() => _creguser_nameForm();
}

class _creguser_nameForm extends State<creguser_name> {
  List _vidk = [];
  String? _selectedVidkuzov;
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
  List _gp = [];
  String? _selectedGP;
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

    _fetchVidT();
    _fetchGP();
  }

  Future _fetchVidT() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/vidk.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _vidk = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load');
    }
  }

  Future _fetchGP() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/get_vidgr.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _gp = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController markaController = TextEditingController();
    final TextEditingController godvController = TextEditingController();
    final TextEditingController maxgruzkppController = TextEditingController();
    final TextEditingController dkuzovController = TextEditingController();
    final TextEditingController shkuzovController = TextEditingController();
    final TextEditingController vidkuzovController = TextEditingController();
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
                'Марка',
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
                controller: markaController,
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
                  hintText: 'Mercedes',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Год выпуска',
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
                controller: godvController,
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
                  hintText: '2011',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Грузоподъемность',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: _gp.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите грузоподьемность',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedGP,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGP = newValue;
                            });
                          },
                          items:
                              _gp.map<DropdownMenuItem<String>>((dynamic gp) {
                            return DropdownMenuItem(
                              value: gp['name'],
                              child: Text(
                                gp['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black38,
                                  fontSize: 16.0,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Длинна кузова',
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
                controller: dkuzovController,
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
                  hintText: '14',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Ширина кузова',
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
                controller: shkuzovController,
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
                  hintText: '3',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Вид кузова',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            /* Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              margin: EdgeInsets.only(top: 10.0),
              child: TextFormField(
                controller: _vidkuzovController,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  fillColor: grayprprColor,
                  filled: true,
                  hintText: '3',
                ),
              ),
            ),*/
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: _vidk.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите вид кузова',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedVidkuzov,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedVidkuzov = newValue;
                            });
                          },
                          items: _vidk
                              .map<DropdownMenuItem<String>>((dynamic vidk1) {
                            return DropdownMenuItem(
                              value: vidk1['namevidk'],
                              child: Text(
                                vidk1['namevidk'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black38,
                                  fontSize: 16.0,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => creguser2_name(
                                  rollNum: rollNum,
                                  statNum: statNum,
                                  firstName: firstName,
                                  middleName: middleName,
                                  lastName: lastName,
                                  city: city,
                                  phone: phone,
                                  email: email,
                                  password: password,
                                  namefirm: namefirm,
                                  innStr: innStr,
                                  ogrnStr: ogrnStr,
                                  kppStr: kppStr,
                                  vidt: vidt,
                                  marka: markaController.text,
                                  godv: godvController.text,
                                  maxgruz: _selectedGP!,
                                  dkuzov: dkuzovController.text,
                                  shkuzov: shkuzovController.text,
                                  vidk:
                                      _selectedVidkuzov!, //_selectedVidkuzov!,
                                )));
                    print(markaController.text);
                    print(godvController.text);
                    print(maxgruzkppController.text);
                    //            print(_selectedVidkuzov!);
                  },
                  child: const Text('Продолжить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
