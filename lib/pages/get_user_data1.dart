import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
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

class MyAppGUD1 extends StatefulWidget {
  final String nameImg;

  const MyAppGUD1({super.key, required this.nameImg});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyAppGUD1> {
  List users = [];
  List _cities = [];
  String? _selectedCity;
  bool isSwitched = false;
//String nameImg;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  late String nameImg;

  @override
  void initState() {
    super.initState();
    nameImg = widget.nameImg;
    _fetchCities();

    getUserData().then((_) {
      // After getUserData completes, fetchUsers is called. Ensures city is updated.
      fetchUsers(nameImg, city);
    });
  }

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

  Future fetchUsers(String name, String city) async {
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
          title: Text(
            nameImg,
            style: const TextStyle(
              color: whiteprColor,
            ),
          ),
          backgroundColor: blueaccentColor,
        ),
        body: Column(
          children: [
// DropdownButton для выбора города
            DropdownButton(
              value: _selectedCity,
              hint: const Text("Выберите город"),
              items: _cities.map<DropdownMenuItem<String>>((dynamic city) {
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
              onChanged: (newValue) {
                setState(() {
                  _selectedCity = newValue;
                  fetchUsers(nameImg,
                      newValue!); // Перезагрузите пользователей на основе выбранного города
                });
              },
            ),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                          "В этом городе исполнителей раздела '$nameImg' нет"))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final nameFirm =
                            users[index]['namefirm'] ?? 'Частное лицо';
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
          ],
        ),
      ),
    );
  }
}
