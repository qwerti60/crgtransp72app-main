class ChatThread {
  ChatThread({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.counterpartName,
    this.counterpartUserId,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.bd,
    this.adId,
    this.offerDataId,
    this.orderGlobalId,
    this.supportTicketId,
    this.ticketStatus,
    this.needsRating = false,
  });

  final int id;
  final String type;
  final String status;
  final String title;
  final String counterpartName;
  final int? counterpartUserId;
  final int unreadCount;
  final String lastMessagePreview;
  final String? lastMessageAt;
  final int? bd;
  final int? adId;
  final int? offerDataId;
  final int? orderGlobalId;
  final int? supportTicketId;
  final String? ticketStatus;
  final bool needsRating;

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: _int(json['id']),
      type: '${json['type'] ?? ''}',
      status: '${json['status'] ?? ''}',
      title: '${json['title'] ?? ''}',
      counterpartName: '${json['counterpart_name'] ?? ''}',
      counterpartUserId: json['counterpart_user_id'] != null
          ? _int(json['counterpart_user_id'])
          : null,
      unreadCount: _int(json['unread_count']),
      lastMessagePreview: '${json['last_message_preview'] ?? ''}',
      lastMessageAt: json['last_message_at']?.toString(),
      bd: json['bd'] != null ? _int(json['bd']) : null,
      adId: json['ad_id'] != null ? _int(json['ad_id']) : null,
      offerDataId: json['offer_data_id'] != null
          ? _int(json['offer_data_id'])
          : null,
      orderGlobalId: json['order_global_id'] != null
          ? _int(json['order_global_id'])
          : null,
      supportTicketId: json['support_ticket_id'] != null
          ? _int(json['support_ticket_id'])
          : null,
      ticketStatus: json['ticket_status']?.toString(),
      needsRating: json['needs_rating'] == true,
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }
}
