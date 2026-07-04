import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Телефон и кнопка чата в одной строке (как на карточках объявлений).
class ProfileContactRow extends StatelessWidget {
  const ProfileContactRow({
    super.key,
    required this.phone,
    required this.onChatTap,
    this.showChat = true,
    this.centerOnNarrow = false,
  });

  final String phone;
  final VoidCallback onChatTap;
  final bool showChat;
  final bool centerOnNarrow;

  Future<void> _callPhone() async {
    final cleaned = phone.trim();
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phoneWidget = GestureDetector(
      onTap: _callPhone,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone),
          const SizedBox(width: 4),
          SizedBox(
            width: 130,
            child: Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (!showChat) {
      return phoneWidget;
    }

    final chatWidget = IconButton(
      icon: const Icon(Icons.chat_bubble_outline),
      tooltip: 'Написать',
      onPressed: onChatTap,
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        phoneWidget,
        chatWidget,
      ],
    );

    if (centerOnNarrow) {
      return Center(child: row);
    }

    return row;
  }
}
