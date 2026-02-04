/// Message types for league chat
enum MessageType {
  chat,
  tradeProposed,
  tradeCountered,
  tradeAccepted,
  tradeCompleted,
  tradeRejected,
  tradeCancelled,
  tradeVetoed,
  tradeInvalidated,
  waiverSuccessful,
  waiverProcessed,
  settingsUpdated,
  memberJoined,
  memberKicked,
  duesPaid,
  duesUnpaid;

  static MessageType fromString(String? value) {
    switch (value) {
      case 'trade_proposed':
        return MessageType.tradeProposed;
      case 'trade_countered':
        return MessageType.tradeCountered;
      case 'trade_accepted':
        return MessageType.tradeAccepted;
      case 'trade_completed':
        return MessageType.tradeCompleted;
      case 'trade_rejected':
        return MessageType.tradeRejected;
      case 'trade_cancelled':
        return MessageType.tradeCancelled;
      case 'trade_vetoed':
        return MessageType.tradeVetoed;
      case 'trade_invalidated':
        return MessageType.tradeInvalidated;
      case 'waiver_successful':
        return MessageType.waiverSuccessful;
      case 'waiver_processed':
        return MessageType.waiverProcessed;
      case 'settings_updated':
        return MessageType.settingsUpdated;
      case 'member_joined':
        return MessageType.memberJoined;
      case 'member_kicked':
        return MessageType.memberKicked;
      case 'dues_paid':
        return MessageType.duesPaid;
      case 'dues_unpaid':
        return MessageType.duesUnpaid;
      default:
        return MessageType.chat;
    }
  }

  String toSnakeCase() {
    switch (this) {
      case MessageType.chat:
        return 'chat';
      case MessageType.tradeProposed:
        return 'trade_proposed';
      case MessageType.tradeCountered:
        return 'trade_countered';
      case MessageType.tradeAccepted:
        return 'trade_accepted';
      case MessageType.tradeCompleted:
        return 'trade_completed';
      case MessageType.tradeRejected:
        return 'trade_rejected';
      case MessageType.tradeCancelled:
        return 'trade_cancelled';
      case MessageType.tradeVetoed:
        return 'trade_vetoed';
      case MessageType.tradeInvalidated:
        return 'trade_invalidated';
      case MessageType.waiverSuccessful:
        return 'waiver_successful';
      case MessageType.waiverProcessed:
        return 'waiver_processed';
      case MessageType.settingsUpdated:
        return 'settings_updated';
      case MessageType.memberJoined:
        return 'member_joined';
      case MessageType.memberKicked:
        return 'member_kicked';
      case MessageType.duesPaid:
        return 'dues_paid';
      case MessageType.duesUnpaid:
        return 'dues_unpaid';
    }
  }
}

/// Metadata for system messages
class SystemMessageMetadata {
  final int? tradeId;
  final String? fromTeam;
  final String? toTeam;
  final int? fromRosterId;
  final int? toRosterId;
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
      if (teamName != null) 'teamName': teamName,
      if (playerName != null) 'playerName': playerName,
      if (playerId != null) 'playerId': playerId,
      if (bidAmount != null) 'bidAmount': bidAmount,
      if (settingName != null) 'settingName': settingName,
    };
  }
}

class ChatMessage {
  final int id;
  final int leagueId;
  final String? userId;
  final String? username;
  final String message;
  final MessageType messageType;
  final SystemMessageMetadata? metadata;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.leagueId,
    this.userId,
    this.username,
    required this.message,
    this.messageType = MessageType.chat,
    this.metadata,
    required this.createdAt,
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
      createdAt: createdAt,
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
