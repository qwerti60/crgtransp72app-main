import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/performer_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ReviewScreenz extends StatefulWidget {
  final String userId;
  final bool showBottomNav;

  ReviewScreenz({required this.userId, this.showBottomNav = false});

  @override
  _ReviewScreenzState createState() => _ReviewScreenzState();
}

class _ReviewScreenzState extends State<ReviewScreenz> {
  late Future<List<Map<String, dynamic>>> futureReviews;

  @override
  void initState() {
    super.initState();
    futureReviews = fetchReviews(widget.userId);
  }

  Future<List<Map<String, dynamic>>> fetchReviews(String userId) async {
    final response = await http.get(
      Uri.parse(Config.baseUrl + '/api/review_apiz.php')
          .replace(queryParameters: {
        'userId': userId,
      }),
    );
    print('kall');
    print(userId);
    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        throw Exception('Пустой ответ от сервера');
      }
      try {
        final parsed = jsonDecode(response.body) as List;

        // Преобразуем каждый элемент списка в Map<String, dynamic>
        return Future.value(
            parsed.map((item) => item as Map<String, dynamic>).toList());
      } catch (e) {
        print('Ошибка декодирования: $e');
        print('Ответ сервера: ${response.body}');
        throw Exception('Ошибка формата ответа');
      }
    } else {
      throw Exception('Failed to load ads');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Отзывы о грузоперевозчике',
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureReviews,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var review = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Оценка: ${review['rating']}'),
                        Text('Комментарий: ${review['comment']}'),
                        Text('Дата: ${review['datastamp']}'),
                        Text(
                            'Имя пользователя: ${review['firstName']} ${review['lastName']}'),
                        Text('Город: ${review['city']}'),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки отзывов'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const PerformerBottomNav(currentIndex: 2)
          : null,
    );
  }
}
