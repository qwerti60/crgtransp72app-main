import 'package:crgtransp72app/design/colors.dart';
import 'package:crgtransp72app/models/chat_thread.dart';
import 'package:crgtransp72app/pages/chat_thread_screen.dart';
import 'package:crgtransp72app/pages/support_create_screen.dart';
import 'package:crgtransp72app/services/chat_api.dart';
import 'package:crgtransp72app/services/chat_push_handler.dart';
import 'package:crgtransp72app/widgets/chat_auth_guard.dart';
import 'package:crgtransp72app/widgets/chat_shell_nav.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    this.initialTab = 0,
    this.showBottomNav = false,
    this.isPerformer = false,
  });

  final int initialTab;
  final bool showBottomNav;
  final bool isPerformer;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<ChatThread> _dealThreads = [];
  List<ChatThread> _supportThreads = [];
  String? _error;

  String get _dealTabLabel =>
      widget.isPerformer ? 'С заказчиками' : 'С исполнителями';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatPushHandler.tryOpenPending(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ChatApi.fetchAllThreads();
      if (!mounted) return;
      setState(() {
        _dealThreads = result.deal;
        _supportThreads = result.support;
        _error = result.error;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить сообщения';
        _loading = false;
      });
    }
  }

  Future<void> _openSupportCreate() async {
    if (!await ensureChatAuthorized(context)) return;
    if (!mounted) return;
    final threadId = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => SupportCreateScreen(
          showBottomNav: widget.showBottomNav,
          isPerformer: widget.isPerformer,
        ),
      ),
    );
    if (threadId != null && mounted) {
      await _load();
      if (!mounted) return;
      await _openThreadById(threadId, 'Поддержка', isSupport: true);
      await _load();
    }
  }

  Future<void> _openThread(ChatThread thread) {
    return _openThreadById(
      thread.id,
      thread.type == 'support' ? thread.title : thread.counterpartName,
      isSupport: thread.type == 'support',
      subtitle: thread.type == 'deal' ? thread.title : null,
      promptSupportRating: thread.needsRating,
      supportTicketId: thread.supportTicketId,
    );
  }

  Future<void> _openThreadById(
    int threadId,
    String title, {
    required bool isSupport,
    String? subtitle,
    bool promptSupportRating = false,
    int? supportTicketId,
  }) {
    return Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          threadId: threadId,
          title: title,
          subtitle: subtitle,
          isSupport: isSupport,
          showBottomNav: widget.showBottomNav,
          isPerformer: widget.isPerformer,
          promptSupportRating: promptSupportRating,
          supportTicketId: supportTicketId,
        ),
      ),
    )
        .then((_) => _load());
  }

  Widget _buildList(List<ChatThread> threads, {required bool isSupport}) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    if (threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSupport
                    ? 'Обращений в поддержку пока нет'
                    : widget.isPerformer
                        ? 'Чатов с заказчиками пока нет'
                        : 'Чатов с исполнителями пока нет',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSupport
                    ? 'Нажмите + чтобы написать в поддержку'
                    : 'Откройте чат с иконки сообщения у объявления',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              if (isSupport) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _openSupportCreate,
                  child: const Text('Написать в поддержку'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: threads.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final t = threads[index];
          return ListTile(
            leading: CircleAvatar(
              child: Icon(
                t.type == 'support' ? Icons.support_agent : Icons.person,
              ),
            ),
            title: Text(
              t.type == 'support' ? t.title : t.counterpartName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              t.lastMessagePreview.isNotEmpty
                  ? t.lastMessagePreview
                  : 'Нет сообщений',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: t.unreadCount > 0
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${t.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  )
                : null,
            onTap: () => _openThread(t),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Сообщения',
          style: TextStyle(color: whiteprColor),
        ),
        backgroundColor: blueaccentColor,
        iconTheme: const IconThemeData(color: whiteprColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: whiteprColor,
          unselectedLabelColor: Color.fromARGB(180, 255, 255, 255),
          indicatorColor: whiteprColor,
          tabs: [
            Tab(text: _dealTabLabel),
            const Tab(text: 'Поддержка'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: whiteprColor),
            tooltip: 'Новое обращение в поддержку',
            onPressed: _openSupportCreate,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_dealThreads, isSupport: false),
          _buildList(_supportThreads, isSupport: true),
        ],
      ),
      bottomNavigationBar: chatShellBottomNav(
        showBottomNav: widget.showBottomNav,
        isPerformer: widget.isPerformer,
      ),
    );
  }
}
