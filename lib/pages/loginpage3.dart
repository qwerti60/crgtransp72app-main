import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyAppreg extends StatelessWidget {
  const MyAppreg({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Registration',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Register'),
        ),
        body: const RegisterForm(),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State {
  final _formKey = GlobalKey();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future _registerUser(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('http://ivnovav.ru/reg.php'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      print('User registered successfully');
    } else {
      throw Exception('Failed to register user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your username';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                GlobalKey<FormState> formKey = GlobalKey();
                bool validateAndSaveForm() {
                  final form = formKey.currentState!;
                  if (form.validate() == true) {
                    _registerUser(
                      _usernameController.text,
                      _emailController.text,
                      _passwordController.text,
                    );
                  }
                  return false;
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
