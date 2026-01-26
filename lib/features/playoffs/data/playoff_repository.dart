import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/playoff.dart';

final playoffRepositoryProvider = Provider<PlayoffRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlayoffRepository(apiClient);
});

class PlayoffRepository {
  final ApiClient _apiClient;

  PlayoffRepository(this._apiClient);

  /// Generate playoff bracket (commissioner only)
  Future<PlayoffBracketView> generateBracket(
    int leagueId, {
    required int playoffTeams,
    required int startWeek,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/playoffs/generate',
      body: {
        'playoff_teams': playoffTeams,
        'start_week': startWeek,
      },
    );
    return PlayoffBracketView.fromJson(response);
  }

  /// Get playoff bracket
  Future<PlayoffBracketView> getBracket(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/playoffs/bracket');
    return PlayoffBracketView.fromJson(response);
  }

  /// Advance winners (commissioner only)
  Future<PlayoffBracketView> advanceWinners(int leagueId, int week) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/playoffs/advance',
      body: {'week': week},
    );
    return PlayoffBracketView.fromJson(response);
  }
}
