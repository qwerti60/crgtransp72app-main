import 'dart:typed_data';

import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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

import 'ads1.dart';
import 'image_bytes_helper.dart';
import 'decimal_text_input_formatter.dart';

// Step 1.
String dropdownValue = 'Мини погрузчики и складская техника';

class edit_ob_vidt extends StatefulWidget {
  final int id;
  const edit_ob_vidt({super.key, required this.id});
  @override

  // ignore: library_private_types_in_public_api

  edit_ob_vidtForm createState() => edit_ob_vidtForm();
}

class edit_ob_vidtForm extends State<edit_ob_vidt> {
  final TextEditingController _cenahaursController = TextEditingController();
  final TextEditingController _cenasmenaController = TextEditingController();
  final TextEditingController _cenakmController = TextEditingController();
  List _vidt = [];
  String? _selectedVidt;
  List _cities = [];
  String? _selectedCity;
  String strData = '';
  String city = '';
  @override
  void initState() {
    super.initState();
    _fetchCities();
    _fetchVidT();
    getUserData();
    fetchAds();
  }

  static const double imageSize = 80.0;
  final List _images = List.generate(4, (index) => null);
  final List _imagesDoc = List.generate(4, (indexDoc) => null); // Список для хр
  final List<XFile?> _originalImages = List.generate(4, (index) => null);
  final List<XFile?> _originalImagesDoc = List.generate(4, (indexDoc) => null);
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

  Future _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();

// Показываем диалоговое окно для выбора источника изображения
    final ImageSource? source = await _showImageSourceDialog(context);

// Если пользователь не выбрал источник, выходим из функции
    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
// Генерируем новое имя файла для сжатого изображения
      final String dir = p.dirname(pickedFile.path);
      final String newPath = p.join(
        dir,
        '${p.basenameWithoutExtension(pickedFile.path)}_compressed.jpg',
      );
      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        newPath, // Использовать новый путь для сжатого файла
        minWidth: 100,
        minHeight: 100,
        quality: 88,
        format: CompressFormat.jpeg,
      );

      setState(() {
        _images[index] = compressedFile ?? pickedFile;
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

  Widget _imageSlotDoc(int indexDoc) {
    return GestureDetector(
      onTap: () => _pickImageDoc(indexDoc),
      child: Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: _imagesDoc[indexDoc] != null
                ? FileImage(File(_imagesDoc[indexDoc]!
                    .path)) // Преобразуем XFile из _images в File
                : _originalImagesDoc[indexDoc] != null
                    ? FileImage(File(_originalImagesDoc[indexDoc]!
                        .path)) // Преобразуем XFile из _originalImages в File
                    : const AssetImage('assets/images/fotouser.png')
                        as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Future _fetchVidT() async {
    final response = await http
        .get(Uri.parse(Config.baseUrl).replace(path: '/api/vidt.php'));
    //    Uri.parse(Config.baseUrl).replace(path: 'regtest.php'),

    if (response.statusCode == 200) {
      setState(() {
        _vidt = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
  }

  Future _pickImageDoc(int indexDoc) async {
    final ImagePicker picker = ImagePicker();

// Показываем диалоговое окно для выбора источника изображения
    final ImageSource? source = await _showImageSourceDialog(context);

// Если пользователь не выбрал источник, выходим из функции
    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
// Генерируем новое имя файла для сжатого изображения
      final String dir = p.dirname(pickedFile.path);
      final String newPath = p.join(
        dir,
        '${p.basenameWithoutExtension(pickedFile.path)}_compressed.jpg',
      );
      XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        pickedFile.path,
        newPath, // Использовать новый путь для сжатого файла
        minWidth: 100,
        minHeight: 100,
        quality: 88,
        format: CompressFormat.jpeg,
      );

      setState(() {
        //     _images[index] = compressedFile;
        //   _originalImages[index] = pickedFile;
        _imagesDoc[indexDoc] = compressedFile ?? pickedFile;
        _originalImagesDoc[indexDoc] = pickedFile;
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

  void uploadData() async {
    var uri = Uri.parse('http://ivnovav.ru/api/update_ob_vidt.php');

// Предполагаем, что _images и _imagesDoc - это пути к файлам на устройстве
    var request = http.MultipartRequest('POST', uri)
      ..fields['id'] = widget.id.toString()
      ..fields['city'] = _selectedCity!
      ..fields['vidt'] = _selectedVidt!
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
    for (int i1 = 0; i1 < _originalImagesDoc.length; i1++) {
      if (_originalImagesDoc[i1] != null) {
        // Получаем путь из объекта XFile
        //FileImage(File(_originalImages[i]!.path));
        String filePath =
            _originalImagesDoc[i1]!.path; // Используем _originalImages здесь

        request.files.add(
            await http.MultipartFile.fromPath('imgDoc${i1 + 1}', filePath));
      }
    }
    var response = await request.send();

    if (response.statusCode == 200) {
      print('Uploaded!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const //HistortScreen(pageProfile: 'Ads1App'),
              Ads1App(),
        ),
      );
    } else {
      print('Failed!');
    }
  }

  Future<void> _pickImageFromDB(int index, dynamic raw) async {
    if (raw == null || raw.isEmpty) return; // в БД нет картинки – выходим

    try {
      // 2.1. Получаем байты
      // Если сервер отдаёт URL – скачайте его через http.get().
      // Ниже пример, когда приходит Base64:
      final Uint8List? bytes = await resolveImageBytes(raw);
      if (bytes == null || bytes.isEmpty) return;

      // 2.2. Пишем во временный файл
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/db_img_${index}_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final file = await File(filePath).writeAsBytes(bytes);

      final XFile xfile = XFile(file.path); // оборачиваем во «файлик»

      // 2.3. Сжимаем (ваш старый код)
      final newPath = p.join(
        p.dirname(xfile.path),
        '${p.basenameWithoutExtension(xfile.path)}_compressed${p.extension(xfile.path)}',
      );

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        xfile.path,
        newPath,
        minWidth: 100,
        minHeight: 100,
        quality: 88,
      format: CompressFormat.jpeg,
      );

      // 2.4. Кладём в стейт, чтобы виджеты перерисовались
      if (mounted) {
        setState(() {
          _images[index] = compressed ?? xfile;
          _originalImages[index] = xfile;
        });
      }
    } catch (e, s) {
      debugPrint('Не удалось обработать картинку из БД: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<void> _pickImageFromDBdoc(int indexDoc, dynamic raw) async {
    if (raw == null || raw.isEmpty) return; // в БД нет картинки – выходим

    try {
      // 2.1. Получаем байты
      // Если сервер отдаёт URL – скачайте его через http.get().
      // Ниже пример, когда приходит Base64:
      final Uint8List? bytes = await resolveImageBytes(raw);
      if (bytes == null || bytes.isEmpty) return;

      // 2.2. Пишем во временный файл
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/db_img_${indexDoc}_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final file = await File(filePath).writeAsBytes(bytes);

      final XFile xfile = XFile(file.path); // оборачиваем во «файлик»

      // 2.3. Сжимаем (ваш старый код)
      final newPath = p.join(
        p.dirname(xfile.path),
        '${p.basenameWithoutExtension(xfile.path)}_compressed${p.extension(xfile.path)}',
      );

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        xfile.path,
        newPath,
        minWidth: 100,
        minHeight: 100,
        quality: 88,
      format: CompressFormat.jpeg,
      );

      // 2.4. Кладём в стейт, чтобы виджеты перерисовались
      if (mounted) {
        setState(() {
          _imagesDoc[indexDoc] = compressed ?? xfile;
          _originalImagesDoc[indexDoc] = xfile;
        });
      }
    } catch (e, s) {
      debugPrint('Не удалось обработать картинку из БД: $e');
      debugPrintStack(stackTrace: s);
    }
  }

  Future<List<Map<String, dynamic>>> fetchAds() async {
    // формируем uri
    final uri = Uri.parse(Config.baseUrl).replace(
      path: '/api/edit_ob_vidt_u.php',
      queryParameters: {
        'idusers': widget.id.toString(),
      },
    );

    final response = await http.get(uri);

    // проверяем статус
    if (response.statusCode != 200) {
      throw Exception('Failed to load ads (code ${response.statusCode})');
    }

    if (response.body.isEmpty) {
      throw Exception('Пустой ответ от сервера');
    }

    try {
      // декодируем ответ ‑ получим список
      final List<dynamic> jsonList = jsonDecode(response.body);

      // приводим к нужному типу
      final List<Map<String, dynamic>> ads =
          jsonList.cast<Map<String, dynamic>>();

      // если нужен только первый элемент
      if (ads.isNotEmpty) {
        final ad = ads.first;

        setState(() {
//          _selectedVidt = ad['vidt'];

          _selectedCity = ad['city'];
          _selectedVidt = ad['vidt'];
          _cenahaursController.text = ad['cenahaurs'];
          _cenasmenaController.text = ad['cenasmena'];
          _cenakmController.text = ad['cenakm'];
          /*
     ..fields['city'] = _selectedCity!
      ..fields['vidt'] = _selectedVidt!
      ..fields['cenahaurs'] = _cenahaursController.text
      ..fields['cenasmena'] = _cenasmenaController.text
      ..fields['cenakm'] = _cenakmController.text
      ..fields['iduser'] = userId.toString();
//
 */
          for (var i = 0; i < 4; i++) {
            // 0,1,2,3
            final key = 'img${i + 1}'; // img1,img2,img3,img4
            _pickImageFromDB(i, ad[key]); // передаём 0-й индекс
          }
          for (var x = 0; x < 4; x++) {
            // 0,1,2,3
            final keydocCamel = 'imgDoc${x + 1}';
            final keydocLower = 'imgdoc${x + 1}';
            _pickImageFromDBdoc(
              x,
              ad[keydocCamel] ?? ad[keydocLower],
            ); // передаём 0-й индекс
          }

          print('xxxz');
          //         print(selectedDatez);
          //       print(_endDate);
          print(_selectedCity);
          print(ad);
        });
      }

      return ads; // возвращаем список объявлений
    } catch (e, s) {
      debugPrint('Ошибка обработки ответа: $e');
      debugPrintStack(stackTrace: s);
      throw Exception('Ошибка формата ответа');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактировать объявление',
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
                          isExpanded: true,
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
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Вид спецтехники',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black38,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 10.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.black38, width: 2),
                color: grayprprColor,
              ),
// Step 2.
              child: _vidt.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          isExpanded: true,
                          hint: const Text(
                            'Выберите вид спецтехники',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black38,
                              fontSize: 16.0,
                            ),
                          ),
                          dropdownColor: grayprprColor,
                          value: _selectedVidt,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedVidt = newValue;
                            });
                          },
                          items: _vidt
                              .map<DropdownMenuItem<String>>((dynamic vidt) {
                            return DropdownMenuItem(
                              value: vidt['name'],
                              child: Text(
                                vidt['name'],
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalTextInputFormatter()],
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalTextInputFormatter()],
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
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalTextInputFormatter()],
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
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(4, (index) => _imageSlot(index)),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              margin: const EdgeInsets.only(top: 15.0),
              child: const Text(
                'Загрузить документы(фото паспорта водителя, стс машины и стс прицепа)',
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
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      List.generate(4, (indexDoc) => _imageSlotDoc(indexDoc)),
                ),
              ),
            ),
            /*
            Container(
              padding: const EdgeInsets.all(
                  10), // Добавляет внутренний отступ к контейнеру
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
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
            */
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
