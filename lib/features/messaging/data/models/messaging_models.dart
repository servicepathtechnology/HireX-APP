class MessageThread {
  final String id;
  final String recruiterId;
  final String candidateId;
  final String taskId;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isActive;
  final DateTime createdAt;

  // Enriched fields (fetched separately)
  final String? otherPartyName;
  final String? otherPartyAvatar;
  final String? taskTitle;

  const MessageThread({
    required this.id,
    required this.recruiterId,
    required this.candidateId,
    required this.taskId,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.unreadCount,
    required this.isActive,
    required this.createdAt,
    this.otherPartyName,
    this.otherPartyAvatar,
    this.taskTitle,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) => MessageThread(
        id: json['id'] as String,
        recruiterId: json['recruiter_id'] as String,
        candidateId: json['candidate_id'] as String,
        taskId: json['task_id'] as String,
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.parse(json['last_message_at'] as String)
            : null,
        lastMessagePreview: json['last_message_preview'] as String?,
        unreadCount: json['unread_count'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        otherPartyName: json['other_party_name'] as String?,
        otherPartyAvatar: json['other_party_avatar'] as String?,
        taskTitle: json['task_title'] as String?,
      );
}

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        threadId: json['thread_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        isRead: json['is_read'] as bool? ?? false,
        readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        id: id,
        threadId: threadId,
        senderId: senderId,
        content: content,
        isRead: isRead,
        readAt: readAt,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}

enum MessageStatus { sending, sent, failed }
