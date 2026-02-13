export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show MessageType;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension MessageTypeUI on MessageType {
  String toSnakeCase() => value;
}

/// Metadata for system messages
class SystemMessageMetadata {
  final int? tradeId;
  final String? fromTeam;
  final String? toTeam;
  final int? fromRosterId;
  final int? toRosterId;
  final String? reason; // e.g., for trade_invalidated
  final String? teamName;
  final String? playerName;
  final int? playerId;
  final int? bidAmount;
  final String? settingName;

  const SystemMessageMetadata({
    this.tradeId,
    this.fromTeam,
    this.toTeam,
    this.fromRosterId,
    this.toRosterId,
    this.reason,
    this.teamName,
    this.playerName,
    this.playerId,
    this.bidAmount,
    this.settingName,
  });

  factory SystemMessageMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SystemMessageMetadata();
    return SystemMessageMetadata(
      tradeId: json['tradeId'] as int?,
      fromTeam: json['fromTeam'] as String?,
      toTeam: json['toTeam'] as String?,
      fromRosterId: json['fromRosterId'] as int?,
      toRosterId: json['toRosterId'] as int?,
      reason: json['reason'] as String?,
      teamName: json['teamName'] as String?,
      playerName: json['playerName'] as String?,
      playerId: json['playerId'] as int?,
      bidAmount: json['bidAmount'] as int?,
      settingName: json['settingName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tradeId != null) 'tradeId': tradeId,
      if (fromTeam != null) 'fromTeam': fromTeam,
      if (toTeam != null) 'toTeam': toTeam,
      if (fromRosterId != null) 'fromRosterId': fromRosterId,
      if (toRosterId != null) 'toRosterId': toRosterId,
      if (reason != null) 'reason': reason,
      if (teamName != null) 'teamName': teamName,
      if (playerName != null) 'playerName': playerName,
      if (playerId != null) 'playerId': playerId,
      if (bidAmount != null) 'bidAmount': bidAmount,
      if (settingName != null) 'settingName': settingName,
    };
  }
}

/// Aggregated reaction data for a single emoji on a message.
class ReactionGroup {
  final String emoji;
  final int count;
  final List<String> users;
  final bool hasReacted;

  const ReactionGroup({
    required this.emoji,
    required this.count,
    required this.users,
    this.hasReacted = false,
  });

  factory ReactionGroup.fromJson(Map<String, dynamic> json) {
    return ReactionGroup(
      emoji: json['emoji'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      users: (json['users'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hasReacted: json['hasReacted'] as bool? ?? false,
    );
  }

  ReactionGroup copyWith({
    String? emoji,
    int? count,
    List<String>? users,
    bool? hasReacted,
  }) {
    return ReactionGroup(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      users: users ?? this.users,
      hasReacted: hasReacted ?? this.hasReacted,
    );
  }
}

/// Status of a message being sent
enum MessageSendStatus {
  /// Message confirmed by the server
  sent,

  /// Message is being sent (optimistic, awaiting server ack)
  sending,

  /// Message failed to send
  failed,
}

class ChatMessage {
  final int id;
  final int leagueId;
  final String? userId;
  final String? username;
  final String message;
  final MessageType messageType;
  final SystemMessageMetadata? metadata;
  final List<ReactionGroup> reactions;
  final DateTime createdAt;
  final MessageSendStatus sendStatus;

  /// Idempotency key used for retry of failed messages
  final String? idempotencyKey;

  ChatMessage({
    required this.id,
    required this.leagueId,
    this.userId,
    this.username,
    required this.message,
    this.messageType = MessageType.chat,
    this.metadata,
    this.reactions = const [],
    required this.createdAt,
    this.sendStatus = MessageSendStatus.sent,
    this.idempotencyKey,
  });

  /// Check if this is a system message (no user AND not 'chat' type)
  bool get isSystemMessage => userId == null && messageType != MessageType.chat;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int?;
    if (id == null) {
      throw FormatException('ChatMessage.fromJson: missing required field "id"');
    }

    final leagueId = json['league_id'] as int? ?? json['leagueId'] as int?;
    if (leagueId == null) {
      throw FormatException('ChatMessage.fromJson: missing required field "league_id"');
    }

    final createdAtStr = json['created_at'] as String? ?? json['createdAt'] as String?;
    final createdAt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    if (createdAt == null) {
      throw FormatException('ChatMessage.fromJson: missing or invalid field "created_at"');
    }

    return ChatMessage(
      id: id,
      leagueId: leagueId,
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      username: json['username'] as String?,
      message: json['message'] as String? ?? '',
      messageType: MessageType.fromString(
        json['message_type'] as String? ?? json['messageType'] as String?,
      ),
      metadata: json['metadata'] != null
          ? SystemMessageMetadata.fromJson(json['metadata'] as Map<String, dynamic>?)
          : null,
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map((r) => ReactionGroup.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: createdAt,
    );
  }

  /// Whether this is an optimistic (locally-created) message not yet confirmed by the server.
  bool get isOptimistic => id < 0;

  ChatMessage copyWith({
    int? id,
    List<ReactionGroup>? reactions,
    MessageSendStatus? sendStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      leagueId: leagueId,
      userId: userId,
      username: username,
      message: message,
      messageType: messageType,
      metadata: metadata,
      reactions: reactions ?? this.reactions,
      createdAt: createdAt,
      sendStatus: sendStatus ?? this.sendStatus,
      idempotencyKey: idempotencyKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'user_id': userId,
      'username': username,
      'message': message,
      'message_type': messageType.toSnakeCase(),
      'metadata': metadata?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
