import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/player.dart';

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlayerRepository(apiClient);
});

class PlayerRepository {
  final ApiClient _apiClient;

  PlayerRepository(this._apiClient);

  Future<List<Player>> getPlayers({
    String? search,
    String? position,
    String? team,
    String? playerType,
    List<String>? playerPool,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['q'] = search;
    if (position != null && position.isNotEmpty) queryParams['position'] = position;
    if (team != null && team.isNotEmpty) queryParams['team'] = team;
    if (playerType != null && playerType.isNotEmpty) queryParams['playerType'] = playerType;
    if (playerPool != null && playerPool.isNotEmpty) queryParams['playerPool'] = playerPool.join(',');

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _apiClient.get('/players$queryString');
    return (response as List).map((json) => Player.fromJson(json)).toList();
  }

  Future<Player> getPlayer(int id) async {
    final response = await _apiClient.get('/players/$id');
    return Player.fromJson(response);
  }

  Future<void> syncPlayers() async {
    await _apiClient.post('/players/sync');
  }

  Future<Map<String, dynamic>> makeDraftPick(int leagueId, int draftId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/pick',
      body: {'player_id': playerId},
    );
    return response as Map<String, dynamic>;
  }
}
