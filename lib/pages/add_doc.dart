import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyAppDoc());
}

class MyAppDoc extends StatelessWidget {
  const MyAppDoc({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FilePickerDemo(),
    );
  }
}

class FilePickerDemo extends StatefulWidget {
  const FilePickerDemo({super.key});

  @override
  _FilePickerDemoState createState() => _FilePickerDemoState();
}

class _FilePickerDemoState extends State {
  final List _selectedFiles = [
    null,
    null,
    null,
    null
  ]; // Для хранения выбранных файлов

  Future _pickFile(int index) async {
    // Получаем путь к папке загрузок
    // Этот вызов специфичен для платформы и может требовать дополнительных разрешений
    String? downloadsDir;
    try {
      downloadsDir = (await getDownloadsDirectory())?.path;
    } catch (e) {
      print("Ошибка получения пути к папке загрузок: $e");
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc'],
      initialDirectory: downloadsDir, // Устанавливаем исходную директорию
    );

    if (result != null) {
      setState(() {
        _selectedFiles[index] = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбери файл'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          final file = _selectedFiles[index];
          final Widget displayChild;

          if (file != null) {
            displayChild = Column(
              children: [
                const Expanded(
                  child: Icon(Icons.file_present, size: 48),
                ),
                Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          } else {
            displayChild = Image.asset(
              'assets/images/fotouser.png',
              width: 100,
              height: 100,
            );
          }

          return GestureDetector(
            onTap: () => _pickFile(index),
            child: SizedBox(
              height: 120.0, // Высота, чтобы вместить и название файла
              width: 100.0,
              child: displayChild,
            ),
          );
        }),
      ),
    );
  }
}
