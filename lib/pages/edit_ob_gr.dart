        import 'dart:typed_data';

import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'decimal_text_input_formatter.dart';
import 'package:path_provider/path_provider.dart';

import '../design/colors.dart';
import '../config.dart';
import 'package:crgtransp72app/api/cities_api.dart';
import 'package:crgtransp72app/widgets/async_list_placeholder.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads1.dart';
import 'ad_edit_image_multipart.dart';
import 'package:crgtransp72app/widgets/ad_edit_image_slot.dart';

// Step 1.
String dropdownValue = 'Мини погрузчики и складская техника';

class edit_ob_gr extends StatefulWidget {
  final int id;
  const edit_ob_gr({super.key, required this.id});
  @override

  // ignore: library_private_types_in_public_api

  add_ob_vidtForm createState() => add_ob_vidtForm();
}

class add_ob_vidtForm extends State<edit_ob_gr> {
  final TextEditingController _cenahaursController = TextEditingController();
  final TextEditingController _cenasmenaController = TextEditingController();
  final TextEditingController _cenakmController = TextEditingController();
  List _vidt = [];
  String? _selectedVidt;
  List _cities = [];
  bool _citiesLoading = true;
  bool _citiesFailed = false;
  String? _selectedCity;
  String strData = '';
  String city = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  bool _isLoading = true;

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchCities(),
      _fetchVidT(),
      //    _fetchGP(),
      getUserData(),
      fetchAds()
    ]); // Ждем завершения всех запросов

    setState(() {
      _isLoading = false; // Флаг готовности
    });
  }

  static const double imageSize = 80.0;
  final List _images = List.generate(4, (index) => null);
  final List _imagesDoc = List.generate(4, (indexDoc) => null); // Список для хр
  final List<XFile?> _originalImages = List.generate(4, (index) => null);
  final List<XFile?> _originalImagesDoc = List.generate(4, (indexDoc) => null);
  final List<bool> _deletedImages = List.generate(4, (_) => false);
  final List<bool> _deletedImagesDoc = List.generate(4, (_) => false);
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
        _deletedImages[index] = false;
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

  void _deleteImage(int index) {
    setState(() {
      _images[index] = null;
      _originalImages[index] = null;
      _deletedImages[index] = true;
    });
  }

  void _deleteImageDoc(int indexDoc) {
    setState(() {
      _imagesDoc[indexDoc] = null;
      _originalImagesDoc[indexDoc] = null;
      _deletedImagesDoc[indexDoc] = true;
    });
  }

  Widget _imageSlot(int index) {
    final hasPhoto = _images[index] != null ||
        (!_deletedImages[index] && _originalImages[index] != null);
    return AdEditImageSlot(
      size: imageSize,
      displayFile: _images[index],
      fallbackFile: _deletedImages[index] ? null : _originalImages[index],
      onTap: () => _pickImage(index),
      onDelete: hasPhoto ? () => _deleteImage(index) : null,
    );
  }

  Widget _imageSlotDoc(int indexDoc) {
    final hasPhoto = _imagesDoc[indexDoc] != null ||
        (!_deletedImagesDoc[indexDoc] &&
            _originalImagesDoc[indexDoc] != null);
    return AdEditImageSlot(
      size: imageSize,
      displayFile: _imagesDoc[indexDoc],
      fallbackFile:
          _deletedImagesDoc[indexDoc] ? null : _originalImagesDoc[indexDoc],
      onTap: () => _pickImageDoc(indexDoc),
      onDelete: hasPhoto ? () => _deleteImageDoc(indexDoc) : null,
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
        _imagesDoc[indexDoc] = compressedFile ?? pickedFile;
        _originalImagesDoc[indexDoc] = pickedFile;
        _deletedImagesDoc[indexDoc] = false;
      });
    }
  }

/*
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
*/
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

  Future<void> _fetchCities() async {
    final result = await CitiesApi.fetchAll();
    if (!mounted) return;
    setState(() {
      _citiesLoading = false;
      _citiesFailed = result.failed;
      if (result.data != null) {
        _cities = result.data!;
      }
    });
  }


  void uploadData() async {
    var uri = Uri.parse('https://ivnovav.ru/api/upload_ob_gr.php');

// Предполагаем, что _images и _imagesDoc - это пути к файлам на устройстве
    var request = http.MultipartRequest('POST', uri)
      ..fields['id'] = widget.id.toString()
      ..fields['city'] = _selectedCity!
      ..fields['cenahaurs'] = _cenahaursController.text
      ..fields['cenasmena'] = _cenasmenaController.text
      ..fields['cenakm'] = _cenakmController.text
      ..fields['iduser'] = userId.toString();

    await AdEditImageMultipart.appendPhotos(
      request,
      originals: _originalImages,
      deleted: _deletedImages,
      fieldPrefix: 'img',
    );
    await AdEditImageMultipart.appendPhotos(
      request,
      originals: _originalImagesDoc,
      deleted: _deletedImagesDoc,
      fieldPrefix: 'imgDoc',
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Uploaded!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const Ads1App(), //HistortScreen(pageProfile: 'Ads1App'), //Ads1App(),
        ),
      );
    } else {
      print('Failed!');
    }
  }

  Uint8List? _hexToBytes(String hex) {
    String normalized = hex.trim();
    if (normalized.startsWith('0x') || normalized.startsWith('0X')) {
      normalized = normalized.substring(2);
    }
    if (normalized.startsWith(r'\x')) {
      normalized = normalized.substring(2);
    }
    if (normalized.isEmpty || normalized.length.isOdd) return null;

    final RegExp onlyHex = RegExp(r'^[0-9a-fA-F]+$');
    if (!onlyHex.hasMatch(normalized)) return null;

    final bytes = <int>[];
    for (int i = 0; i < normalized.length; i += 2) {
      bytes.add(int.parse(normalized.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  Future<Uint8List?> _resolveImageBytes(dynamic raw) async {
    if (raw == null) return null;

    if (raw is List) {
      try {
        return Uint8List.fromList(raw.cast<int>());
      } catch (_) {}
    }

    final String value = raw.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return null;

    try {
      if (value.startsWith('http://') || value.startsWith('https://')) {
        final response = await http.get(Uri.parse(value));
        if (response.statusCode == 200) return response.bodyBytes;
        return null;
      }

      if (value.startsWith('data:')) {
        final int commaIndex = value.indexOf(',');
        if (commaIndex != -1) {
          final String dataPart = value.substring(commaIndex + 1);
          return base64Decode(dataPart);
        }
      }

      final bool looksLikeRelativeImagePath = value.contains('/') &&
          (value.endsWith('.jpg') ||
              value.endsWith('.jpeg') ||
              value.endsWith('.png') ||
              value.endsWith('.webp') ||
              value.endsWith('.heic'));
      if (looksLikeRelativeImagePath) {
        final String base = Config.baseUrl.replaceAll(RegExp(r'/$'), '');
        final String path = value.replaceFirst(RegExp(r'^/'), '');
        final response = await http.get(Uri.parse('$base/$path'));
        if (response.statusCode == 200) return response.bodyBytes;
      }

      final Uint8List? hexBytes = _hexToBytes(value);
      if (hexBytes != null && hexBytes.isNotEmpty) return hexBytes;

      String normalized = value
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .replaceAll(' ', '');
      final int mod4 = normalized.length % 4;
      if (mod4 != 0) {
        normalized = normalized.padRight(normalized.length + (4 - mod4), '=');
      }
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImageFromDB(int index, dynamic raw) async {
    if (raw == null || raw.isEmpty) return; // в БД нет картинки – выходим

    try {
      final Uint8List? bytes = await _resolveImageBytes(raw);
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
          _images[index] = compressed;
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
      final Uint8List? bytes = await _resolveImageBytes(raw);
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
      path: '/api/edit_ob_gr_u_v2.php',
      queryParameters: {
        'id': widget.id.toString(),
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
          _cenahaursController.text = ad['cenahaurs'];
          _cenasmenaController.text = ad['cenasmena'];
          _cenakmController.text = ad['cenakm'];
          for (var i = 0; i < 4; i++) {
            _images[i] = null;
            _originalImages[i] = null;
            _imagesDoc[i] = null;
            _originalImagesDoc[i] = null;
          }
          for (var i = 0; i < 4; i++) {
            // 0,1,2,3
            final key = 'img${i + 1}'; // img1,img2,img3,img4
            _pickImageFromDB(i, ad[key]); // передаём 0-й индекс
          }
          for (var x = 0; x < 4; x++) {
            // 0,1,2,3
            // Поддерживаем оба варианта ключей из API: imgDocN и imgdocN
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
    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator()); // Показываем индикатор загрузки
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактировать объявление грузчика',
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
              child: AsyncListPlaceholder(
                isLoading: _citiesLoading,
                loadFailed: _citiesFailed,
                isEmpty: _cities.isEmpty,
                onRetry: () {
                  setState(() {
                    _citiesLoading = true;
                    _citiesFailed = false;
                  });
                  _fetchCities();
                },
                child: Column(
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
                    child: const Text('Сохранить')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
