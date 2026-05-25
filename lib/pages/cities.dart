import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';
import 'package:crgtransp72app/api/cities_api.dart';
import 'package:crgtransp72app/widgets/async_list_placeholder.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPage createState() => _RegisterPage();
}

class _RegisterPage extends State {
  List _cities = [];
  bool _citiesLoading = true;
  bool _citiesFailed = false;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchCities();
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


/*
  Future _fetchCities() async {
    final response =
        await http.get(Uri.parse(Config.baseUrl).replace(path: 'cities.php'));

    if (response.statusCode == 200) {
      setState(() {
        _cities = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load cities');
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a City'),
      ),
      body: AsyncListPlaceholder(
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
                  hint: const Text('Select city'),
                  value: _selectedCity,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCity = newValue;
                    });
                  },
                  items: _cities.map<DropdownMenuItem<String>>((dynamic city) {
                    return DropdownMenuItem(
                      value: city['name'],
                      child: Text(city['name']),
                    );
                  }).toList(),
                ),
                ElevatedButton(
                  onPressed: _selectedCity == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    NextScreen(city: _selectedCity!)),
                          );
                        },
                  child: const Text('Next'),
                ),
              ],
            ),
      ),
    );
  }
}

class NextScreen extends StatelessWidget {
  final String city;

  const NextScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selected City'),
      ),
      body: Center(
        child: Text('You selected: $city'),
      ),
    );
  }
}
