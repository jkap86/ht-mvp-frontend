class SendMessageRequest {
  final int leagueId;
  final String message;
  final String? idempotencyKey;

  const SendMessageRequest({
    required this.leagueId,
    required this.message,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'league_id': leagueId,
      'message': message,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
    };
  }
}

class AddReactionRequest {
  final int messageId;
  final String emoji;

  const AddReactionRequest({required this.messageId, required this.emoji});

  Map<String, dynamic> toJson() => {'message_id': messageId, 'emoji': emoji};
}

class SearchMessagesRequest {
  final int leagueId;
  final String query;
  final int? limit;
  final int? offset;

  const SearchMessagesRequest({
    required this.leagueId,
    required this.query,
    this.limit,
    this.offset,
  });

  Map<String, dynamic> toJson() {
    return {
      'league_id': leagueId,
      'query': query,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };
  }
}
