import '../common/enums.dart';

class ChatMessageDto {
  final int id;
  final int leagueId;
  final String? userId;
  final String? username;
  final String message;
  final MessageType messageType;
  final Map<String, dynamic>? metadata;
  final List<ReactionDto> reactions;
  final DateTime createdAt;

  const ChatMessageDto({
    required this.id,
    required this.leagueId,
    this.userId,
    this.username,
    required this.message,
    this.messageType = MessageType.chat,
    this.metadata,
    this.reactions = const [],
    required this.createdAt,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int? ?? json['leagueId'] as int? ?? 0,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      username: json['username'] as String?,
      message: json['message'] as String? ?? '',
      messageType: MessageType.fromString(json['message_type'] as String? ?? json['messageType'] as String?),
      metadata: json['metadata'] as Map<String, dynamic>?,
      reactions: (json['reactions'] as List<dynamic>?)?.map((r) => ReactionDto.fromJson(r as Map<String, dynamic>)).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'user_id': userId,
      'username': username,
      'message': message,
      'message_type': messageType.value,
      'metadata': metadata,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ConversationDto {
  final int id;
  final String otherUserId;
  final String otherUsername;
  final DirectMessageDto? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ConversationDto({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: json['id'] as int? ?? 0,
      otherUserId: json['other_user_id'] as String? ?? json['otherUserId'] as String? ?? '',
      otherUsername: json['other_username'] as String? ?? json['otherUsername'] as String? ?? 'Unknown',
      lastMessage: json['last_message'] != null ? DirectMessageDto.fromJson(json['last_message'] as Map<String, dynamic>) : null,
      unreadCount: json['unread_count'] as int? ?? json['unreadCount'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'other_user_id': otherUserId,
      'other_username': otherUsername,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class DirectMessageDto {
  final int id;
  final int conversationId;
  final String senderId;
  final String senderUsername;
  final String message;
  final List<ReactionDto> reactions;
  final DateTime createdAt;

  const DirectMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.message,
    this.reactions = const [],
    required this.createdAt,
  });

  factory DirectMessageDto.fromJson(Map<String, dynamic> json) {
    return DirectMessageDto(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversation_id'] as int? ?? json['conversationId'] as int? ?? 0,
      senderId: json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      senderUsername: json['sender_username'] as String? ?? json['senderUsername'] as String? ?? '',
      message: json['message'] as String? ?? '',
      reactions: (json['reactions'] as List<dynamic>?)?.map((r) => ReactionDto.fromJson(r as Map<String, dynamic>)).toList() ?? [],
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_username': senderUsername,
      'message': message,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ReactionDto {
  final String emoji;
  final int count;
  final List<String> users;
  final bool hasReacted;

  const ReactionDto({required this.emoji, required this.count, required this.users, this.hasReacted = false});

  factory ReactionDto.fromJson(Map<String, dynamic> json) {
    return ReactionDto(
      emoji: json['emoji'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      users: (json['users'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hasReacted: json['hasReacted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'emoji': emoji, 'count': count, 'users': users, 'hasReacted': hasReacted};
}
