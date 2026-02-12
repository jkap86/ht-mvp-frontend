import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/player.dart';

/// Result of a player fetch operation, bundling data with freshness metadata.
///
/// Since the backend does not include update timestamps in player API responses,
/// and real-time news push/socket events are not yet implemented, this wrapper
/// tracks when data was fetched client-side so consumers can display freshness
/// indicators (e.g. "Updated 3 min ago" or "Refresh to update").
class PlayerFetchResult {
  final List<Player> players;

  /// When this data was fetched from the server.
  final DateTime fetchedAt;

  const PlayerFetchResult({
    required this.players,
    required this.fetchedAt,
  });

  /// Whether the data is considered stale (older than [threshold]).
  bool isStale({Duration threshold = const Duration(minutes: 5)}) {
    return DateTime.now().difference(fetchedAt) > threshold;
  }

  /// Human-readable freshness label for display.
  /// Returns strings like "Just now", "2 min ago", "1 hr ago", or "Refresh to update".
  String get freshnessLabel {
    final elapsed = DateTime.now().difference(fetchedAt);
    if (elapsed.inSeconds < 30) return 'Just now';
    if (elapsed.inMinutes < 1) return '${elapsed.inSeconds}s ago';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';
    return 'Refresh to update';
  }
}

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlayerRepository(apiClient);
});

class PlayerRepository {
  final ApiClient _apiClient;

  /// Tracks when player list data was last fetched from the server.
  DateTime? _lastPlayersFetchedAt;

  /// Tracks when individual player data was last fetched, keyed by player ID.
  final Map<int, DateTime> _lastPlayerFetchedAt = {};

  PlayerRepository(this._apiClient);

  /// When the most recent [getPlayers] call completed, or null if never fetched.
  DateTime? get lastPlayersFetchedAt => _lastPlayersFetchedAt;

  /// When a specific player was last fetched via [getPlayer], or null if never fetched.
  DateTime? lastPlayerFetchedAt(int playerId) => _lastPlayerFetchedAt[playerId];

  /// Fetch players with search/filter parameters.
  ///
  /// Note: The backend does not include freshness timestamps in player responses.
  /// Real-time news push via sockets is TODO on the backend. Use [getPlayersWithFreshness]
  /// to get a [PlayerFetchResult] that includes a client-side fetch timestamp.
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
    final players = (response as List).map((json) => Player.fromJson(json)).toList();
    _lastPlayersFetchedAt = DateTime.now();
    return players;
  }

  /// Fetch players and return a [PlayerFetchResult] with freshness metadata.
  ///
  /// This is the preferred method for UI code that needs to display
  /// "last updated" timestamps alongside player data.
  Future<PlayerFetchResult> getPlayersWithFreshness({
    String? search,
    String? position,
    String? team,
    String? playerType,
    List<String>? playerPool,
  }) async {
    final players = await getPlayers(
      search: search,
      position: position,
      team: team,
      playerType: playerType,
      playerPool: playerPool,
    );
    return PlayerFetchResult(
      players: players,
      fetchedAt: _lastPlayersFetchedAt!,
    );
  }

  /// Fetch a single player by ID.
  ///
  /// Note: The backend does not include freshness timestamps in player responses.
  /// Real-time news push via sockets is TODO on the backend.
  Future<Player> getPlayer(int id) async {
    final response = await _apiClient.get('/players/$id');
    final player = Player.fromJson(response);
    _lastPlayerFetchedAt[id] = DateTime.now();
    return player;
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
