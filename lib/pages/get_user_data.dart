import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../design/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _makePhoneCall(String phoneNumber) async {
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: phoneNumber,
  );
  if (await canLaunchUrl(launchUri)) {
    await launchUrl(launchUri);
  } else {
    throw 'Could not launch $launchUri';
  }
}

class MyAppGUD extends StatefulWidget {
  final String nameImg;

  const MyAppGUD({super.key, required this.nameImg});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State {
  List users = [];
  final _currentPage = 0;
  bool isSwitched = false;

  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  int idusers = 0;
  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final response = await http
        .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          idusers = data['idusers'];
          firstName = data['firstName'];
          lastName = data['lastName'];
          middleName = data['middleName'];
          city = data['city'];
          phone = data['phone'];
          email = data['email'];
        });

        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  @override
  void initState() {
    super.initState();

    getUserData().then((_) {
      // After getUserData completes, fetchUsers is called. Ensures city is updated.
      fetchUsers('Грузчики');
    });
  }

  Future fetchUsers(String name) async {
    var response = await http.get(Uri.parse(
        'http://ivnovav.ru/api/getuserdata_ispolnit.php?name=$name&city=$city'));

    print('city: $city');
    print('name: $name');

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data == null || data.isEmpty) {
        // Проверяем на null или пустоту
        // В таком случае устанавливаем users в пустой список, чтобы ничего не отображать
        setState(() {
          users = [];
        });
      } else {
        setState(() {
          users = data;
        });
      }
    } else {
      throw Exception('Failed to load users');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Грузчики',
            style: TextStyle(
              color: whiteprColor,
            ),
          ),
          backgroundColor: blueaccentColor,
        ),
        body: users.isEmpty // Проверка, если список users пуст
            ? Center(
                child: Text("В этом городе нет грузчиков $idusers"),
              )
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final nameFirm = users[index]['namefirm'] ?? 'Частное лицо';
                  return ListTile(
                    title: Text(
                        '${users[index]['firstName']} ${users[index]['lastName']}'),
                    subtitle: Text(
                        '$nameFirm, ${users[index]['city']}, ${users[index]['phone']}'),
                    onTap: users[index]['phone'] != null
                        ? () => _makePhoneCall(users[index]['phone'])
                        : null,
                  );
                },
              ),
      ),
    );
  }
}
