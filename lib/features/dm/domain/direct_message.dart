import '../../../features/chat/domain/chat_message.dart' show ReactionGroup;

class DirectMessage {
  final int id;
  final int conversationId;
  final String senderId;
  final String senderUsername;
  final String message;
  final List<ReactionGroup> reactions;
  final DateTime createdAt;

  DirectMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.message,
    this.reactions = const [],
    required this.createdAt,
  });

  DirectMessage copyWith({
    List<ReactionGroup>? reactions,
  }) {
    return DirectMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      senderUsername: senderUsername,
      message: message,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt,
    );
  }

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversation_id'] as int? ?? json['conversationId'] as int? ?? 0,
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      senderUsername: json['sender_username'] as String? ?? json['senderUsername'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? '',
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => ReactionGroup.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Parse DateTime from various formats (String ISO8601, DateTime, or null)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      // Server should always provide created_at, but fallback gracefully
      return DateTime.now();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    // Fallback only if truly unparseable
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
