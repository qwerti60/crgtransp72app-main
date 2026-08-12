import 'dart:convert';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdTemplatePickerScreen extends StatefulWidget {
  const AdTemplatePickerScreen({super.key});

  @override
  State<AdTemplatePickerScreen> createState() => _AdTemplatePickerScreenState();
}

class _AdTemplatePickerScreenState extends State<AdTemplatePickerScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await getSecurefcm_token();
      final uri = Uri.parse('${Config.apiBase}/get_customer_ad_templates.php')
          .replace(queryParameters: {'token': token ?? '', 'limit': '20'});
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (data['success'] == true && data['templates'] is List) {
        setState(() {
          _items = (data['templates'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'Не удалось загрузить шаблоны';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Ошибка: $e';
        _loading = false;
      });
    }
  }

  Future<void> _duplicate(Map<String, dynamic> item) async {
    try {
      final token = await getSecurefcm_token();
      final resp = await http.post(
        Uri.parse('${Config.apiBase}/duplicate_customer_ad.php'),
        body: {
          'token': token ?? '',
          'bd': (item['bd'] ?? 0).toString(),
          'source_id': (item['id'] ?? 0).toString(),
        },
      );
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (!mounted) return;
      if (data['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']?.toString() ?? 'Заявка создана')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error']?.toString() ?? 'Ошибка')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать как прошлую'),
        backgroundColor: blueaccentColor,
        foregroundColor: whiteprColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Пока нет прошлых заявок. Создайте первую вручную.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          title: Text(item['title']?.toString() ?? 'Заявка'),
                          subtitle: Text(
                            '${item['city'] ?? ''} · ${item['created_at'] ?? ''}',
                          ),
                          trailing: const Icon(Icons.copy),
                          onTap: () => _duplicate(item),
                        );
                      },
                    ),
    );
  }
}
