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
  }) async {
    final queryParts = <String>['limit=$limit'];
    if (before != null) {
      queryParts.add('before=$before');
    }
    final queryString = queryParts.join('&');

    final response = await _apiClient.get('/leagues/$leagueId/chat?$queryString');
    return (response as List)
        .map((json) => ChatMessage.fromJson(json))
        .toList();
  }

  Future<void> sendMessage(int leagueId, String message) async {
    await _apiClient.post(
      '/leagues/$leagueId/chat',
      body: {'message': message},
    );
  }
}
