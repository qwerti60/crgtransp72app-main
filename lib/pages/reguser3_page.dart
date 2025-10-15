import 'package:crgtransp72app/config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/colors.dart';
import '../design/dimension.dart';

import 'loginpage.dart';
import 'reguser4_page_.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'reguser5_page_.dart';
import 'reguser_name.dart';

class creguser3name extends StatefulWidget {
  final int rollNum;
  final int statNum;
  final String firstName;
  final String lastName;
  final String middleName;
  final String city;

  const creguser3name({
    super.key,
    required this.rollNum,
    required this.statNum,
    required this.firstName,
    required this.lastName,
    required this.middleName,
    required this.city,
  });

  @override
  _CregUser3NameState createState() => _CregUser3NameState();
}

void _launchURL() async {
  const url =
      '${Config.baseUrl}/api/agreement.html'; // Укажите здесь URL вашего пользовательского соглашения
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Не могу открыть $url';
  }
}

class _CregUser3NameState extends State<creguser3name> {
  late final TextEditingController phoneController = TextEditingController();
  late final TextEditingController emailController = TextEditingController();
  late final TextEditingController passwordController = TextEditingController();
  bool _isChecked = false;

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
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Номер телефона',
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
                controller: phoneController,
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
                  // hintText: '8(999) 888 77-66',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле не должно быть пустым';
                  }
                  return null;
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Эл. почта',
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
                controller: emailController,
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
                  hintText: 'ivanov@yandex.com',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле не должно быть пустым';
                  }
                  return null;
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Пароль',
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
                controller: passwordController,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле не должно быть пустым';
                  }
                  return null;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero, // Убираем отступ, если нужно
                title: GestureDetector(
                  onTap: () {
                    _launchURL();
                  },
                  child: const Text(
                    "Принять пользовательское соглашение",
                    style: TextStyle(
                      color: Colors.blue, // Цвет текста-ссылки
                      decoration: TextDecoration
                          .underline, // Подчеркивание как у ссылок
                    ),
                  ),
                ),
                value: _isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    _isChecked = value!;
                  });
                },
                activeColor: Colors.blue, // Цвет галочки при активации
                checkColor: Colors.white, // Цвет флажка галочки
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
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueAccent,
                    disabledForegroundColor: Colors.grey,
                    shape: const BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                  onPressed: () async {
                    bool validateEmail(String email) {
                      // Регулярное выражение для синтаксической проверки email
                      String pattern =
                          r'^[a-zA-Z0-9]+([._\-\+]?[a-zA-Z0-9]+)*@[a-zA-Z0-9]+(\.[a-zA-Z]{2,})+$';
                      RegExp regex = RegExp(pattern);
                      return regex.hasMatch(email);
                    }

                    bool validatePhone(String phone) {
                      final RegExp regex = RegExp(r'^\+?[0-9]{10,15}$');
                      return regex.hasMatch(phone);
                    }

                    bool validatePassword(String password) {
                      final RegExp regex =
                          RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
                      return regex.hasMatch(password);
                    }

                    String phone = phoneController.text;
                    String email = emailController.text;
                    String password = passwordController.text;

                    if (phone.isEmpty || email.isEmpty) {
// Если хотя бы одно поле пустое, показываем осведомительное сообщение
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Пожалуйста, заполните все поля и выберите город.'),
                        ),
                      );
                      return;
                    } else if (!validatePhone(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Введите корректный номер телефона')));
                      return;
                    } else if (!validateEmail(email)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Введите корректный email')));
                      return;
                    } else if (!validatePassword(password)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Пароль должен быть не менее 8 символов, содержать буквы и цифры')));
                      return;
                    } else if (_isChecked == false) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Примте пользовательское соглашение')));
                      return;
                    }
                    if ((widget.rollNum == 1 && widget.statNum == 2) ||
                        (widget.rollNum == 4 && widget.statNum == 2)) {
                      final response = await http.post(
                        Uri.parse(Config.baseUrl)
                            .replace(path: '/api/regtest.php'),
                        body: json.encode({
                          'email': emailController.text,
                          'password': passwordController.text,
                          'phone': phoneController.text,
                          'rollNum': widget
                              .rollNum, // пример данных из предыдущего окна
                          'statNum': widget
                              .statNum, // пример данных из предыдущего окна
                          'firstName': widget
                              .firstName, // пример данных из предыдущего окна
                          'lastName': widget
                              .lastName, // пример данных из предыдущего окна
                          'middleName': widget
                              .middleName, // пример данных из предыдущего окна
                          'city': widget.city,
                        }),
                      );

                      final responseData = json.decode(response.body);

                      if (responseData['status'] == 'error') {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(responseData['message'])));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Регистрация успешна')));
                      }
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));
                    }
                    if ((widget.rollNum == 1 && widget.statNum == 1) ||
                        (widget.rollNum == 2 && widget.statNum == 1) ||
                        (widget.rollNum == 3 && widget.statNum == 1) ||
                        (widget.rollNum == 4 && widget.statNum == 1)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => creguser4_name_(
                              rollNum: widget.rollNum,
                              statNum: widget.statNum,
                              firstName: widget.firstName,
                              middleName: widget.middleName,
                              lastName: widget.lastName,
                              city: widget.city,
                              phone: phone,
                              email: email,
                              password: password),
                        ),
                      );
                    }
                    if ((widget.rollNum == 2 && widget.statNum == 2)) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => creguser_name(
                              rollNum: widget.rollNum,
                              statNum: widget.statNum,
                              firstName: widget.firstName,
                              middleName: widget.middleName,
                              lastName: widget.lastName,
                              city: widget.city,
                              phone: phone,
                              email: email,
                              password: password,
                              namefirm: '',
                              innStr: '',
                              ogrnStr: '',
                              kppStr: '',
                              vidt: ''),
                        ),
                      );
                    }
                    if (widget.rollNum == 3 && widget.statNum == 2) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => creguser5_name_(
                                    rollNum: widget.rollNum,
                                    statNum: widget.statNum,
                                    firstName: widget.firstName,
                                    middleName: widget.middleName,
                                    lastName: widget.lastName,
                                    city: widget.city,
                                    phone: phone,
                                    email: email,
                                    password: password,
                                    namefirm: '',
                                    innStr: '',
                                    ogrnStr: '',
                                    kppStr: '',
                                  )));
                    }
                  },
                  child: Text((widget.rollNum == 1 && widget.statNum == 2) ||
                          (widget.rollNum == 4 && widget.statNum == 2)
                      ? 'Регистрация'
                      : 'Продолжить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
