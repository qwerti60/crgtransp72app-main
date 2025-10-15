import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPage createState() => _RegisterPage();
}

class _RegisterPage extends State {
  List _cities = [];
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future _fetchCities() async {
    try {
      final response =
          await http.get(Uri.parse(Config.baseUrl).replace(path: 'cities.php'));
      if (response.statusCode == 200) {
        setState(() {
          _cities = json.decode(response.body);
        });
      } else {
        print('Failed to load cities: ${response.statusCode}');
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      print('Error fetching cities: $e');
    }
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
      body: _cities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButton(
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
