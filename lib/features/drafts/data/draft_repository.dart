import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../leagues/domain/league.dart';

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DraftRepository(apiClient);
});

class DraftRepository {
  final ApiClient _apiClient;

  DraftRepository(this._apiClient);

  Future<Draft> getDraft(int leagueId, int draftId) async {
    final response = await _apiClient.get('/leagues/$leagueId/drafts/$draftId');
    return Draft.fromJson(response);
  }

  Future<Draft> startDraft(int leagueId, int draftId) async {
    final response =
        await _apiClient.post('/leagues/$leagueId/drafts/$draftId/start');
    return Draft.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getDraftPicks(
      int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/picks');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getDraftOrder(
      int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/order');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> makePick(
      int leagueId, int draftId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/pick',
      body: {'player_id': playerId},
    );
    return response as Map<String, dynamic>;
  }

  Future<void> randomizeDraftOrder(int leagueId, int draftId) async {
    await _apiClient.post('/leagues/$leagueId/drafts/$draftId/randomize-order');
  }

  // Queue methods
  Future<List<Map<String, dynamic>>> getQueue(int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/queue');
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> addToQueue(
      int leagueId, int draftId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'player_id': playerId},
    );
    return response as Map<String, dynamic>;
  }

  Future<void> removeFromQueue(int leagueId, int draftId, int playerId) async {
    await _apiClient.delete('/leagues/$leagueId/drafts/$draftId/queue/$playerId');
  }

  Future<List<Map<String, dynamic>>> reorderQueue(
      int leagueId, int draftId, List<int> playerIds) async {
    final response = await _apiClient.put(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'player_ids': playerIds},
    );
    return (response as List).cast<Map<String, dynamic>>();
  }
}
