import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/services/chat_api.dart';
import 'package:flutter/material.dart';

Future<bool?> showSupportRatingSheet(
  BuildContext context, {
  required int ticketId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return _SupportRatingSheet(ticketId: ticketId);
    },
  );
}

class _SupportRatingSheet extends StatefulWidget {
  const _SupportRatingSheet({required this.ticketId});

  final int ticketId;

  @override
  State<_SupportRatingSheet> createState() => _SupportRatingSheetState();
}

class _SupportRatingSheetState extends State<_SupportRatingSheet> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите оценку от 1 до 5')),
      );
      return;
    }
    setState(() => _sending = true);
    final err = await ChatApi.rateSupportTicket(
      ticketId: widget.ticketId,
      rating: _rating,
      comment: _commentController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Оцените ответ поддержки',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Обращение решено — ваш отзыв поможет улучшить сервис.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: _sending ? null : () => setState(() => _rating = star),
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700,
                  size: 36,
                ),
              );
            }),
          ),
          TextField(
            controller: _commentController,
            enabled: !_sending,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Комментарий (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                fixedSize: const Size(double.infinity, 50),
                foregroundColor: whiteprColor,
                backgroundColor: blueaccentColor,
                disabledForegroundColor: grayprprColor,
                shape: const BeveledRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                ),
              ),
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: whiteprColor,
                      ),
                    )
                  : const Text('Отправить оценку'),
            ),
          ),
        ],
      ),
    );
  }
}
