import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: RentDateForm()));
}

class RentDateForm extends StatefulWidget {
  const RentDateForm({super.key});

  @override
  _RentDateFormState createState() => _RentDateFormState();
}

class _RentDateFormState extends State {
  String? _selectedOption = 'Как можно быстрее';
  DateTime? _startDate;
  DateTime? _endDate;

// Форматируем дату для отображения
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите дату аренды'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButton(
              value: _selectedOption,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedOption = newValue;
                  _startDate = null;
                  _endDate = null;
                });
              },
              items: const [
                DropdownMenuItem(
                    value: 'Как можно быстрее',
                    child: Text('Как можно быстрее')),
                DropdownMenuItem(
                    value: 'В период с... по...',
                    child: Text('В период с... по...')),
                DropdownMenuItem(
                    value: 'Не позднее чем', child: Text('Не позднее чем')),
              ],
            ),
            if (_selectedOption == 'В период с... по...')
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_startDate == null
                          ? 'Выберите начальную дату'
                          : 'Начало: ${_dateFormat.format(_startDate!)}'),
                      onTap: () => _selectDate(context, isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(_endDate == null
                          ? 'Выберите конечную дату'
                          : 'Конец: ${_dateFormat.format(_endDate!)}'),
                      onTap: () => _selectDate(context, isStart: false),
                    ),
                  ),
                ],
              ),
            if (_selectedOption == 'Не позднее чем')
              ListTile(
                title: Text(_endDate == null
                    ? 'Выберите дату'
                    : 'Не позднее: ${_dateFormat.format(_endDate!)}'),
                onTap: () => _selectDate(context, isStart: false),
              ),
          ],
        ),
      ),
    );
  }
}
