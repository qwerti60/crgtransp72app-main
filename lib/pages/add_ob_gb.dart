import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../config.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Step 1.
String dropdownValue = 'Мини погрузчики и складская техника';

class add_ob_gp extends StatefulWidget {
  const add_ob_gp({super.key});
  @override

  // ignore: library_private_types_in_public_api

  add_ob_vidtForm createState() => add_ob_vidtForm();
}

class add_ob_vidtForm extends State<add_ob_gp> {
  final TextEditingController _markaController = TextEditingController();
  final TextEditingController _godvController = TextEditingController();
  final TextEditingController _maxgruzkppController = TextEditingController();
  final TextEditingController _dkuzovController = TextEditingController();
  final TextEditingController _shkuzovController = TextEditingController();
  final TextEditingController _vidkuzovController = TextEditingController();
  final TextEditingController _cenahaursController = TextEditingController();
  final TextEditingController _cenasmenaController = TextEditingController();
  final TextEditingController _cenakmController = TextEditingController();
  static const double imageSize = 100.0;
  final List _vidk = [];
  String? _selectedVidkuzov;
  List _cities = [];
  String? _selectedCity;
  final List _gp = [];
  String? _selectedGP;

  String strData = '';
  String city = '';

  @override
  void initState() {
    super.initState();
    _fetchCities();
//    _fetchVidT();
    getUserData();
  }

  final List _images = List.generate(4, (index) => null);
  final List _imagesDoc = [null, null, null, null]; // Список для хр
  final List<XFile?> _originalImages = List.generate(4, (index) => null);
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String city1 = '';
  String phone = '';
  String email = '';
  int userId = 0;
  Future<void> getUserData() async {
    final token = await getSecurefcm_token(); // Await the secure token
    if (token == null) {
      print("Token is null");
      return;
    }
    final encodedToken = Uri.encodeComponent(
        token); // Экранирование потенциально опасных символов
    final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/getuserinfo.php?token=$encodedToken'));

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
          city1 = data['city'];
          phone = data['phone'];
          email = data['email'];
        });
        print('вывод id: $userId');
        // Теперь переменные firstName, lastName, middleName доступны для использования в build() методе
      }
    } else {
      print('Ошибка при получении данных пользователя');
    }
  }

  Future _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();

// Показываем диалоговое окно для выбора источника изображения
    final ImageSource? source = await _showImageSourceDialog(context);

// Если пользователь не выбрал источник, выходим из функции
    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
// Генерируем новое имя файла для сжатого изображения
      String dir = p.dirname(pickedFile.path);
      String extension = p.extension(pickedFile.path);
      String newFileName =
          '${p.basenameWithoutExtension(pickedFile.path)}_compressed$extension';
      String newPath = p.join(dir, newFileName);
      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        newPath, // Использовать новый путь для сжатого файла
        minWidth: 100,
        minHeight: 100,
        quality: 88,
      );

      setState(() {
        _images[index] = compressedFile;
        _originalImages[index] = pickedFile;
      });
    }
  }

  Future _showImageSourceDialog(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Выберите источник изображения'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ImageSource.camera),
                  child: const Text('Камера'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, ImageSource.gallery),
                  child: const Text('Галерея'),
                ),
              ],
            ));
  }

  Widget _imageSlot(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: _images[index] != null
                ? FileImage(File(_images[index]!
                    .path)) // Преобразуем XFile из _images в File
                : _originalImages[index] != null
                    ? FileImage(File(_originalImages[index]!
                        .path)) // Преобразуем XFile из _originalImages в File
                    : const AssetImage('assets/images/fotouser.png')
                        as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Future _pickImageDoc(int index) async {
    final picker = ImagePicker();
// Можно указать типы файлов, добавив параметры в pickImage
    final XFile? image = await picker.pickImage(
        source:
            ImageSource.gallery); // Или pickMultiImage для нескольких файлов
    if (image != null) {
      setState(() {
        _imagesDoc[index] = image;
      });
    }
  }

  Future<void> pickFile(int index) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      // В результате вы получите платформенно-независимый путь к файлу
      PlatformFile file = result.files.first;

      setState(() {
        // Предполагается, что у вас есть переменная _imagesDoc,
        // где вы храните ссылки на выбранные файлы. Может потребоваться изменить тип хранения
        // с Image на более подходящий для файлов в общем, например, String или PlatformFile
        _imagesDoc[index] = file;
      });
    }
  }

  Future _fetchCities() async {
    final response =
        await http.get(Uri.parse('${Config.baseUrl}/api/cities.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _cities = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
  }

  void uploadData() async {
    var uri = Uri.parse('${Config.baseUrl}/api/add_ob_gp.php');

// Предполагаем, что _images и _imagesDoc - это пути к файлам на устройстве
    var request = http.MultipartRequest('POST', uri)
      ..fields['city'] = _selectedCity!
      ..fields['marka'] = _markaController.text
      ..fields['godv'] = _godvController.text
      ..fields['maxgruz'] = _selectedGP!
      ..fields['dkuzov'] = _dkuzovController.text
      ..fields['shkuzov'] = _shkuzovController.text
      ..fields['vidk'] = _selectedVidkuzov!
      ..fields['cenahaurs'] = _cenahaursController.text
      ..fields['cenasmena'] = _cenasmenaController.text
      ..fields['cenakm'] = _cenakmController.text
      ..fields['iduser'] = userId.toString();

// Предполагаем, что _originalImages - это List<XFile>, такой же как и _images
    for (int i = 0; i < _originalImages.length; i++) {
      if (_originalImages[i] != null) {
        // Получаем путь из объекта XFile
        //FileImage(File(_originalImages[i]!.path));
        String filePath =
            _originalImages[i]!.path; // Используем _originalImages здесь

        request.files
            .add(await http.MultipartFile.fromPath('img${i + 1}', filePath));
      }
    }

// Пример добавления imgdoc1
// Повторите для imgdoc2, imgdoc3, imgdoc4
    if (_imagesDoc[0] != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'imgdoc1',
        _imagesDoc[0].path, // Извлекаем строку пути из объекта XFile
      ));
    }

    if (_imagesDoc[1] != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'imgdoc2',
        _imagesDoc[1].path, // Извлекаем строку пути из объекта XFile
      ));
    }
    if (_imagesDoc[2] != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'imgdoc3',
        _imagesDoc[2].path, // Извлекаем строку пути из объекта XFile
      ));
    }
    if (_imagesDoc[3] != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'imgdoc4',
        _imagesDoc[3].path, // Извлекаем строку пути из объекта XFile
      ));
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Uploaded!');
    } else {
      print('Failed!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Добавить объявление',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: _cities.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите город(населенный пункт',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedCity,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                            });
                          },
                          items: _cities
                              .map<DropdownMenuItem<String>>((dynamic city) {
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
                        ),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Марка',
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
                controller: _markaController,
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
                  hintText: 'Mercedes',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Год выпуска',
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
                controller: _godvController,
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
                  hintText: '2011',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Грузоподъемность',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: _gp.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите грузоподьемность',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedGP,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGP = newValue;
                            });
                          },
                          items:
                              _gp.map<DropdownMenuItem<String>>((dynamic gp) {
                            return DropdownMenuItem(
                              value: gp['name'],
                              child: Text(
                                gp['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black38,
                                  fontSize: 16.0,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Длинна кузова',
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
                controller: _dkuzovController,
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
                  hintText: '14',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Ширина кузова',
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
                controller: _shkuzovController,
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
                  hintText: '3',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Вид кузова',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
              child: _vidk.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          hint: const Text(
                            'Выберите вид кузова',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedVidkuzov,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedVidkuzov = newValue;
                            });
                          },
                          items: _vidk
                              .map<DropdownMenuItem<String>>((dynamic vidk1) {
                            return DropdownMenuItem(
                              value: vidk1['namevidk'],
                              child: Text(
                                vidk1['namevidk'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black38,
                                  fontSize: 16.0,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 5.0),
              child: const Text(
                'Час',
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
                controller: _cenahaursController,
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
                  hintText: '1000',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Смена',
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
                controller: _cenasmenaController,
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
                  hintText: '10 000',
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'За км',
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
                controller: _cenakmController,
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
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Загрузить фото',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(4, (index) => _imageSlot(index)),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Загрузить документы(Паспорт водителя, стс машины и стс прицепа)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(
                  10), // Добавляет внутренний отступ к контейнеру
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    // Ваш контейнер с изображением или иконкой
                    return GestureDetector(
                      onTap: () => pickFile(index),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _imagesDoc[index] != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.file_present,
                                      size: 48), // Иконка файла
                                  Text(
                                    _imagesDoc[index]!
                                        .name
                                        .split('/')
                                        .last, // Название файла
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              )
                            : Image.asset(
                                'assets/images/fotouser.png'), // Стандартное изображение
                      ),
                    );
                  }),
                ),
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
                      foregroundColor: whiteprColor,
                      backgroundColor: blueaccentColor,
                      disabledForegroundColor: grayprprColor,
                      shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(3))),
                    ),
                    onPressed: () async {
                      String cenahaurs = _cenahaursController.text;
                      String cenasmena = _cenasmenaController.text;
                      String cenakm = _cenakmController.text;

                      if (cenahaurs.isEmpty || cenasmena.isEmpty) {
// Если хотя бы одно поле пустое, показываем осведомительное сообщение
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Пожалуйста, заполните все поля.'),
                          ),
                        );
                        return;
                      }

                      uploadData();
                    },
                    child: const Text('Продолжить')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
