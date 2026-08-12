import 'dart:convert';

import 'package:crgtransp72app/pages/chat_list_screen.dart';
import 'package:crgtransp72app/pages/chat_thread_screen.dart';
import 'package:crgtransp72app/pages/subscription_screen.dart';
import 'package:crgtransp72app/widgets/chat_auth_guard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatPushOpenRequest {
  ChatPushOpenRequest({
    required this.kind,
    this.threadId,
    this.isSupport = false,
    this.promptRating = false,
    this.supportTicketId,
    this.title,
  });

  /// chat | deal_event | subscription
  final String kind;
  final int? threadId;
  final bool isSupport;
  final bool promptRating;
  final int? supportTicketId;
  final String? title;
}

/// Обработка FCM: чат, события сделки, напоминания о подписке.
class ChatPushHandler {
  static ChatPushOpenRequest? _pending;

  static void install() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleRemoteMessage(message);
      }
    });
  }

  static void handlePayload(Map<String, dynamic> data) {
    final req = _parse(data);
    if (req != null) {
      _pending = req;
    }
  }

  static void handlePayloadJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        handlePayload(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  static ChatPushOpenRequest? _parse(Map<String, dynamic> data) {
    final type = '${data['type'] ?? ''}';

    if (type == 'subscription_reminder') {
      return ChatPushOpenRequest(
        kind: 'subscription',
        title: 'Подписка',
      );
    }

    if (type == 'deal_event') {
      final threadId = int.tryParse('${data['thread_id'] ?? ''}');
      return ChatPushOpenRequest(
        kind: 'deal_event',
        threadId: threadId != null && threadId > 0 ? threadId : null,
        title: 'Сделка',
      );
    }

    if (type != 'chat_message') return null;
    final threadId = int.tryParse('${data['thread_id'] ?? ''}');
    if (threadId == null || threadId <= 0) return null;
    final chatType = '${data['chat_type'] ?? 'deal'}';
    final isSupport = chatType == 'support';
    final ticketId = int.tryParse('${data['ticket_id'] ?? ''}');
    final needsRating =
        data['needs_rating'] == '1' || data['needs_rating'] == true;

    return ChatPushOpenRequest(
      kind: 'chat',
      threadId: threadId,
      isSupport: isSupport,
      promptRating: isSupport && needsRating,
      supportTicketId: ticketId != null && ticketId > 0 ? ticketId : null,
      title: isSupport ? 'Поддержка' : 'Чат по заказу',
    );
  }

  static void _handleRemoteMessage(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      handlePayload(message.data);
    }
  }

  static Future<void> tryOpenPending(BuildContext context) async {
    final req = _pending;
    if (req == null || !context.mounted) return;

    if (req.kind == 'subscription') {
      _pending = null;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }

    if (!await ensureChatAuthorized(context)) {
      return;
    }
    if (!context.mounted) return;

    _pending = null;

    if (req.kind == 'deal_event') {
      if (req.threadId != null && req.threadId! > 0) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              threadId: req.threadId!,
              title: req.title ?? 'Чат по заказу',
            ),
          ),
        );
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ChatListScreen(initialTab: 0),
          ),
        );
      }
      return;
    }

    if (req.threadId == null || req.threadId! <= 0) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          threadId: req.threadId!,
          title: req.title ?? (req.isSupport ? 'Поддержка' : 'Чат'),
          isSupport: req.isSupport,
          promptSupportRating: req.promptRating,
          supportTicketId: req.supportTicketId,
        ),
      ),
    );
  }
}
