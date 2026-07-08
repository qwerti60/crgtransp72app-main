import 'dart:typed_data';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/customer_bottom_nav.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/services/avatar_image_upload.dart';

import '../design/colors.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_rating_row.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

class zprofil_ld extends StatefulWidget {
  final bool showBottomNav;
  final bool isPerformerProfile;

  const zprofil_ld({
    super.key,
    this.showBottomNav = true,
    this.isPerformerProfile = false,
  });
  @override
  zprofil_ldForm createState() => zprofil_ldForm();
}

class zprofil_ldForm extends State<zprofil_ld> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var _currentPage = 0;
  bool isSwitched = false;
  Uint8List? fotouser;
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city = '';
  String phone = '';
  String email = '';
  int userId = 0;
  double avgRating = 0;
  int reviewsCount = 0;
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void _showImagePickOptions(BuildContext context) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить e-mail профиля')),
      );
      return;
    }

    final result = await AvatarImageUpload.runPickPreviewUploadFlow(
      context,
      email: email,
      onUploaded: (bytes) {
        if (!mounted) return;
        setState(() => fotouser = bytes);
      },
    );

    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? 'Загрузка успешна!' : 'Ошибка при загрузке изображения',
        ),
      ),
    );
  }

/*
  Future<void> _uploadImage(ui.Image image) async {
    // Преобразование ui.Image в Uint8List
    final Uint8List imgBytes = await _imageToUint8List(image);

    // Создаем запрос на сервер
    Uri uri =
        Uri.parse("${Config.baseUrl}/api/upload.php"); // Измените на ваш URL
    var request = http.MultipartRequest("POST", uri)
      ..fields['email'] = email // Замените на соответствующий ID пользователя
      ..files.add(http.MultipartFile.fromBytes(
          'fotouser', // Имя поля для файла, ожидаемое вашим PHP скриптом
          imgBytes,
          filename: 'image.png' // Имя файла
          ));

    // Отправляем запрос на сервер
    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Загрузка успешна!')));
      print("Загрузка успешна");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке изображения')));
      print("Ошибка при загрузке изображения");
    }
  }
*/
  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final apiPath = widget.isPerformerProfile
        ? '/api/getuserinfo_order.php'
        : '/api/getuserinfo.php';
    final response = await http
        .get(Uri.parse('${Config.baseUrl}$apiPath?token=$token'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['error'] != null) {
        print('Ошибка: ${data['error']}');
      } else {
        // Обновляем поля класса и UI
        setState(() {
          userId = data['idusers'];
          firstName = data['firstName'];
          lastName = data['lastName'];
          middleName = data['middleName'];
          city = data['city'];
          phone = data['phone'];
          email = data['email'];
          // Проверяем, есть ли изображение пользователя и преобразуем его из base64.
          fotouser = decodeUserPhotoFromApi(data['fotouser']);
          final rating = ProfileRatingRow.fromApiMap(
            Map<String, dynamic>.from(data),
          );
          avgRating = rating.avgRating;
          reviewsCount = rating.reviewsCount;
        });

        // Теперь переменные firstName, lastName, middleName, и userfoto доступны для использования в build() методе.
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        title: const Text(
          'Личные данные',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: SingleChildScrollView(
        key: _scaffoldKey, // Присвоение ключа Scaffold
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ProfileAvatar(fotouser: fotouser),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: Text(
                '$firstName $lastName', // Интерполяция используется для вставки значений
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (userId > 0)
              ProfileRatingRow(
                avgRating: avgRating,
                reviewsCount: reviewsCount,
                onTap: () {
                  if (widget.isPerformerProfile) {
                    ProfileRatingRow.openPerformerReviews(context, userId);
                  } else {
                    ProfileRatingRow.openCustomerReviews(context, userId);
                  }
                },
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: TexticonsColor,
                ),
                onPressed: () => _showImagePickOptions(context),
                child: const Text('Добавить(изменить) фото'),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Фамилия',
                style: TextStyle(
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
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  hintText: firstName,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Имя',
                style: TextStyle(
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
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  hintText: lastName,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Отчеество',
                style: TextStyle(
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
                decoration: InputDecoration(
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  hintText: middleName,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const CustomerBottomNav(currentIndex: 2)
          : null,
    );
  }
}
