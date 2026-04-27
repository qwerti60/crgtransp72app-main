//import 'dart:ffi';

import 'dart:convert';

import 'package:crgtransp72app/design/colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config.dart';
import '../design/dimension.dart';
import 'change_user.dart';
import 'changestatis_page.dart';
import 'gruz_vodit.dart';
//import 'profil_page.dart';
import 'rent_z.dart';
import 'zprofil_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  var login;
  var password;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final TextEditingController _resetEmailController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureNewPassword = true;

  Future<void> _requestPasswordResetCode(String email) async {
    final response = await http.post(
      Uri.parse(Config.baseUrl).replace(path: '/api/request_password_reset.php'),
      body: {'email': email.trim()},
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    final data = jsonDecode(response.body);
    if (!mounted) return;

    if (response.statusCode == 200 && data['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Код отправлен на e-mail')),
      );
      Navigator.of(context).pop();
      _showConfirmResetDialog(email.trim());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Не удалось отправить код')),
    );
  }

  Future<void> _confirmPasswordReset(String email, String code, String password) async {
    final response = await http.post(
      Uri.parse(Config.baseUrl).replace(path: '/api/confirm_password_reset.php'),
      body: {
        'email': email.trim(),
        'code': code.trim(),
        'new_password': password,
      },
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    final data = jsonDecode(response.body);
    if (!mounted) return;

    if (response.statusCode == 200 && data['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль успешно изменен')),
      );
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'] ?? 'Не удалось изменить пароль')),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    _resetEmailController.clear();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Восстановить пароль'),
          content: TextFormField(
            controller: _resetEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Введите e-mail',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final email = _resetEmailController.text.trim();
                final isValidEmail = RegExp(
                  r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(email);
                if (!isValidEmail) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите корректный e-mail')),
                  );
                  return;
                }
                _requestPasswordResetCode(email);
              },
              child: const Text('Отправить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmResetDialog(String email) async {
    _resetCodeController.clear();
    _newPasswordController.clear();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Подтверждение'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _resetCodeController,
                    decoration: const InputDecoration(hintText: 'Код из e-mail'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Новый пароль',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    final code = _resetCodeController.text.trim();
                    final newPassword = _newPasswordController.text;
                    if (code.isEmpty || newPassword.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Введите код и пароль не менее 8 символов'),
                        ),
                      );
                      return;
                    }
                    _confirmPasswordReset(email, code, newPassword);
                  },
                  child: const Text('Сменить пароль'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _login() async {
    final prefs = await SharedPreferences.getInstance();
    final fcmToken =
        prefs.getString('fcm_token'); // Читаем сохранённый токен FCM

    // Формируем тело запроса для авторизации
    var response = await http.post(
      Uri.parse(Config.baseUrl).replace(path: '/api/autoriz1.php'),
      body: {
        'email': _emailController.text,
        'password': _passwordController.text,
        if (fcmToken != null)
          'fcm_token':
              fcmToken, // Теперь токен передается только если он существует
        // Передаём токен FCM на сервер
      },
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
    );

    var json = jsonDecode(response.body);

    Future<void> saveTokenSecurely(String token) async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('789456123', token); // Сохраняем обычный токен (не FCM!)
      print(json['token']);
      print(json['rollNum']);
    }

    // Проверяем success и token
    if (json['success'] != null && json['success'] && json['token'] != null) {
      saveTokenSecurely(json['token']);

      // Переход на соответствующие экраны в зависимости от rollNum
      switch (json['rollNum']) {
        case 1:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const change_user()));
          break;
        case 2:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const zprofil_name()));
          break;
        case 3:
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const gruz_vodit()));
          break;
        default:
          break;
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(content: Text(json['message']));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Авторизация',
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
            const Text('Авторизация',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: blackprColor,
                  fontSize: fontSize30,
                )),
            /*Text('Логин',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 25.0,
                )),*/
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 30.0),
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'E-mail',
                  fillColor: grayprprColor,
                  filled: true,
                ),
                onChanged: (value) {
                  login = value;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  prefixIcon: Icon(Icons.lock),
                  hintText: 'Пароль',
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
                onChanged: (value) {
                  password = value;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
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
                      _login();
                    },
                    child: const Text('Войти')),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 24.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: blueaccentColor,
                ),
                onPressed: _showForgotPasswordDialog,
                child: const Text('Восстановить пароль'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 40.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: blueaccentColor,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const chagestatus(
                                data: 1,
                              )));
                },
                child: const Text('Регистрация'),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: OutlinedButton.icon(
                icon: Icon(Icons.group_add_outlined),
                label: const Text('Присоединиться к группе'),
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.blueAccent),
                ),
                onPressed: () {
                  launchUrlString("https://t.me/+bocT1PzkmNIyZmQy");
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

signup(login, password) async {
  var url = "127.0.0.1:5000";
  final response = await http.post(
    url as Uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'login': login,
      'password': password,
    }),
  );

  if (response.statusCode == 201) {
    // If the server did return a 201 CREATED response,
    // then parse the JSON.
  } else {
    // If the server did not return a 201 CREATED response,
    // then throw an exception.
    throw Exception('Failed to create album.');
  }
}
