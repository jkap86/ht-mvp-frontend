import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/chat_message.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ChatRepository(apiClient);
});

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  Future<List<ChatMessage>> getMessages(
    int leagueId, {
    int limit = 50,
    int? before,
    DateTime? aroundTimestamp,
  }) async {
    final queryParts = <String>['limit=$limit'];
    if (before != null) {
      queryParts.add('before=$before');
    }
    if (aroundTimestamp != null) {
      queryParts.add('around_timestamp=${aroundTimestamp.toIso8601String()}');
    }
    final queryString = queryParts.join('&');

    final response = await _apiClient.get('/leagues/$leagueId/chat?$queryString');
    return (response as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> searchMessages(
    int leagueId,
    String query, {
    int limit = 100,
    int offset = 0,
  }) async {
    final queryString = 'q=${Uri.encodeComponent(query)}&limit=$limit&offset=$offset';
    final response = await _apiClient.get('/leagues/$leagueId/chat/search?$queryString');

    return {
      'messages': (response['messages'] as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList(),
      'total': response['total'] as int,
      'limit': response['limit'] as int,
      'offset': response['offset'] as int,
    };
  }

  Future<void> sendMessage(int leagueId, String message, {String? idempotencyKey}) async {
    await _apiClient.post(
      '/leagues/$leagueId/chat',
      body: {'message': message},
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> addReaction(int leagueId, int messageId, String emoji) async {
    await _apiClient.post(
      '/leagues/$leagueId/chat/$messageId/reactions',
      body: {'emoji': emoji},
    );
  }

  Future<void> removeReaction(int leagueId, int messageId, String emoji) async {
    await _apiClient.delete(
      '/leagues/$leagueId/chat/$messageId/reactions',
      body: {'emoji': emoji},
    );
  }

  Future<void> markAsRead(int leagueId) async {
    await _apiClient.post('/leagues/$leagueId/chat/read');
  }

  Future<int> getUnreadCount(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/chat/unread');
    return response['unreadCount'] as int;
  }
}
