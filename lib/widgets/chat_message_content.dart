import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessageContent extends StatelessWidget {
  const ChatMessageContent({
    super.key,
    required this.message,
    required this.authToken,
  });

  final ChatMessage message;
  final String? authToken;

  String? get _attachmentUrl {
    if (!message.hasAttachment || authToken == null || authToken!.isEmpty) {
      return null;
    }
    return '${Config.apiBase}/chat/attachment.php'
        '?token=${Uri.encodeComponent(authToken!)}'
        '&message_id=${message.id}';
  }

  Future<void> _openAttachment() async {
    final url = _attachmentUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _attachmentUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.hasAttachment && url != null) ...[
          if (message.isImageAttachment)
            GestureDetector(
              onTap: _openAttachment,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      width: 220,
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _attachmentChip(),
                ),
              ),
            )
          else
            _attachmentChip(),
          if (message.body.isNotEmpty &&
              !message.body.startsWith('📎'))
            const SizedBox(height: 6),
        ],
        if (message.body.isNotEmpty &&
            !(message.hasAttachment && message.body.startsWith('📎')))
          Text(message.body),
      ],
    );
  }

  Widget _attachmentChip() {
    final name = message.attachmentName ?? 'Документ';
    return InkWell(
      onTap: _openAttachment,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.isImageAttachment ? Icons.image_outlined : Icons.attach_file,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
