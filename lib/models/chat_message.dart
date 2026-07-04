class ChatMessage {
  ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderType,
    required this.body,
    required this.isMine,
    required this.createdAt,
    this.hasAttachment = false,
    this.attachmentMime,
    this.attachmentName,
    this.isImageAttachment = false,
  });

  final int id;
  final int threadId;
  final String senderType;
  final String body;
  final bool isMine;
  final String createdAt;
  final bool hasAttachment;
  final String? attachmentMime;
  final String? attachmentName;
  final bool isImageAttachment;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _int(json['id']),
      threadId: _int(json['thread_id']),
      senderType: '${json['sender_type'] ?? ''}',
      body: '${json['body'] ?? ''}',
      isMine: json['is_mine'] == true,
      createdAt: '${json['created_at'] ?? ''}',
      hasAttachment: json['has_attachment'] == true,
      attachmentMime: json['attachment_mime']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      isImageAttachment: json['is_image_attachment'] == true,
    );
  }

  static int _int(dynamic v) {
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }
}
