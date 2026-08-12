import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/services/chat_api.dart';
import 'package:crgtransp72app/widgets/chat_shell_nav.dart';
import 'package:flutter/material.dart';

class SupportCreateScreen extends StatefulWidget {
  const SupportCreateScreen({
    super.key,
    this.showBottomNav = false,
    this.isPerformer = false,
    this.initialCategory,
    this.initialSubject,
    this.contextJson,
    this.lockCategory = false,
  });

  final bool showBottomNav;
  final bool isPerformer;
  final String? initialCategory;
  final String? initialSubject;
  final Map<String, dynamic>? contextJson;
  final bool lockCategory;

  @override
  State<SupportCreateScreen> createState() => _SupportCreateScreenState();
}

class _SupportCreateScreenState extends State<SupportCreateScreen> {
  late final TextEditingController _subjectController;
  final _bodyController = TextEditingController();
  late String _category;
  bool _sending = false;

  static const _categories = <String, String>{
    'account': 'Аккаунт и вход',
    'ad_moderation': 'Модерация объявления',
    'payment': 'Подписка и оплата',
    'deal_dispute': 'Спор по заказу',
    'bug': 'Ошибка приложения',
    'other': 'Другое',
  };

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    _category = (initial != null && _categories.containsKey(initial))
        ? initial
        : 'other';
    _subjectController = TextEditingController(
      text: widget.initialSubject ?? '',
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите текст обращения')),
      );
      return;
    }

    setState(() => _sending = true);
    Map<String, dynamic>? result;
    try {
      result = await ChatApi.createSupportTicket(
        subject: _subjectController.text.trim(),
        category: _category,
        body: body,
        contextJson: widget.contextJson,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    if (!mounted) return;

    if (result == null || result['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result?['error'] ?? 'Ошибка'}'),
        ),
      );
      return;
    }

    final threadId = int.tryParse('${result['thread_id']}');
    if (!mounted) return;
    Navigator.of(context).pop(threadId);
  }

  @override
  Widget build(BuildContext context) {
    final isReport = widget.contextJson != null && widget.contextJson!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isReport ? 'Пожаловаться' : 'Поддержка',
          style: const TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
        iconTheme: const IconThemeData(color: whiteprColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isReport
                ? 'Опишите нарушение — оператор проверит контекст и переписку.'
                : 'Опишите проблему — оператор ответит в этом диалоге.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Категория',
              border: OutlineInputBorder(),
            ),
            items: _categories.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (_sending || widget.lockCategory)
                ? null
                : (v) {
                    if (v != null) setState(() => _category = v);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectController,
            enabled: !_sending,
            decoration: const InputDecoration(
              labelText: 'Тема (необязательно)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            enabled: !_sending,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Сообщение',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                fixedSize: const Size(double.infinity, 50),
                foregroundColor: whiteprColor,
                backgroundColor: blueaccentColor,
                disabledForegroundColor: grayprprColor,
                disabledBackgroundColor: grayprprColor,
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
                  : const Text('Отправить'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: chatShellBottomNav(
        showBottomNav: widget.showBottomNav,
        isPerformer: widget.isPerformer,
      ),
    );
  }
}
