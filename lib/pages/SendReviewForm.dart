import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/navigation/shell_nav_auth_cache.dart';
import 'package:crgtransp72app/pages/sendNotification.dart';
import 'package:crgtransp72app/pages/zakaz_screen2.dart';
import 'package:crgtransp72app/services/review_pair_api.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/* =================================================================== */
/* --------------------- ФОРМА ОТПРАВКИ ОТЗЫВА ----------------------- */

class SendReviewForm extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final int parsedUserIdOk;
  const SendReviewForm({
    Key? key,
    required this.currentUserId,
    required this.targetUserId,
    required this.parsedUserIdOk,
  }) : super(key: key);
  State<SendReviewForm> createState() {
    // Логируем значения переменных
    print('Initializing SendReviewForm with:');
    print('Current User ID: $currentUserId');
    print('Target User ID: $targetUserId');

    return _SendReviewFormState();
  }
}

/* ------------------------------------------------------------------- */

class _SendReviewFormState extends State<SendReviewForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;

  int _selectedRating = 0;
  bool _loadingReview = true;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final performerId = int.tryParse(widget.currentUserId) ?? 0;
    final customerId = int.tryParse(widget.targetUserId) ?? 0;
    final existing = await fetchReviewBetween(
      table: ReviewPairTable.performerAboutCustomer,
      performerId: performerId,
      customerId: customerId,
    );
    if (!mounted) return;
    if (existing != null) {
      _selectedRating = existing.rating;
      _commentController.text = existing.comment;
      _isEdit = true;
    }
    setState(() => _loadingReview = false);
  }

  Future<void> _submitReview() async {
    // Проверка заполнения формы
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRating < 1) {
      showErrorDialog('Ошибка', 'Выберите оценку');
      return;
    }
    _formKey.currentState!.save();

    final comment = _commentController.text.trim();
    final data = {
      'user_id': widget.currentUserId,
      'target_user_id': widget.targetUserId,
      'rating': _selectedRating,
      'comment': comment,
    };

    try {
      final response = await Dio().post(
        '${Config.apiBase}/save_review.php',
        data: data,
        options: Options(validateStatus: (code) => code! >= 200 && code < 300),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        await notifyUserById(
          userId: widget.targetUserId,
          title: kDefaultPushTitle,
          body: 'Исполнитель оставил отзыв о заказчике',
        );
        PerformerShellNavCache.update(
          isAuthorized: true,
          highlightOrders: false,
        );
        final successText = _isEdit
            ? 'Отзыв обновлён'
            : 'Ваш отзыв успешно отправлен.';
        showSuccessDialog('Спасибо!', successText, onOkPressed: () {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const MyAppZakazScreen(initialPage: 0),
            ),
            (route) => false,
          );
          print(
              'API Success: Review submitted by user ${widget.currentUserId} for user ${widget.targetUserId}.');
        });
      } else {
        // Логируем сообщение об ошибке
        print(
            'API Error: Status Code=${response.statusCode}, Message=${response.data["message"]}');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Изменить отзыв' : 'Оставьте отзыв',
          style: const TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
      ),
      body: _loadingReview
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    RatingSelector(
                      initialRating: _selectedRating,
                      onSelected: (val) => setState(() => _selectedRating = val),
                    ),
                    const SizedBox(height: 24),
                    CommentField(controller: _commentController),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.maxFinite,
                      height: 50,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all(Colors.white),
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blue),
                        ),
                        onPressed: _submitReview,
                        child: Text(_isEdit
                            ? 'Сохранить изменения'
                            : 'Отправить отзыв'),
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
  final TextEditingController controller;

  const CommentField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
        child: SendReviewForm(
            currentUserId: '1', targetUserId: '2', parsedUserIdOk: 106),
      ),
    );
  }
}
