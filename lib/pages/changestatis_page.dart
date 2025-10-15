import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/dimension.dart';
import 'reguser1_name.dart';

class chagestatus extends StatefulWidget {
  final int data;

  const chagestatus({super.key, required this.data});

  @override
  // ignore: library_private_types_in_public_api
  _changestatusForm createState() => _changestatusForm();
}

class _changestatusForm extends State<chagestatus> {
  String strData = '';
  String status = 'Юр лицо';
  int RolNum = 1;

  @override
  void initState() {
    super.initState();
    if (widget.data == 1) {
      strData = 'заказчика';
      RolNum = 1;
    } else if (widget.data == 2) {
      strData = 'грузоперевозчика';
      RolNum = 2;
    } else if (widget.data == 3) {
      strData = 'усл. спецтехн';
      RolNum = 3;
    } else if (widget.data == 4) {
      strData = 'усл. грузчиков';
      RolNum = 4;
    }
  }

  int _value = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('Выбор статуса',
                style: TextStyle(
                  color: whiteprColor,
                  fontSize: fontSize30,
                )),
            Text(strData,
                style: const TextStyle(color: whiteprColor, fontSize: 24)),
          ],
        ),
        toolbarHeight: 72, // Опционально: регулировка высоты AppBar
        backgroundColor: blueaccentColor,
      ),
      /*       appBar: AppBar(
        title: Text(
          "Выбор статуса $strData",
          style: TextStyle(
            color: whiteprColor,
          ),
        ),
        backgroundColor: blueaccentColor,
      ),*/
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50.0),
            Image.asset(
              'assets/images/logo.png', // путь к изображению
              width: 189, // ширина изображения
              height: 119, // высота изображения
            ),
            const Text('Выберите статус',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: blackprColor,
                  fontSize: fontSize30,
                )),
            Container(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ListTile(
                    title: const Text('Юр. лицо'),
                    leading: Radio<int>(
                      value: 1,
                      groupValue: _value,
                      activeColor:
                          blueaccentColor, // Change the active radio button color here
                      fillColor: WidgetStateProperty.all(
                          blueaccentColor), // Change the fill color when selected
                      splashRadius: 25, // Change the splash radius when clicked
                      onChanged: (int? value) {
                        setState(() {
                          _value = value!;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Физ. лицо'),
                    leading: Radio<int>(
                      value: 2,
                      groupValue: _value,
                      activeColor:
                          blueaccentColor, // Change the active radio button color here
                      fillColor: WidgetStateProperty.all(
                          blueaccentColor), // Change the fill color when selected
                      splashRadius: 25, // Change the splash radius when clicked
                      onChanged: (int? value) {
                        setState(() {
                          _value = value!;
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
                    int StatNum = _value;
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Creguser1_Name(
                                RolNum: RolNum, StatNum: StatNum)));
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
