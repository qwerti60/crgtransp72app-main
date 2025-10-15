import 'package:flutter/material.dart';

import '../config.dart';
import '../design/colors.dart';
import '../design/dimension.dart';
import 'reguser3_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Step 1.
String dropdownValue = 'Абатское';
late int RolNum;

class Creguser1_Name extends StatefulWidget {
  const Creguser1_Name(
      {super.key, required this.RolNum, required this.StatNum});

  final int RolNum;
  final int StatNum;
  //String city  = '';
  //final String strData;

  @override

  // ignore: library_private_types_in_public_api

  _Creguser1_NameForm createState() => _Creguser1_NameForm();
}

class _Creguser1_NameForm extends State<Creguser1_Name> {
  List _cities = [];
  String? _selectedCity;

  late int rolNum;
  late int statNum;
  String strData = '';
  String city = '';

  @override
  void initState() {
    super.initState();
    _fetchCities();
    // Переносим параметры из виджета в состояние
    rolNum = widget.RolNum;
    statNum = widget.StatNum;
    if (rolNum == 1) {
      strData = 'Физ. лица';
    } else if (rolNum == 2) {
      strData = 'Юр. лица';
    }
  }

  Future _fetchCities() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/cities.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _cities = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
  }

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
//  String? _selectedCity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('Регистрация',
                style: TextStyle(
                  color: whiteprColor,
                  fontSize: fontSize30,
                )),
            Text(strData,
                style: const TextStyle(color: whiteprColor, fontSize: 24)),
          ],
        ),
        toolbarHeight: 72, // Опционально: регулировка высоты AppBar
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                'Имя',
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
                controller: _firstNameController,
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
                  hintText: 'Иван',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Отчество',
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
                controller: _middleNameController,
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
                  hintText: 'Иванович',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Фамилия',
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
                controller: _lastNameController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  hintText: 'Иванов',
                  fillColor: grayprprColor,
                  filled: true,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Адрес',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            // Получайте ширину экрана с контекстом.

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: _cities.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите город(населенный пункт',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedCity,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                            });
                          },
                          items: _cities
                              .map<DropdownMenuItem<String>>((dynamic city) {
                            return DropdownMenuItem(
                              value: city['name'],
                              child: Text(
                                city['name'],
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
                    String firstName = _firstNameController.text;
                    String middleName = _middleNameController.text;
                    String lastName = _lastNameController.text;

                    if (firstName.isEmpty ||
                        middleName.isEmpty ||
                        lastName.isEmpty ||
                        _selectedCity == null) {
// Если хотя бы одно поле пустое, показываем осведомительное сообщение
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Пожалуйста, заполните все поля и выберите город.'),
                        ),
                      );
                    } else {
// Все поля заполнены, переходим на следующую страницу
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => creguser3name(
                            // rolNum: rolNum,
                            statNum: statNum,
                            firstName: firstName,
                            middleName: middleName,
                            lastName: lastName,
                            city: _selectedCity!,
                            rollNum: rolNum,
                          ),
                        ),
                      );
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
