class ChatMessagePayload {
  final int id;
  final int leagueId;
  final String? userId;
  final String? username;
  final String message;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ChatMessagePayload({
    required this.id,
    required this.leagueId,
    this.userId,
    this.username,
    required this.message,
    required this.messageType,
    this.metadata,
    required this.createdAt,
  });

  factory ChatMessagePayload.fromJson(Map<String, dynamic> json) {
    return ChatMessagePayload(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? json['leagueId'] as int? ?? 0,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      username: json['username'] as String?,
      message: json['message'] as String? ?? '',
      messageType: json['message_type'] as String? ?? json['messageType'] as String? ?? 'chat',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.utc(1970),
    );
  }
}

class ChatReactionPayload {
  final int messageId;
  final String emoji;
  final String userId;
  final String? username;

  const ChatReactionPayload({
    required this.messageId,
    required this.emoji,
    required this.userId,
    this.username,
  });

  factory ChatReactionPayload.fromJson(Map<String, dynamic> json) {
    return ChatReactionPayload(
      messageId: json['messageId'] as int? ?? 0,
      emoji: json['emoji'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String?,
    );
  }
}

class DmMessagePayload {
  final int conversationId;
  final Map<String, dynamic> message;

  const DmMessagePayload({required this.conversationId, required this.message});

  factory DmMessagePayload.fromJson(Map<String, dynamic> json) {
    return DmMessagePayload(
      conversationId: json['conversationId'] as int? ?? 0,
      message: json['message'] as Map<String, dynamic>? ?? {},
    );
  }

  int get messageId => message['id'] as int? ?? 0;
  String get senderId => message['sender_id'] as String? ?? '';
  String get senderUsername => message['sender_username'] as String? ?? '';
  String get messageText => message['message'] as String? ?? '';
}

class DmReadPayload {
  final int conversationId;
  final String readBy;

  const DmReadPayload({required this.conversationId, required this.readBy});

  factory DmReadPayload.fromJson(Map<String, dynamic> json) {
    return DmReadPayload(
      conversationId: json['conversationId'] as int? ?? 0,
      readBy: json['readBy'] as String? ?? '',
    );
  }
}

class DmReactionPayload {
  final int messageId;
  final String emoji;
  final String userId;

  const DmReactionPayload({
    required this.messageId,
    required this.emoji,
    required this.userId,
  });

  factory DmReactionPayload.fromJson(Map<String, dynamic> json) {
    return DmReactionPayload(
      messageId: json['messageId'] as int? ?? 0,
      emoji: json['emoji'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
    );
  }
}
