import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/conversation.dart';
import '../domain/direct_message.dart';

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DmRepository(apiClient);
});

class DmRepository {
  final ApiClient _apiClient;

  DmRepository(this._apiClient);

  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    final response = await _apiClient.get('/dm');
    return (response as List)
        .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get or create a conversation with another user
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    final response = await _apiClient.post('/dm/user/$otherUserId');
    return Conversation.fromJson(response as Map<String, dynamic>);
  }

  /// Get messages for a conversation
  Future<List<DirectMessage>> getMessages(int conversationId, {int? limit, int? before}) async {
    String path = '/dm/$conversationId/messages';
    final queryParams = <String>[];
    if (limit != null) queryParams.add('limit=$limit');
    if (before != null) queryParams.add('before=$before');
    if (queryParams.isNotEmpty) {
      path += '?${queryParams.join('&')}';
    }

    final response = await _apiClient.get(path);
    return (response as List)
        .map((json) => DirectMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Send a message in a conversation
  Future<DirectMessage> sendMessage(int conversationId, String message) async {
    final response = await _apiClient.post(
      '/dm/$conversationId/messages',
      body: {'message': message},
    );
    return DirectMessage.fromJson(response as Map<String, dynamic>);
  }

  /// Mark a conversation as read
  Future<void> markAsRead(int conversationId) async {
    await _apiClient.put('/dm/$conversationId/read');
  }

  /// Get total unread message count
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get('/dm/unread-count');
    return (response as Map<String, dynamic>)['unread_count'] as int? ?? 0;
  }
}
