import 'direct_message.dart';

class Conversation {
  final int id;
  final String otherUserId;
  final String otherUsername;
  final DirectMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int? ?? 0,
      otherUserId: json['other_user_id'] as String? ?? json['otherUserId'] as String? ?? '',
      otherUsername: json['other_username'] as String? ?? json['otherUsername'] as String? ?? 'Unknown',
      lastMessage: json['last_message'] != null
          ? DirectMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? json['unreadCount'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? json['updatedAt'] as String? ?? '') ?? DateTime.utc(1970),
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

  /// Create a copy with updated values
  Conversation copyWith({
    int? id,
    String? otherUserId,
    String? otherUsername,
    DirectMessage? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUsername: otherUsername ?? this.otherUsername,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
