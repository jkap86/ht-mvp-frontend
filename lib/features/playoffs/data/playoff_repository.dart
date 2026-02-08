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
  ///
  /// Optional parameters:
  /// - enableThirdPlaceGame: Enable 3rd place game
  /// - consolationType: 'NONE' or 'CONSOLATION'
  /// - consolationTeams: 4, 6, or 8 (null for auto)
  Future<PlayoffBracketView> generateBracket(
    int leagueId, {
    required int playoffTeams,
    required int startWeek,
    bool? enableThirdPlaceGame,
    String? consolationType,
    int? consolationTeams,
  }) async {
    final body = <String, dynamic>{
      'playoff_teams': playoffTeams,
      'start_week': startWeek,
    };

    if (enableThirdPlaceGame != null) {
      body['enable_third_place_game'] = enableThirdPlaceGame;
    }
    if (consolationType != null) {
      body['consolation_type'] = consolationType;
    }
    if (consolationTeams != null) {
      body['consolation_teams'] = consolationTeams;
    }

    final response = await _apiClient.post(
      '/leagues/$leagueId/playoffs/generate',
      body: body,
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
