import 'dart:async';
import 'dart:typed_data';

import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/chat_message.dart';
import 'package:crgtransp72app/pages/chat_list_screen.dart';
import 'package:crgtransp72app/pages/fcm_token.dart';
import 'package:crgtransp72app/pages/support_create_screen.dart';
import 'package:crgtransp72app/services/chat_api.dart';
import 'package:crgtransp72app/widgets/chat_auth_guard.dart';
import 'package:crgtransp72app/widgets/chat_message_content.dart';
import 'package:crgtransp72app/widgets/chat_shell_nav.dart';
import 'package:crgtransp72app/widgets/support_rating_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.threadId,
    required this.title,
    this.subtitle,
    this.readOnly = false,
    this.isSupport = false,
    this.showBottomNav = true,
    this.isPerformer = false,
    this.promptSupportRating = false,
    this.supportTicketId,
    this.bd,
    this.adId,
    this.offerDataId,
    this.orderGlobalId,
  });

  final int threadId;
  final String title;
  final String? subtitle;
  final bool readOnly;
  final bool isSupport;
  final bool showBottomNav;
  final bool isPerformer;
  final bool promptSupportRating;
  final int? supportTicketId;
  final int? bd;
  final int? adId;
  final int? offerDataId;
  final int? orderGlobalId;

  /// Открыть или создать диалог по объявлению, затем показать переписку.
  static Future<void> openDeal({
    required BuildContext context,
    required int counterpartUserId,
    required int bd,
    required int adId,
    required String title,
    required int currentUserId,
    bool showBottomNav = true,
    bool isPerformer = false,
  }) async {
    if (!await ensureChatAuthorized(context)) return;
    if (!context.mounted) return;

    if (counterpartUserId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя написать самому себе')),
      );
      return;
    }

    OverlayEntry? blocker;
    void removeBlocker() {
      blocker?.remove();
      blocker = null;
    }

    ({int? threadId, String? error}) result;
    try {
      final overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay != null) {
        blocker = OverlayEntry(
          builder: (_) => const Stack(
            children: [
              ModalBarrier(dismissible: false, color: Color(0x33000000)),
              Center(child: CircularProgressIndicator()),
            ],
          ),
        );
        overlay.insert(blocker!);
      }

      result = await ChatApi.openDealThread(
        counterpartUserId: counterpartUserId,
        bd: bd,
        adId: adId,
      );
    } catch (e) {
      result = (threadId: null, error: 'Сеть: $e');
    } finally {
      removeBlocker();
    }

    if (result.threadId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Не удалось открыть чат'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          threadId: result.threadId!,
          title: title,
          subtitle: 'Объявление #$adId',
          showBottomNav: showBottomNav,
          isPerformer: isPerformer,
          bd: bd,
          adId: adId,
        ),
      ),
    );
  }

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _loadError;
  Timer? _pollTimer;
  int _lastId = 0;
  bool _ratingPromptShown = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    getSecurefcm_token().then((token) {
      if (mounted) setState(() => _authToken = token);
    });
    _loadInitial();
    _pollTimer = Timer.periodic(const Duration(seconds: 7), (_) => _poll());
  }

  Future<void> _openReport() async {
    if (!await ensureChatAuthorized(context)) return;
    if (!mounted) return;
    final contextJson = <String, dynamic>{
      'thread_id': widget.threadId,
      if (widget.bd != null && widget.bd! > 0) 'bd': widget.bd,
      if (widget.adId != null && widget.adId! > 0) 'ad_id': widget.adId,
      if (widget.offerDataId != null && widget.offerDataId! > 0)
        'offer_data_id': widget.offerDataId,
      if (widget.orderGlobalId != null && widget.orderGlobalId! > 0)
        'order_global_id': widget.orderGlobalId,
    };
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportCreateScreen(
          showBottomNav: false,
          isPerformer: widget.isPerformer,
          initialCategory: 'deal_dispute',
          initialSubject: 'Жалоба по чату #${widget.threadId}',
          lockCategory: true,
          contextJson: contextJson,
        ),
      ),
    );
  }

  Future<void> _maybePromptSupportRating() async {
    if (!widget.isSupport ||
        !widget.promptSupportRating ||
        _ratingPromptShown ||
        widget.supportTicketId == null ||
        widget.supportTicketId! <= 0) {
      return;
    }
    _ratingPromptShown = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await showSupportRatingSheet(
      context,
      ticketId: widget.supportTicketId!,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await ChatApi.fetchMessages(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages = result.messages;
        _loadError = result.error;
        _lastId = result.messages.isEmpty ? 0 : result.messages.last.id;
      });
      _markRead();
      _scrollToBottom();
      await _maybePromptSupportRating();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Не удалось загрузить чат';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _poll() async {
    if (_loading || _loadError != null) return;
    final items = await ChatApi.pollMessages(widget.threadId, _lastId);
    if (items.isEmpty || !mounted) return;
    setState(() {
      _messages = [..._messages, ...items];
      _lastId = _messages.last.id;
    });
    _markRead();
    _scrollToBottom();
  }

  Future<void> _markRead() async {
    if (_messages.isEmpty) return;
    await ChatApi.markRead(widget.threadId, _messages.last.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || widget.readOnly) return;

    setState(() => _sending = true);
    final err = await ChatApi.sendMessage(widget.threadId, text);
    if (!mounted) return;
    setState(() => _sending = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    _controller.clear();
    await _loadInitial();
  }

  String? _mimeFromFilename(String filename) {
    switch (p.extension(filename).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.txt':
        return 'text/plain';
      default:
        return null;
    }
  }

  Future<String?> _compressImageIfNeeded(String path) async {
    final ext = p.extension(path).toLowerCase();
    if (ext != '.jpg' && ext != '.jpeg' && ext != '.png' && ext != '.webp') {
      return path;
    }
    final dir = p.dirname(path);
    final outPath = p.join(dir, '${p.basenameWithoutExtension(path)}_chat.jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      path,
      outPath,
      minWidth: 1280,
      minHeight: 1280,
      quality: 85,
    );
    return compressed?.path ?? path;
  }

  Future<void> _sendAttachment({
    String? filePath,
    Uint8List? fileBytes,
    required String filename,
    String? mimeType,
  }) async {
    if (_sending || widget.readOnly) return;

    setState(() => _sending = true);
    final err = await ChatApi.sendMessageWithFile(
      threadId: widget.threadId,
      body: _controller.text.trim(),
      filePath: filePath,
      fileBytes: fileBytes,
      filename: filename,
      mimeType: mimeType ?? _mimeFromFilename(filename),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }

    _controller.clear();
    await _loadInitial();
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Галерея'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Камера'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null || !mounted) return;

    final uploadPath = await _compressImageIfNeeded(picked.path);
    if (uploadPath == null || !mounted) return;

    final name = p.basename(uploadPath);
    await _sendAttachment(
      filePath: uploadPath,
      filename: name,
      mimeType: _mimeFromFilename(name) ?? 'image/jpeg',
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
      ],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    final path = file.path;
    final bytes = file.bytes;
    if ((path == null || path.isEmpty) && (bytes == null || bytes.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось прочитать файл')),
      );
      return;
    }

    final name = file.name.isNotEmpty ? file.name : p.basename(path ?? 'file');
    await _sendAttachment(
      filePath: path,
      fileBytes: bytes,
      filename: name,
      mimeType: _mimeFromFilename(name),
    );
  }

  Future<void> _showAttachMenu() async {
    if (_sending || widget.readOnly) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Фото'),
              onTap: () => Navigator.pop(ctx, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Документ'),
              onTap: () => Navigator.pop(ctx, 'doc'),
            ),
          ],
        ),
      ),
    );

    if (action == 'photo') {
      await _pickPhoto();
    } else if (action == 'doc') {
      await _pickDocument();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteprColor,
      appBar: AppBar(
        backgroundColor: blueaccentColor,
        iconTheme: const IconThemeData(color: whiteprColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, color: whiteprColor),
            ),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
              Text(
                widget.subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: whiteprColor.withValues(alpha: 0.85),
                ),
              ),
          ],
        ),
        actions: [
          if (!widget.isSupport)
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: whiteprColor),
              tooltip: 'Пожаловаться',
              onPressed: _openReport,
            ),
          if (widget.isSupport)
            IconButton(
              icon: const Icon(Icons.list_alt, color: whiteprColor),
              tooltip: 'Все обращения',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatListScreen(
                      initialTab: 1,
                      showBottomNav: widget.showBottomNav,
                      isPerformer: widget.isPerformer,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_loadError!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadInitial,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMine = m.isMine;
                      final isSystem = m.senderType == 'system';
                      if (isSystem) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              m.body,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return Align(
                        alignment:
                            isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.blue.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChatMessageContent(
                                message: m,
                                authToken: _authToken,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.createdAt,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (!widget.readOnly)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Прикрепить файл',
                      onPressed: _sending ? null : _showAttachMenu,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Сообщение…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
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
