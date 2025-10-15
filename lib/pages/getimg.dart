import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp6());
}

class MyApp6 extends StatelessWidget {
  const MyApp6({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImagePickerDemo(),
    );
  }
}

class ImagePickerDemo extends StatefulWidget {
  const ImagePickerDemo({super.key});

  @override
  _ImagePickerDemoState createState() => _ImagePickerDemoState();
}

class _ImagePickerDemoState extends State {
  static const double imageSize = 100.0;
  final List _images = List.generate(4, (index) => null);
  final List<XFile?> _originalImages = List.generate(4, (index) => null);

  Future _pickImage(int index) async {
    final ImagePicker picker = ImagePicker();

// Показываем диалоговое окно для выбора источника изображения
    final ImageSource? source = await _showImageSourceDialog(context);

// Если пользователь не выбрал источник, выходим из функции
    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(source: source);
    _originalImages[index] = pickedFile;
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
      onLongPress: () {
        // Убедитесь, что оригинальное изображение существует, прежде чем продолжать
        if (_originalImages[index] != null) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: Image.file(File(_originalImages[index]!
                  .path)), // Показываем оригинальное изображение
            ),
          );
        }
      },
      child: Container(
        height: imageSize,
        width: imageSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: _images[index] != null
                ? FileImage(File(_images[index]!.path))
                : const AssetImage('assets/images/fotouser.png')
                    as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Picker Demo')),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) => _imageSlot(index)),
        ),
      ),
    );
  }
}
