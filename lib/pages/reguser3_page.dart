import 'package:crgtransp72app/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/colors.dart';
import '../design/dimension.dart';

import 'loginpage.dart';
import 'reguser4_page_.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'reguser5_page_.dart';
import 'reguser_name.dart';

class RussianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('8')) {
      digits = digits.substring(1);
    } else if (digits.startsWith('7')) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(0, 10);
    }

    final b = StringBuffer('+7');
    if (digits.isNotEmpty) {
      b.write('(');
      b.write(digits.substring(0, digits.length.clamp(0, 3)));
      if (digits.length >= 3) b.write(')');
    }
    if (digits.length > 3) {
      b.write(' ');
      b.write(digits.substring(3, digits.length.clamp(3, 6)));
    }
    if (digits.length > 6) {
      b.write('-');
      b.write(digits.substring(6, digits.length.clamp(6, 8)));
    }
    if (digits.length > 8) {
      b.write('-');
      b.write(digits.substring(8, digits.length.clamp(8, 10)));
    }

    final formatted = b.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
  final url = Uri.parse('${Config.baseUrl}/api/agreement.html');
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw 'Не могу открыть $url';
  }
}

class _CregUser3NameState extends State<creguser3name> {
  late final TextEditingController phoneController = TextEditingController();
  late final TextEditingController emailController = TextEditingController();
  late final TextEditingController passwordController = TextEditingController();
  bool _isChecked = false;
  bool _obscurePassword = true;
  bool _isEmailVerified = false;
  String _verifiedEmail = '';

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('8')) {
      return '+7${digits.substring(1)}';
    }
    if (digits.length == 11 && digits.startsWith('7')) {
      return '+$digits';
    }
    return phone.trim();
  }

  bool _isValidPhone(String phone) {
    final normalized = _normalizePhone(phone);
    return RegExp(r'^\+7\d{10}$').hasMatch(normalized);
  }

  Future<Map<String, dynamic>> _postForm(
    String path,
    Map<String, String> body,
  ) async {
    final response = await http.post(
      Uri.parse(Config.baseUrl).replace(path: path),
      body: body,
    );
    try {
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'status': 'error',
        'message': 'Некорректный ответ сервера (${response.statusCode})',
      };
    }
  }

  Future<bool> _requestRegistrationCode(String email) async {
    final data = await _postForm('/api/request_registration_code.php', {
      'email': email,
    });
    if (data['status'] != 'success') {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${data['message'] ?? 'Ошибка отправки кода'}')),
      );
      return false;
    }
    return true;
  }

  Future<bool> _verifyRegistrationCode(String email, String code) async {
    final data = await _postForm('/api/verify_registration_code.php', {
      'email': email,
      'code': code,
    });
    if (data['status'] != 'success') {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${data['message'] ?? 'Ошибка проверки кода'}')),
      );
      return false;
    }
    return true;
  }

  Future<bool> _ensureEmailVerified(String email) async {
    if (_isEmailVerified && _verifiedEmail == email) return true;

    final sent = await _requestRegistrationCode(email);
    if (!sent || !mounted) return false;

    final TextEditingController codeController = TextEditingController();
    bool isSubmitting = false;
    bool isResending = false;

    final bool? verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Подтверждение e-mail'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Введите код, отправленный на $email'),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: '6-значный код',
                    counterText: '',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: isResending
                    ? null
                    : () async {
                        setDialogState(() => isResending = true);
                        await _requestRegistrationCode(email);
                        if (mounted) {
                          setDialogState(() => isResending = false);
                        }
                      },
                child: Text(isResending ? 'Отправка...' : 'Отправить код снова'),
              ),
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final code = codeController.text.trim();
                        if (code.length != 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Введите 6-значный код'),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        final ok = await _verifyRegistrationCode(email, code);
                        if (!mounted) return;
                        setDialogState(() => isSubmitting = false);
                        if (ok) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      },
                child: Text(isSubmitting ? 'Проверка...' : 'Подтвердить'),
              ),
            ],
          ),
        );
      },
    );

    if (verified == true) {
      setState(() {
        _isEmailVerified = true;
        _verifiedEmail = email;
      });
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    phoneController.text = '+7';
    phoneController.selection =
        TextSelection.collapsed(offset: phoneController.text.length);
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
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  RussianPhoneInputFormatter(),
                ],
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
                  hintText: '+7(___) ___-__-__',
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
                obscureText: _obscurePassword,
                decoration: InputDecoration(
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
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
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
                contentPadding: EdgeInsets.zero,
                title: GestureDetector(
                  onTap: _launchURL,
                  child: const Text(
                    'Принять пользовательское соглашение',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
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

                    bool validatePassword(String password) {
                      final RegExp regex =
                          RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
                      return regex.hasMatch(password);
                    }

                    String phone = _normalizePhone(phoneController.text);
                    String email = emailController.text.trim();
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
                    } else if (!_isValidPhone(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Введите корректный номер телефона в формате +7XXXXXXXXXX')));
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
                          content: Text('Примите пользовательское соглашение')));
                      return;
                    }

                    final verified = await _ensureEmailVerified(email);
                    if (!verified) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Подтвердите e-mail кодом для продолжения регистрации')));
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
                          'phone': phone,
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
