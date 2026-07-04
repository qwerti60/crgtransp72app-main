import 'dart:convert';
import 'dart:typed_data';

import 'package:crgtransp72app/config.dart';
import 'package:crgtransp72app/models/chat_message.dart';
import 'package:crgtransp72app/models/chat_thread.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ChatApiResponse {
  ChatApiResponse({
    required this.success,
    this.error,
    this.items = const [],
    this.data = const {},
  });

  final bool success;
  final String? error;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> data;
}

class ChatApi {
  static const _timeout = Duration(seconds: 25);

  static Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${Config.baseUrl}$path').replace(queryParameters: query);
  }

  static Future<String?> _token() => getSecurefcm_token();

  static ChatApiResponse _parseResponse(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) {
      return ChatApiResponse(
        success: false,
        error: 'Пустой ответ сервера (${response.statusCode})',
      );
    }
    if (raw.startsWith('<') || raw.startsWith('<!')) {
      final preview = raw
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .trim();
      final short = preview.length > 120 ? '${preview.substring(0, 120)}…' : preview;
      return ChatApiResponse(
        success: false,
        error: short.isEmpty
            ? 'Сервер вернул HTML вместо JSON (${response.statusCode})'
            : 'Сервер: $short',
      );
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) {
        return ChatApiResponse(success: false, error: 'Некорректный ответ');
      }
      final map = Map<String, dynamic>.from(decoded);
      final itemsRaw = map['items'];
      final items = <Map<String, dynamic>>[];
      if (itemsRaw is List) {
        for (final item in itemsRaw) {
          if (item is Map) {
            items.add(Map<String, dynamic>.from(item));
          }
        }
      }
      return ChatApiResponse(
        success: map['success'] == true,
        error: map['error']?.toString(),
        items: items,
        data: map,
      );
    } catch (e) {
      return ChatApiResponse(success: false, error: 'Ошибка разбора ответа: $e');
    }
  }

  static Future<ChatApiResponse> _get(
    String path,
    Map<String, String> query,
  ) async {
    final token = await _token();
    if (token == null) {
      return ChatApiResponse(success: false, error: 'Требуется авторизация');
    }
    try {
      final response = await http
          .get(_uri(path, {...query, 'token': token}))
          .timeout(_timeout);
      return _parseResponse(response);
    } on Exception catch (e) {
      return ChatApiResponse(success: false, error: 'Сеть: $e');
    }
  }

  static Future<ChatApiResponse> _post(
    String path,
    Map<String, String> body,
  ) async {
    final token = await _token();
    if (token == null) {
      return ChatApiResponse(success: false, error: 'Требуется авторизация');
    }
    try {
      final response = await http
          .post(_uri(path), body: {...body, 'token': token})
          .timeout(_timeout);
      return _parseResponse(response);
    } on Exception catch (e) {
      return ChatApiResponse(success: false, error: 'Сеть: $e');
    }
  }

  static List<ChatThread> _threadsFromResponse(ChatApiResponse res) {
    if (!res.success) return [];
    return res.items.map(ChatThread.fromJson).toList();
  }

  static List<ChatMessage> _messagesFromResponse(ChatApiResponse res) {
    if (!res.success) return [];
    return res.items.map(ChatMessage.fromJson).toList();
  }

  static Future<({List<ChatThread> deal, List<ChatThread> support, String? error})>
      fetchAllThreads() async {
    final res = await _get('/api/chat/threads.php', {});
    if (!res.success) {
      return (
        deal: <ChatThread>[],
        support: <ChatThread>[],
        error: res.error ?? 'Не удалось загрузить',
      );
    }
    final all = _threadsFromResponse(res);
    return (
      deal: all.where((t) => t.type == 'deal').toList(),
      support: all.where((t) => t.type == 'support').toList(),
      error: null,
    );
  }

  static Future<List<ChatThread>> fetchThreads({String? type}) async {
    final query = <String, String>{};
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    final res = await _get('/api/chat/threads.php', query);
    return _threadsFromResponse(res);
  }

  static Future<({List<ChatMessage> messages, String? error})> fetchMessages(
    int threadId,
  ) async {
    final res = await _get('/api/chat/messages.php', {
      'thread_id': '$threadId',
    });
    if (!res.success) {
      return (
        messages: <ChatMessage>[],
        error: res.error ?? 'Не удалось загрузить чат',
      );
    }
    return (messages: _messagesFromResponse(res), error: null);
  }

  static Future<List<ChatMessage>> pollMessages(
    int threadId,
    int afterId,
  ) async {
    final res = await _get('/api/chat/poll.php', {
      'thread_id': '$threadId',
      'after_id': '$afterId',
    });
    return _messagesFromResponse(res);
  }

  static Future<({int? threadId, String? error})> openDealThread({
    required int counterpartUserId,
    required int bd,
    required int adId,
  }) async {
    final res = await _post('/api/chat/open_deal.php', {
      'counterpart_user_id': '$counterpartUserId',
      'bd': '$bd',
      'ad_id': '$adId',
    });
    if (!res.success) {
      return (threadId: null, error: res.error ?? 'Не удалось открыть чат');
    }
    final id = int.tryParse('${res.data['thread_id']}');
    if (id == null || id <= 0) {
      return (threadId: null, error: 'Некорректный ответ сервера');
    }
    return (threadId: id, error: null);
  }

  static Future<String?> sendMessage(int threadId, String body) async {
    final res = await _post('/api/chat/send.php', {
      'thread_id': '$threadId',
      'body': body,
    });
    if (res.success) return null;
    return res.error ?? 'Не удалось отправить';
  }

  static Future<String?> sendMessageWithFile({
    required int threadId,
    required String body,
    String? filePath,
    Uint8List? fileBytes,
    required String filename,
    String? mimeType,
  }) async {
    if ((filePath == null || filePath.isEmpty) &&
        (fileBytes == null || fileBytes.isEmpty)) {
      return 'Файл не выбран';
    }

    final token = await _token();
    if (token == null) {
      return 'Требуется авторизация';
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        _uri('/api/chat/send.php', {'token': token}),
      );
      request.fields['token'] = token;
      request.fields['thread_id'] = '$threadId';
      request.fields['body'] = body;

      MediaType? contentType;
      if (mimeType != null && mimeType.isNotEmpty) {
        try {
          contentType = MediaType.parse(mimeType);
        } catch (_) {
          contentType = null;
        }
      }

      if (fileBytes != null && fileBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: filename,
            contentType: contentType,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath!,
            filename: filename,
            contentType: contentType,
          ),
        );
      }

      final streamed = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final parsed = _parseResponse(response);
      if (parsed.success) return null;
      return parsed.error ?? 'Не удалось отправить файл';
    } on Exception catch (e) {
      return 'Сеть: $e';
    }
  }

  static Future<void> markRead(int threadId, int lastMessageId) async {
    if (lastMessageId <= 0) return;
    await _post('/api/chat/read.php', {
      'thread_id': '$threadId',
      'last_read_message_id': '$lastMessageId',
    });
  }

  static Future<Map<String, dynamic>?> createSupportTicket({
    required String subject,
    required String category,
    required String body,
  }) async {
    final res = await _post('/api/support/create.php', {
      'subject': subject,
      'category': category,
      'body': body,
    });
    if (res.success) return res.data;
    return {
      'success': false,
      'error': res.error ?? 'Ошибка',
    };
  }

  static Future<String?> rateSupportTicket({
    required int ticketId,
    required int rating,
    String comment = '',
  }) async {
    final res = await _post('/api/support/rate.php', {
      'ticket_id': '$ticketId',
      'rating': '$rating',
      'comment': comment,
    });
    if (res.success) return null;
    return res.error ?? 'Не удалось отправить оценку';
  }
}
