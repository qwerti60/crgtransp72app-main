import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'User Registration',
      home: RegistrationScreen(),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State {
  final _usernameController = TextEditingController();
  String _message = '';

  Future checkUser() async {
    final response = await http.post(
      Uri.parse('http://www.ivnovav.ru/register.php'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'username': _usernameController.text,
      }),
    );

    if (response.statusCode == 200) {
      //String jsonsDataString = response.body.toString().replaceAll("\n", "");
      var jsonsDataString = await json.decode(json.encode(response.body));
      final data = jsonDecode(jsonsDataString);
//      final data = jsonDecode(response.body);
      if (data['exists']) {
        setState(() {
          _message = 'Username already taken. Please try another one.';
        });
      } else {
        setState(() {
          _message = 'User is registered successfully.';
        });
      }
    } else {
      setState(() {
        _message = 'Error: Unable to check username.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkUser,
              child: const Text('Check Username'),
            ),
            const SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
