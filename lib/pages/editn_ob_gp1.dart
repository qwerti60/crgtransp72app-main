// TODO Implement this library.
import 'dart:typed_data';

import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../design/colors.dart';
//import 'reguser1_name.dart';
import '../config.dart';
import 'package:crgtransp72app/api/reference_lists_api.dart';
import 'package:crgtransp72app/widgets/async_list_placeholder.dart';
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

import 'image_bytes_helper.dart';
import 'ad_edit_image_multipart.dart';
import 'decimal_text_input_formatter.dart';
import 'package:crgtransp72app/widgets/ad_edit_image_slot.dart';
import 'package:crgtransp72app/utils/reference_dropdown.dart';

class editn_ob_gp extends StatefulWidget {
  final int id;
  const editn_ob_gp({super.key, required this.id});

  @override

  // ignore: library_private_types_in_public_api

  _editn_ob_gpForm createState() => _editn_ob_gpForm();
}

class _editn_ob_gpForm extends State<editn_ob_gp> {
  final TextEditingController _markaController = TextEditingController();
  final TextEditingController _godvController = TextEditingController();
  final TextEditingController _maxgruzkppController = TextEditingController();
  final TextEditingController _dkuzovController = TextEditingController();
  final TextEditingController _shkuzovController = TextEditingController();
  final TextEditingController _vidkuzovController = TextEditingController();
  final TextEditingController _cenahaursController = TextEditingController();
  final TextEditingController _cenasmenaController = TextEditingController();
  final TextEditingController _cenakmController = TextEditingController();
  static const double imageSize = 80.0;
  List _vidk = [];
  bool _vidkLoading = true;
  bool _vidkFailed = false;
  String? _selectedVidkuzov;
  List _cities = [];
  bool _citiesLoading = true;
  bool _citiesFailed = false;
  String? _selectedCity;
  List _gp = [];
  bool _gpLoading = true;
  bool _gpFailed = false;
  String? _selectedGP;

  String strData = '';
  String city = '';

  final List _images = List.generate(4, (index) => null);
  final List _imagesDoc = List.generate(4, (indexDoc) => null); // Список для хр
  final List<XFile?> _originalImages = List.generate(4, (index) => null);
  final List<XFile?> _originalImagesDoc = List.generate(4, (indexDoc) => null);
  final List<bool> _deletedImages = List.generate(4, (_) => false);
  final List<bool> _deletedImagesDoc = List.generate(4, (_) => false);
  @override
  void initState() {
    super.initState();
    _fetchCities();
    _fetchVidT();
    _fetchGP();
    getUserData();
    fetchAds();
  }

  List<String> get _gpNames =>
      ReferenceDropdown.uniqueFieldValues(_gp, field: 'name');

  List<String> get _vidkNames =>
      ReferenceDropdown.uniqueFieldValues(_vidk, field: 'namevidk');

  List<String> get _cityNames =>
      ReferenceDropdown.uniqueFieldValues(_cities, field: 'name');

  void _reconcileReferenceSelections() {
    if (_selectedGP != null && _selectedGP!.isNotEmpty) {
      _selectedGP = ReferenceDropdown.resolveValue(_selectedGP, _gpNames);
    }
    if (_selectedVidkuzov != null && _selectedVidkuzov!.isNotEmpty) {
      _selectedVidkuzov =
          ReferenceDropdown.resolveValue(_selectedVidkuzov, _vidkNames);
    }
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      _selectedCity = ReferenceDropdown.resolveValue(_selectedCity, _cityNames);
    }
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

  Future<void> _fetchCities() async {
    final result = await CitiesApi.fetchAll();
    if (!mounted) return;
    setState(() {
      _citiesLoading = false;
      _citiesFailed = result.failed;
      if (result.data != null) {
        _cities = result.data!;
      }
      _reconcileReferenceSelections();
    });
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

  Future<void> _fetchVidT() async {
    final result = await ReferenceListsApi.fetch('/api/vidk.php');
    if (!mounted) return;
    setState(() {
      _vidkLoading = false;
      _vidkFailed = result.failed;
      if (result.data != null) _vidk = result.data!;
      _reconcileReferenceSelections();
    });
  }


  Future<void> _fetchGP() async {
    final result = await ReferenceListsApi.fetch('/api/get_vidgr.php');
    if (!mounted) return;
    setState(() {
      _gpLoading = false;
      _gpFailed = result.failed;
      if (result.data != null) _gp = result.data!;
      _reconcileReferenceSelections();
    });
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
  void uploadData() async {
    var uri = Uri.parse('${Config.baseUrl}/api/update_ob_gp_u.php');

// Предполагаем, что _images и _imagesDoc - это пути к файлам на устройстве
    var request = http.MultipartRequest('POST', uri)
      //..fields['idusers'] = userId
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
      ..fields['iduser'] = userId.toString()
      ..fields['id'] = widget.id.toString();

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

// Пример добавления imgdoc1
// Повторите для imgdoc2, imgdoc3, imgdoc4
    /*  if (_imagesDoc[0] != null) {
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
*/
    var response = await request.send();

    if (response.statusCode == 200) {
      print('Uploaded!');
      if (context.mounted) {
        Navigator.pop(context, true);
      }
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
      path: '/api/edit_ob_gp_u.php',
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

          _selectedCity = ad['city']?.toString();
          _cenahaursController.text = ad['cenahaurs'];
          _cenasmenaController.text = ad['cenasmena'];
          _cenakmController.text = ad['cenakm'];
          _markaController.text = ad['marka'];
          _godvController.text = ad['godv']?.toString() ?? '';
          _selectedGP = ad['maxgruz']?.toString() ?? '';
          _dkuzovController.text = ad['dkuzov']?.toString() ?? '';
          _shkuzovController.text = ad['shkuzov']?.toString() ?? '';
          _selectedVidkuzov = ad['vidk']?.toString();
          _reconcileReferenceSelections();
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
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue;
                            });
                          },
                          items: ReferenceDropdown.menuItems(
                            _cityNames,
                            currentValue: _selectedCity,
                            style: ReferenceDropdown.defaultItemStyle,
                          ),
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
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              child: AsyncListPlaceholder(
                isLoading: _gpLoading,
                loadFailed: _gpFailed,
                isEmpty: _gp.isEmpty,
                onRetry: _fetchGP,
                child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          isExpanded: true,
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
                          items: ReferenceDropdown.menuItems(
                            _gpNames,
                            currentValue: _selectedGP,
                            style: ReferenceDropdown.defaultItemStyle,
                          ),
                        ),
                      ],
                    ),
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
              child: AsyncListPlaceholder(
                isLoading: _vidkLoading,
                loadFailed: _vidkFailed,
                isEmpty: _vidk.isEmpty,
                onRetry: _fetchVidT,
                child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          isExpanded: true,
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
                          items: ReferenceDropdown.menuItems(
                            _vidkNames,
                            currentValue: _selectedVidkuzov,
                            style: ReferenceDropdown.defaultItemStyle,
                          ),
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
                'Загрузить документы(Фото паспорта водителя, стс машины и стс прицепа)',
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
            /*   Container(
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
