import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/matchup.dart';

final matchupRepositoryProvider = Provider<MatchupRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchupRepository(apiClient);
});

class MatchupRepository {
  final ApiClient _apiClient;

  MatchupRepository(this._apiClient);

  /// Get all matchups for a specific week
  Future<List<Matchup>> getMatchups(int leagueId, {int? week, int? season}) async {
    final queryParams = <String, String>{};
    if (week != null) queryParams['week'] = week.toString();
    if (season != null) queryParams['season'] = season.toString();

    final queryString = queryParams.isNotEmpty
        ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';

    final response = await _apiClient.get('/leagues/$leagueId/matchups$queryString');
    return ((response['matchups'] as List?) ?? [])
        .map((json) => Matchup.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific matchup (basic, without lineup details)
  /// Use getMatchupWithLineups() for full team lineup information
  Future<Matchup> getMatchupBasic(int leagueId, int matchupId) async {
    final response = await _apiClient.get('/leagues/$leagueId/matchups/$matchupId');
    return Matchup.fromJson(response['matchup'] ?? response);
  }

  /// Get a matchup with full lineup details
  Future<MatchupDetails> getMatchupWithLineups(int leagueId, int matchupId) async {
    final response = await _apiClient.get('/leagues/$leagueId/matchups/$matchupId/detail');
    return MatchupDetails.fromJson(response['matchup'] ?? response);
  }

  /// Get league standings
  Future<List<Standing>> getStandings(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/standings');
    return ((response['standings'] as List?) ?? [])
        .map((json) => Standing.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Generate season schedule (commissioner only)
  Future<void> generateSchedule(int leagueId, {int weeks = 14}) async {
    await _apiClient.post(
      '/leagues/$leagueId/schedule/generate',
      body: {'weeks': weeks},
    );
  }

  /// Finalize matchups for a week (commissioner only)
  Future<void> finalizeMatchups(int leagueId, int week) async {
    await _apiClient.post(
      '/leagues/$leagueId/matchups/finalize',
      body: {'week': week},
    );
  }

  /// Get scoring rules for the league
  Future<Map<String, dynamic>> getScoringRules(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/scoring/rules');
    return response as Map<String, dynamic>;
  }

  /// Get the maximum scheduled week for the league
  Future<int> getMaxScheduledWeek(int leagueId) async {
    // Fetch all matchups (without week filter) to find max week
    final response = await _apiClient.get('/leagues/$leagueId/matchups');
    final matchups = ((response['matchups'] as List?) ?? [])
        .map((json) => Matchup.fromJson(json as Map<String, dynamic>))
        .toList();

    if (matchups.isEmpty) return 0; // No schedule yet - let caller use league.totalWeeks

    return matchups.map((m) => m.week).reduce((a, b) => a > b ? a : b);
  }
}
