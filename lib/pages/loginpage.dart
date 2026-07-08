//import 'dart:ffi';

import 'dart:async';
import 'dart:convert';

import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config.dart';
import '../design/dimension.dart';
import '../services/avatar_upload_prompt.dart';
import 'changestatis_page.dart';
import 'zakaz_screen1.dart';
import 'zakaz_screen2.dart';
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
  String? _passwordResetSentToEmail;

  Future<String?> _requestPasswordResetCode(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse(Config.baseUrl)
                .replace(path: '/api/request_password_reset.php'),
            body: {'email': email.trim()},
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['status'] == 'success') {
        _passwordResetSentToEmail =
            data['email']?.toString().trim().isNotEmpty == true
                ? data['email'].toString().trim()
                : email.trim();
        return null;
      }
      _passwordResetSentToEmail = null;
      return data['message']?.toString() ?? 'Не удалось отправить код';
    } catch (_) {
      _passwordResetSentToEmail = null;
      return 'Нет связи с сервером. Проверьте интернет.';
    }
  }

  Future<String?> _confirmPasswordReset({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(Config.baseUrl)
                .replace(path: '/api/confirm_password_reset.php'),
            body: {
              'email': email.trim(),
              'code': code.trim(),
              'new_password': password,
            },
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['status'] == 'success') {
        return null;
      }
      return data['message']?.toString() ?? 'Не удалось изменить пароль';
    } catch (_) {
      return 'Нет связи с сервером. Проверьте интернет.';
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    _resetEmailController.clear();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        var isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Восстановить пароль'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSubmitting,
                    decoration: const InputDecoration(
                      hintText: 'Введите e-mail',
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final email = _resetEmailController.text.trim();
                          final isValidEmail = RegExp(
                            r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
                          ).hasMatch(email);
                          if (!isValidEmail) {
                            setDialogState(() {
                              errorMessage = 'Введите корректный e-mail';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          final error = await _requestPasswordResetCode(email);
                          if (!dialogContext.mounted) return;

                          if (error == null) {
                            final sentTo = _passwordResetSentToEmail ?? email;
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Код отправлен на $sentTo. Проверьте входящие и спам.',
                                ),
                                duration: const Duration(seconds: 6),
                              ),
                            );
                            await _showConfirmResetDialog(sentTo);
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = error;
                          });
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Отправить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showConfirmResetDialog(String email) async {
    _resetCodeController.clear();
    _newPasswordController.clear();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        var obscurePassword = true;
        var isSubmitting = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Подтверждение'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _resetCodeController,
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting,
                    decoration:
                        const InputDecoration(hintText: 'Код из e-mail'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: obscurePassword,
                    enabled: !isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Новый пароль',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () {
                                setDialogState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final code = _resetCodeController.text.trim();
                          final newPassword = _newPasswordController.text;
                          if (code.isEmpty || newPassword.length < 8) {
                            setDialogState(() {
                              errorMessage =
                                  'Введите код и пароль не менее 8 символов';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            errorMessage = null;
                          });

                          final error = await _confirmPasswordReset(
                            email: email,
                            code: code,
                            password: newPassword,
                          );
                          if (!dialogContext.mounted) return;

                          if (error == null) {
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Пароль успешно изменен'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = error;
                          });
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сменить пароль'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAuthError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(content: Text(message)),
    );
  }

  void _goAfterLogin(BuildContext context, int rollNum) {
    switch (rollNum) {
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyApp(initialPage: 0)),
          (_) => false,
        );
        break;
      case 2:
      case 3:
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyAppZakazScreen(initialPage: 0)),
          (_) => false,
        );
        break;
      default:
        _showAuthError('Неизвестный тип аккаунта');
        break;
    }
  }

  void _login() async {
    try {
      final body = <String, String>{
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final response = await http
          .post(
            Uri.parse(Config.baseUrl).replace(path: '/api/autoriz1.php'),
            body: body,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final dynamic json;
      try {
        json = jsonDecode(response.body);
      } catch (_) {
        if (response.statusCode != 200) {
          _showAuthError(
              'Ошибка сервера (${response.statusCode}). Попробуйте позже.');
        } else {
          _showAuthError(
              'Сервер вернул неверный ответ. Обновите api/autoriz1.php на хостинге.');
        }
        return;
      }

      if (json['success'] == true && json['token'] != null) {
        await saveAuthToken(json['token']);
        final fcmOk = await syncPushFcmTokenAfterLogin();
        if (!fcmOk && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Push не подключён: разрешите уведомления в Настройках iPhone '
                'и перезапустите приложение.',
              ),
              duration: Duration(seconds: 6),
            ),
          );
        }
        if (!mounted) return;
        final rollNum = json['rollNum'] as int? ?? 0;
        final isPerformer = rollNum != 1;
        await maybePromptAvatarUploadAfterLogin(
          context,
          isPerformer: isPerformer,
        );
        if (!mounted) return;
        _goAfterLogin(context, rollNum);
      } else {
        _showAuthError(json['message']?.toString() ?? 'Ошибка авторизации');
      }
    } catch (_) {
      if (!mounted) return;
      _showAuthError('Нет связи с сервером. Проверьте интернет.');
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
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
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
              margin: const EdgeInsets.only(top: 16.0),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.fire_truck_outlined),
                label: const Text('Смотреть услуги без регистрации'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: blueaccentColor,
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MyApp()),
                    (route) => false,
                  );
                },
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
