import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/pages/add_ob_vidt.dart';
import 'package:crgtransp72app/pages/add_ob_gp1.dart';
import 'package:flutter/material.dart';

import 'add_ob_gr.dart';

class changerol extends StatefulWidget {
  const changerol({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _changerolForm createState() => _changerolForm();
}

class _changerolForm extends State<changerol> {
  int _valueRole = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Выбор роли',
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ListTile(
                    title: const Text('Грузоперевозчик'),
                    leading: Radio<int>(
                      value: 2,
                      groupValue: _valueRole,
                      activeColor:
                          blueaccentColor, // Change the active radio button color here
                      fillColor: WidgetStateProperty.all(
                          blueaccentColor), // Change the fill color when selected
                      splashRadius: 25, // Change the splash radius when clicked
                      onChanged: (int? value) {
                        setState(() {
                          _valueRole = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Услуги спецтехники'),
                    leading: Radio<int>(
                      value: 3,
                      groupValue: _valueRole,
                      activeColor:
                          blueaccentColor, // Change the active radio button color here
                      fillColor: WidgetStateProperty.all(
                          blueaccentColor), // Change the fill color when selected
                      splashRadius: 25, // Change the splash radius when clicked
                      onChanged: (int? value) {
                        setState(() {
                          _valueRole = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Услуги грузчиков'),
                    leading: Radio<int>(
                      value: 4,
                      groupValue: _valueRole,
                      activeColor:
                          blueaccentColor, // Change the active radio button color here
                      fillColor: WidgetStateProperty.all(
                          blueaccentColor), // Change the fill color when selected
                      splashRadius: 25, // Change the splash radius when clicked
                      onChanged: (int? value) {
                        setState(() {
                          _valueRole = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              margin: const EdgeInsets.only(top: 20.0),
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
                  onPressed: () {
                    if (_valueRole == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const add_ob_gp(),
                        ),
                      );
                    }
                    if (_valueRole == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const add_ob_vidt(),
                        ),
                      );
                    }
                    if (_valueRole == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const add_ob_gr(),
                        ),
                      );
                    }
                  },
                  child: const Text('Продолжить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
