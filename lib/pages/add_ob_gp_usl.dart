// TODO Implement this library.
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';

import '../design/colors.dart';
//import 'reguser1_name.dart';
import '../config.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'ads2.dart';

class add_ob_gp_usl extends StatefulWidget {
  const add_ob_gp_usl({super.key});

  @override

  // ignore: library_private_types_in_public_api

  _add_ob_gpForm createState() => _add_ob_gpForm();
}

class _add_ob_gpForm extends State<add_ob_gp_usl> {
  final TextEditingController _cenakmController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  static const double imageSize = 100.0;
  List _vidk = [];
  String? _selectedVidkuzov;
  List _cities = [];
  String? _selectedCity;
  final List _cities1 = [];
  String? _selectedCity1;
  List _gp = [];
  String? _selectedGP;
  String? selectedValue;
  String strData = '';
  String city = '';
  final List _zp = [];
  final List _tp = [];
  String? _dropdownValueTypePer =
      'Не знаю'; // Убедитесь, что это значение совпадает с одним из элементов в items
  String? _dropdownValueZagr = 'Не знаю';
  final String _dropdownValueGruzch = 'Без грузчиков';
  final List _images = List.generate(4, (index) => null);
  final List _imagesDoc = [null, null, null, null]; // Список для хр
  final List<XFile?> _originalImages = List.generate(4, (index) => null);
  List<String> dropdownOptions = [
    'Не знаю',
    'Полная загрузка',
    'Частичная загрузка(догруз)',
    'Негабаритная(большегруз)'
  ];
  final List<String> dropdownItems = [
    'Не знаю',
    'Верхняя',
    'Задняя',
    'Боковая',
    'С гидробортом',
    'С полной растентовкой',
    'С аппарелями/сходнями',
    'С обрешоткой',
    'С кониками',
    'С пневмоподвеской',
  ];
  @override
  void initState() {
    super.initState();
    _fetchCities();
    _fetchVidT();
    _fetchGP();
    getUserData();
  }

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

  Future _fetchVidT() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/vidk.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _vidk = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load');
    }
  }

  Future _fetchGP() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/get_vidgr.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _gp = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
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

  void uploadData() async {
    var uri = Uri.parse('${Config.baseUrl}/api/add_gruz_info.php');

// Предполагаем, что _images и _imagesDoc - это пути к файлам на устройстве
    var request = http.MultipartRequest('POST', uri)
      //..fields['idusers'] = userId
      ..fields['maxgruz'] = _selectedGP!
      ..fields['city'] = _selectedCity!
      ..fields['startdate'] = _startDate.toString()
      ..fields['enddate'] = _endDate.toString()
      ..fields['city1'] = _selectedCity1!
      ..fields['vidk'] = _selectedVidkuzov!
      ..fields['zagr'] = _dropdownValueZagr!
      ..fields['typeper'] = _dropdownValueTypePer!
      ..fields['cena'] = _cenakmController.text
      ..fields['about'] = _aboutController.text
      ..fields['enddatez'] = selectedDatez.toString()
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

    print(_dropdownValueGruzch);
    print(selectedDatez);
    print(_selectedCity);
    print(_selectedCity);
    var response = await request.send();

    if (response.statusCode == 200) {
      print('Uploaded!');
      print('Uploaded!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Ads2App(),
        ),
      );
    } else {
      print('Failed!');
    }
  }

  String? _selectedOption = 'Как можно быстрее';
  DateTime? _startDate;
  DateTime? _endDatez;
  DateTime? _endDate;

// Форматируем дату для отображения
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _selectDate(BuildContext context, {bool isStart = true}) async {
    final now = DateTime.now(); // Текущая дата

    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate ?? now : _endDate ?? _startDate,
      firstDate: isStart
          ? now
          : _startDate ??
              now, // Если начальная дата есть, начинаем отсчёт с неё
      lastDate: isStart
          ? (_endDate ?? DateTime(2100))
          : DateTime(
              2100), // Лимитируем начальную дату конечной, если она задана
    );

    if (picked != null || (!isStart && _endDate != null)) {
      if (isStart) {
        setState(() {
          _startDate = picked;
        });
      } else {
        setState(() {
          _endDate = picked;
        });
      }
    }
  }

  DateTime selectedDatez = DateTime.now();

  Future<void> _selectDatez(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDatez,
        firstDate: DateTime(2025),
        lastDate: DateTime(2100));
    if (picked != null && picked != selectedDatez) {
      setState(() {
        selectedDatez = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Добавить заказ',
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
                          isExpanded: true,
                          underline: const SizedBox(),
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
                'Откуда забрать',
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
                          isExpanded: true,
                          underline: const SizedBox(),
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
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Дата погрузки',
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
                color:
                    grayprprColor, // Ensure you define 'grayprprColor' color variable somewhere in your code
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton(
                    hint: Text(
                      _selectedOption ?? 'Выберите опцию',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black38,
                        fontSize: 16.0,
                      ),
                    ),
                    dropdownColor: grayprprColor,
                    value: _selectedOption,
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedOption = newValue;
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'Как можно быстрее',
                        child: Text(
                          'Как можно быстрее',
                          style: TextStyle(
                            // Добавляем стиль тексту
                            fontSize: 16.0,
                            color: Colors.black38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                          value: 'В период с... по...',
                          child: Text(
                            'В период с... по...',
                            style: TextStyle(
                              // Добавляем стиль тексту
                              fontSize: 16.0,
                              color: Colors.black38,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                      DropdownMenuItem(
                          value: 'Не позднее чем',
                          child: Text(
                            'Не позднее чем',
                            style: TextStyle(
                              // Добавляем стиль тексту
                              fontSize: 16.0,
                              color: Colors.black38,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ],
                  ),
                  if (_selectedOption == 'В период с... по...')
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                                _startDate == null
                                    ? 'Выберите начальную дату'
                                    : 'Начало: ${_dateFormat.format(_startDate!)}',
                                style: const TextStyle(color: Colors.black38)),
                            onTap: () => _selectDate(context, isStart: true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                                _endDate == null
                                    ? 'Выберите конечную дату'
                                    : 'Конец: ${_dateFormat.format(_endDate!)}',
                                style: const TextStyle(color: Colors.black38)),
                            onTap: () => _selectDate(context, isStart: false),
                          ),
                        ),
                      ],
                    ),
                  if (_selectedOption == 'Не позднее чем')
                    ListTile(
                      title: Text(
                          _endDate == null
                              ? 'Выберите дату'
                              : 'Не позднее: ${_dateFormat.format(_endDate!)}',
                          style: const TextStyle(color: Colors.black38)),
                      onTap: () => _selectDate(context, isStart: false),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Куда доставить',
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
                          value: _selectedCity1,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity1 = newValue;
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
                            'Не знаю',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedVidkuzov,
                          isExpanded: true,
                          underline: const SizedBox(),
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
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Тип перевозки',
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
              child: DropdownButton<String>(
                hint: const Text("Не знаю"),
                value: _dropdownValueTypePer,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  setState(() {
                    _dropdownValueTypePer = newValue;
                  });
                },
                items: dropdownOptions
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                // Отключение подчеркивания по умолчанию

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                dropdownColor: grayprprColor,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Тип загрузки',
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
              child: DropdownButton<String>(
                hint: const Text("Не знаю"),
                value: _dropdownValueZagr,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  setState(() {
                    _dropdownValueZagr = newValue;
                  });
                },
                items:
                    dropdownItems.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                dropdownColor: grayprprColor,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Бюджет до',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              // padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                'Подробнее о заказе',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: Colors.black38,
                  width: 2,
                ),
                color: grayprprColor, // Используйте вашу переменную цвета здесь
              ),
              child: TextField(
                controller: _aboutController,
                keyboardType:
                    TextInputType.multiline, // Делаем поле многострочным
                maxLines: null, // Без ограничения на количество строк
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
                  border: InputBorder.none, // Убираем внутреннюю рамку
                  // Добавьте другие настройки декорации здесь, если это необходимо
                ),
                // Добавьте другие настройки TextField здесь, если это необходимо
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Прием заявок до',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              child: ListTile(
                title: Text(
                    selectedDatez == null
                        ? 'Выберите дату'
                        : 'Прием заявок до: ${_dateFormat.format(selectedDatez)}',
                    style: const TextStyle(color: Colors.black38)),
                onTap: () => _selectDatez(context),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Загрузить фото груза',
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
                      String about = _aboutController.text;
                      String cena = _cenakmController.text;
                      String vidk = _selectedVidkuzov!;
                      String zagr = _dropdownValueZagr!;
                      if (about.isEmpty) {
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
                    child: const Text('Отправить заказ')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
