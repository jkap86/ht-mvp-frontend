class ChatMessage {
  final int id;
  final int leagueId;
  final String userId;
  final String username;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.username,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      leagueId: json['league_id'] as int,
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'user_id': userId,
      'username': username,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
