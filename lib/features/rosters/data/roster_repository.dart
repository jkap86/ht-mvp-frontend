import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../players/domain/player.dart';
import '../domain/roster_player.dart';
import '../domain/roster_lineup.dart';

final rosterRepositoryProvider = Provider<RosterRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RosterRepository(apiClient);
});

class RosterRepository {
  final ApiClient _apiClient;

  RosterRepository(this._apiClient);

  /// Get all players on a roster with their details
  Future<List<RosterPlayer>> getRosterPlayers(int leagueId, int rosterId) async {
    final response = await _apiClient.get('/leagues/$leagueId/rosters/$rosterId/players');
    return ((response['players'] as List?) ?? []).map((json) => RosterPlayer.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Add a player to roster (free agency pickup)
  Future<RosterPlayer> addPlayer(int leagueId, int rosterId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/rosters/$rosterId/players',
      body: {'playerId': playerId},
    );
    return RosterPlayer.fromJson(response);
  }

  /// Drop a player from roster
  Future<void> dropPlayer(int leagueId, int rosterId, int playerId) async {
    await _apiClient.delete('/leagues/$leagueId/rosters/$rosterId/players/$playerId');
  }

  /// Add/drop players in a single transaction
  Future<RosterPlayer> addDropPlayer(
    int leagueId,
    int rosterId,
    int addPlayerId,
    int dropPlayerId,
  ) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/rosters/$rosterId/players/add-drop',
      body: {
        'addPlayerId': addPlayerId,
        'dropPlayerId': dropPlayerId,
      },
    );
    return RosterPlayer.fromJson(response);
  }

  /// Get free agents (players not on any roster in the league)
  Future<List<Player>> getFreeAgents(
    int leagueId, {
    String? position,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (position != null) queryParams['position'] = position;
    if (search != null) queryParams['search'] = search;

    final queryString = queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _apiClient.get('/leagues/$leagueId/free-agents?$queryString');
    return ((response['players'] as List?) ?? []).map((json) => Player.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get roster transactions history
  Future<List<RosterTransaction>> getTransactions(
    int leagueId,
    int rosterId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/rosters/$rosterId/transactions?limit=$limit&offset=$offset',
    );
    return ((response['transactions'] as List?) ?? []).map((json) => RosterTransaction.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get lineup for a specific week
  Future<RosterLineup> getLineup(int leagueId, int rosterId, int week) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/rosters/$rosterId/lineup?week=$week',
    );
    return RosterLineup.fromJson(response);
  }

  /// Set lineup for a specific week
  Future<RosterLineup> setLineup(
    int leagueId,
    int rosterId,
    int week,
    LineupSlots lineup,
  ) async {
    final response = await _apiClient.put(
      '/leagues/$leagueId/rosters/$rosterId/lineup',
      body: {
        'week': week,
        'lineup': lineup.toJson(),
      },
    );
    return RosterLineup.fromJson(response);
  }

  /// Move a player to a different slot
  Future<RosterLineup> movePlayer(
    int leagueId,
    int rosterId,
    int week,
    int playerId,
    String toSlot,
  ) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/rosters/$rosterId/lineup/move',
      body: {
        'week': week,
        'playerId': playerId,
        'toSlot': toSlot,
      },
    );
    return RosterLineup.fromJson(response);
  }
}
