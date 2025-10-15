import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyAppI());

class MyAppI extends StatelessWidget {
  const MyAppI({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Gallery App',
      home: GalleryScreen(),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State {
  late Future<List<ImageData>> images; // Уточненный тип Future

  @override
  void initState() {
    super.initState();
    images = fetchImages();
  }

  Future<List<ImageData>> fetchImages() async {
    final response =
        await http.get(Uri.parse('http://ivnovav.ru/api/getimage.php?bd=vidt'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((image) => ImageData.fromJson(image)).toList();
    } else {
      throw Exception('Failed to load images from server');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
      ),
      body: FutureBuilder<List<ImageData>>(
        // Указываем явный тип данных здесь
        future: images,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else {
            List<ImageData> images = snapshot.data!;
            // Тело GridView.builder
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: images.length,
// В вашем GridView.builder измените itemBuilder на следующий:
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(
                      8.0), // Отступы вокруг каждого элемента
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Image.memory(
                          base64Decode(images[index].image),
                          fit: BoxFit.contain, // Изменено на BoxFit.contain
                        ),
                      ),
                      const SizedBox(
                          height:
                              8), // Добавляем пространство между картинкой и текстом
                      Align(
                        // Обертываем Text виджет в Align
                        alignment: Alignment.center, // Выравнивание по центру
                        child: Text(images[index]
                            .name), // Выводим название под картинкой
                      ),
                    ],
                  ),
                );
              },
            );

// Показываем индикатор загрузки
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class ImageData {
  final String image;
  final String name;

  ImageData({required this.image, required this.name});

  factory ImageData.fromJson(Map json) {
    return ImageData(
      image: json['image'],
      name: json['name'],
    );
  }
}
