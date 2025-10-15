import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/dimension.dart';
import '../config.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

import 'reguser2_page.dart';
import 'reguser_name.dart';

//import 'reguser2_page_.dart';

// Step 1.
String dropdownValue = 'Мини погрузчики и складская техника';

class creguser5_name_ extends StatefulWidget {
  final int rollNum;
  final int statNum;
  final String firstName;
  final String lastName;
  final String middleName;
  final String city;
  final String email;
  final String phone;
  final String password;
  final String namefirm;
  final String innStr;
  final String ogrnStr;
  final String kppStr;

  const creguser5_name_(
      {super.key,
      required this.rollNum,
      required this.statNum,
      required this.firstName,
      required this.lastName,
      required this.middleName,
      required this.city,
      required this.email,
      required this.phone,
      required this.password,
      required this.namefirm,
      required this.ogrnStr,
      required this.innStr,
      required this.kppStr});
  @override

  // ignore: library_private_types_in_public_api

  _creguser5_nameForm createState() => _creguser5_nameForm();
}

class _creguser5_nameForm extends State<creguser5_name_> {
  List _vidt = [];
  String? _selectedVidt;
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

    _fetchVidT();
  }

  Future _fetchVidT() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/vidt.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _vidt = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Вид спецтехники',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
// Step 2.
              child: _vidt.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите вид спецтехники',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedVidt,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedVidt = newValue;
                            });
                          },
                          items: _vidt
                              .map<DropdownMenuItem<String>>((dynamic vidt) {
                            return DropdownMenuItem(
                              value: vidt['name'],
                              child: Text(
                                vidt['name'],
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
                    // String namefirm = _nameController.text;
                    if (rollNum == 3) {
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
                                    vidt: _selectedVidt!,
                                    godv: '',
                                    marka: '',
                                    maxgruz: '',
                                    dkuzov: '',
                                    shkuzov: '',
                                    vidk: '',
                                  )));
                    } else {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => creguser_name(
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
                                    vidt: _selectedVidt!,
                                  )));
                    }
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
