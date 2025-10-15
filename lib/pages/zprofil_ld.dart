import 'dart:typed_data';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';

import '../design/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'dart:async';

class zprofil_ld extends StatefulWidget {
  const zprofil_ld({super.key});
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
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Let user select photo from gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    // Alternatively, let the user take a photo
    // final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Преобразование выбранного изображения
      _transformAndUploadImage(image, _scaffoldKey.currentContext!);
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);
    // Здесь вы можете использовать полученный файл
    if (pickedFile != null) {
      // Преобразование выбранного изображения
      await _transformAndUploadImage(pickedFile, _scaffoldKey.currentContext!);
    }
  }

  Future<void> _transformAndUploadImage(
      XFile image, BuildContext context) async {
    // Загрузка исходного изображения
    var originalImageFile = File(image.path);
    img.Image originalImage =
        img.decodeImage(originalImageFile.readAsBytesSync())!;

    // Изменение размера изображения
    img.Image resizedImg =
        img.copyResize(originalImage, width: 100, height: 100);

    // Преобразование в круглое
    ui.Image roundedImage = await _convertToRoundedImage(resizedImg);

    // Преобразование ui.Image в Uint8List для отображения
    ByteData? byteData =
        await roundedImage.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // Показ всплывающего окна перед отправкой

    if (!mounted) return;
    bool? shouldUpload = await showDialog<bool>(
      context: _scaffoldKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Предпросмотр'),
        content: Image.memory(pngBytes),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );

    // Если пользователь подтвердил, загружаем на сервер
    if (shouldUpload == true) {
      _uploadImage(pngBytes, email);
    }
  }

// Сюда можно вставить функции _convertToRoundedImage и _uploadImage,
// с учетом вашего текущего кода и контекста.

  Future<ui.Image> _convertToRoundedImage(img.Image inputImage) async {
    // Первый шаг: преобразуем img.Image (из пакета image) в Uint8List
    Uint8List imageBytes = Uint8List.fromList(img.encodePng(inputImage));

    // Загружаем Uint8List как ui.Image для последующего использования с Canvas
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imageBytes, (uiImage) {
      completer.complete(uiImage);
    });
    ui.Image image = await completer.future;

    // Создаем объект ui.PictureRecorder для записи процесса рисования
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder);

    // Размеры изображения
    double imgWidth = image.width.toDouble();
    double imgHeight = image.height.toDouble();
    Rect oval = Rect.fromLTWH(0, 0, imgWidth, imgHeight);

    // Path и Paint для создания кругового клиппирования
    Path clipOvalPath = Path()..addOval(oval);
    canvas.clipPath(clipOvalPath);

    // Рисуем изображение в круглом клиппировании
    paintImage(canvas: canvas, rect: oval, image: image, fit: BoxFit.fill);

    // Преобразуем Picture в Image для возвращения
    ui.Picture picture = recorder.endRecording();
    final ui.Image roundedImage =
        await picture.toImage(image.width, image.height);

    return roundedImage;
  }

// Эта функция нужна для непосредственного рисования изображения на канвасе.
  void paintImage({
    required Canvas canvas,
    required Rect rect,
    required ui.Image image,
    required BoxFit fit,
  }) {
    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());
    final FittedSizes sizes = applyBoxFit(fit, imageSize, rect.size);
    final Rect inputSubrect =
        Alignment.center.inscribe(sizes.source, Offset.zero & imageSize);
    final Rect outputSubrect =
        Alignment.center.inscribe(sizes.destination, rect);
    canvas.drawImageRect(image, inputSubrect, outputSubrect, Paint());
  }

  // Функция показа диалогового окна
  void _showImagePickOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Выбор изображения"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextButton(
                  child: const Text("Загрузить из фотогалереи"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImage();
                  },
                ),
                TextButton(
                  child: const Text("Сделать фото"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImageFromCamera(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _imageToUint8List(ui.Image image) async {
    // Создание объекта ByteData из ui.Image
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    // Преобразование ByteData в Uint8List
    final Uint8List imgBytes = byteData!.buffer.asUint8List();
    return imgBytes;
  }

  Future _uploadImage(Uint8List imageBytes, String email) async {
    String base64Image = base64Encode(imageBytes);
    var response = await http.post(
      Uri.parse('http://ivnovav.ru/api/upload.php'),
      body: {
        'image': base64Image,
        'email': email,
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Загрузка успешна!')));
      setState(() {
        fotouser = imageBytes;
      });
      print("Загрузка успешна");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при загрузке изображения')));
      print("Ошибка при загрузке изображения");
    }
  }

/*
  Future<void> _uploadImage(ui.Image image) async {
    // Преобразование ui.Image в Uint8List
    final Uint8List imgBytes = await _imageToUint8List(image);

    // Создаем запрос на сервер
    Uri uri =
        Uri.parse("http://ivnovav.ru/api/upload.php"); // Измените на ваш URL
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
    final response = await http
        .get(Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$token'));

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
          fotouser =
              data['fotouser'] != null ? base64Decode(data['fotouser']) : null;
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
      body: SingleChildScrollView(
        key: _scaffoldKey, // Присвоение ключа Scaffold
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 150,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image:
                      AssetImage("assets/images/bgcolor_head_blue_white.png"),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(
                // Центрируем изображение
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: fotouser != null
                      ? Image.memory(
                          fotouser!,
                          // fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Ошибка при загрузке изображения: $error');
                            // Возвращает виджет, который отображается в случае ошибки
                            return Icon(Icons.error);
                          },
                        )
                      : Image.asset(
                          'assets/images/fotouser.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                'Ошибка при загрузке изображения из ассетов: $error');
                            // Возвращает виджет, который отображается в случае ошибки
                            return Icon(Icons.error);
                          },
                        ),
                ),
              ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 20.0),
              child: const Text(
                'Банковская карта',
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
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    borderSide: BorderSide(color: blueaccentColor),
                  ),
                  hintText: '0000 0000 0000 0000',
                ),
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
                      backgroundColor: violetColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () {},
                    child: const Text('Привязать карту')),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fire_truck),
            label: 'Техника',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subject),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Водители',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Профиль',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentPage,
        fixedColor: violetColor,
        onTap: (int intIndex) {
          setState(() {
            _currentPage = intIndex;
          });
        },
      ),
    );
  }
}
