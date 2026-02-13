import 'chat_dtos.dart';

class ListMessagesResponse {
  final List<ChatMessageDto> messages;

  const ListMessagesResponse({required this.messages});

  factory ListMessagesResponse.fromJson(List<dynamic> json) {
    return ListMessagesResponse(
      messages: json.map((m) => ChatMessageDto.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }
}

class ListConversationsResponse {
  final List<ConversationDto> conversations;

  const ListConversationsResponse({required this.conversations});

  factory ListConversationsResponse.fromJson(List<dynamic> json) {
    return ListConversationsResponse(
      conversations: json.map((c) => ConversationDto.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }
}

class UnreadCountResponse {
  final int count;

  const UnreadCountResponse({required this.count});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(count: json['count'] as int? ?? 0);
  }
}
