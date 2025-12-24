import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/pages/ads1.dart';
import 'package:crgtransp72app/pages/history_isp.dart';
import 'package:crgtransp72app/pages/list_predloj_na_zayavki.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/* =================================================================== */
/* --------------------- ФОРМА ОТПРАВКИ ОТЗЫВА ----------------------- */

class SendReviewForm extends StatefulWidget {
  final int currentUserId;
  final int targetUserId;

  const SendReviewForm({
    Key? key,
    required this.currentUserId,
    required this.targetUserId,
  }) : super(key: key);

  @override
  State<SendReviewForm> createState() => _SendReviewFormState();
}

/* ------------------------------------------------------------------- */

class _SendReviewFormState extends State<SendReviewForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _selectedRating = 0;
  String _textComment = '';

  Future<void> _submitReview() async {
    // Проверка заполнения формы
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Проверка наличия обязательных полей
    if (widget.currentUserId == null || widget.targetUserId == null) {
      showErrorDialog('Ошибка', 'Пользовательские ID не заданы');
      return;
    }

    final data = {
      'user_id': widget.currentUserId,
      'target_user_id': widget.targetUserId,
      'rating': _selectedRating,
      'comment': _textComment.trim(),
    };

    try {
      final response = await Dio().post(
        '${Config.baseUrl}/api/save_review.php',
        data: data,
        options: Options(validateStatus: (code) => code! >= 200 && code < 300),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // Открытие окна с успешным результатом и последующей навигацией
        showSuccessDialog('Спасибо!', 'Ваш отзыв успешно отправлен.',
            onOkPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => history_isp(
                  nameImg: widget.currentUserId.toString(), bd: 1)));
          print('widget.currentUserId: ${widget.currentUserId}');
        });
      } else {
        showErrorDialog('Ошибка', response.data['message']);
      }
    } catch (e) {
      showErrorDialog('Ошибка', e.toString());
    }
  }

  void showSuccessDialog(String title, String message,
      {Function()? onOkPressed}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("ОК"),
              onPressed: () {
                // Закрываем текущий диалог
                Navigator.pop(context);

                // Если передана колбэк-функция, выполняем её
                if (onOkPressed != null) {
                  onOkPressed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorDialog(String title, String errorMessage) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(errorMessage),
        actions: [
          TextButton(
            child: const Text('ОК'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /* ------------------------- UI ------------------------------------ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оставьте отзыв')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              RatingSelector(
                initialRating: _selectedRating,
                onSelected: (val) => setState(() => _selectedRating = val),
              ),
              SizedBox(height: 24),
              CommentField(
                initialValue: _textComment,
                onSaved: (val) => _textComment = val ?? '',
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.maxFinite,
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                  ),
                  onPressed: _submitReview,
                  child: const Text('Отправить отзыв'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =================================================================== */
/* -------------------- SELECTOR ЗВЁЗД ------------------------------- */

class RatingSelector extends StatelessWidget {
  final int initialRating;
  final Function(int)? onSelected;

  const RatingSelector({
    Key? key,
    required this.initialRating,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        bool isFilled = index < initialRating;
        return IconButton(
          iconSize: 32,
          splashRadius: 20,
          color: isFilled ? Colors.amber : Colors.grey,
          icon: Icon(isFilled ? Icons.star : Icons.star_outline),
          onPressed: () {
            final newRating = index + 1;
            onSelected?.call(newRating);
          },
        );
      }),
    );
  }
}

/* =================================================================== */
/* ------------------ ПОЛЕ КОММЕНТАРИЯ ------------------------------- */

class CommentField extends StatelessWidget {
  final String initialValue;
  final Function(String?)? onSaved;

  const CommentField({
    Key? key,
    required this.initialValue,
    this.onSaved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: TextEditingController(text: initialValue),
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Комментарий',
        border: UnderlineInputBorder(),
        hintText: 'Опишите ваше впечатление...',
      ),
      validator: (value) {
        if ((value?.isEmpty ?? false) || value!.trim().length < 10) {
          return 'Комментарий должен содержать минимум 10 символов.';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}

/* =================================================================== */
/* ========================== MAIN APP ================================ */

void main() {
  runApp(MaterialApp(home: MyHomePage()));
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SendReviewForm(currentUserId: 1, targetUserId: 2),
      ),
    );
  }
}
