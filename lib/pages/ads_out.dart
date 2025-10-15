import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'package:flutter/material.dart';

Future<List> fetchAds() async {
  final response = await http
      .get(Uri.parse(Config.baseUrl).replace(path: '/api/get_ads.php'));
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    // Проверяем, не пустой ли ответ
    if (response.body.isEmpty) {
      // Обработка ситуации с пустым телом ответа
      throw Exception('Пустой ответ от сервера');
    }
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load ads');
  }
}

class AdWidget extends StatelessWidget {
  final ad;
  const AdWidget({super.key, this.ad});

  @override
  Widget build(BuildContext context) {
    // Используйте ad['column_name'] для получения данных из вашего объявления
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Здесь может быть ваш слайдер изображений
          Expanded(
            child: Text(
                "Наименование: ${ad['name']}"), // Пример использования данных
          ),
          // ... Добавьте другие поля
        ],
      ),
    );
  }
}

class AdsPage extends StatefulWidget {
  const AdsPage({super.key});

  @override
  _AdsPageState createState() => _AdsPageState();
}

class _AdsPageState extends State<AdsPage> {
  List _ads = [];

  @override
  void initState() {
    super.initState();
    fetchAds().then((data) {
      setState(() {
        _ads = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Объявления'),
      ),
      body: ListView.builder(
          itemCount: _ads.length,
          itemBuilder: (context, index) {
            return AdWidget(ad: _ads[index]);
          }),
    );
  }
}
