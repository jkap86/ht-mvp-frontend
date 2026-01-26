import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/league.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LeagueRepository(apiClient);
});

class LeagueRepository {
  final ApiClient _apiClient;

  LeagueRepository(this._apiClient);

  Future<List<League>> getMyLeagues() async {
    final response = await _apiClient.get('/leagues/my-leagues');
    if (response is! List) return [];
    return response.map((json) => League.fromJson(json)).toList();
  }

  Future<League> getLeague(int id) async {
    final response = await _apiClient.get('/leagues/$id');
    return League.fromJson(response);
  }

  Future<League> createLeague({
    required String name,
    required String season,
    int totalRosters = 12,
    Map<String, dynamic>? scoringSettings,
    String? mode,
    Map<String, dynamic>? settings,
  }) async {
    final response = await _apiClient.post('/leagues', body: {
      'name': name,
      'season': season,
      'total_rosters': totalRosters,
      if (scoringSettings != null) 'scoring_settings': scoringSettings,
      if (mode != null) 'mode': mode,
      if (settings != null) 'settings': settings,
    });
    return League.fromJson(response);
  }

  Future<League> joinLeague(String inviteCode) async {
    final response = await _apiClient.post('/leagues/join/$inviteCode');
    return League.fromJson(response);
  }

  Future<List<Roster>> getLeagueMembers(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/members');
    if (response is! List) return [];
    return response.map((json) => Roster.fromJson(json)).toList();
  }

  Future<List<Draft>> getLeagueDrafts(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/drafts');
    if (response is! List) return [];
    return response.map((json) => Draft.fromJson(json)).toList();
  }

  Future<Draft> createDraft(int leagueId) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts');
    return Draft.fromJson(response);
  }

  Future<Draft> startDraft(int leagueId, int draftId) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts/$draftId/start');
    return Draft.fromJson(response);
  }

  /// Dev endpoint to add multiple users to a league
  Future<List<Map<String, dynamic>>> devAddUsersToLeague(
    int leagueId,
    List<String> usernames,
  ) async {
    final response = await _apiClient.post('/leagues/$leagueId/dev/add-users', body: {
      'usernames': usernames,
    });
    return (response['results'] as List).cast<Map<String, dynamic>>();
  }

  /// Get members as raw data (for commissioner screen)
  Future<List<Map<String, dynamic>>> getMembers(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/members');
    if (response is! List) return [];
    return response.cast<Map<String, dynamic>>();
  }

  /// Kick a member from the league (commissioner only)
  Future<void> kickMember(int leagueId, int rosterId) async {
    await _apiClient.delete('/leagues/$leagueId/members/$rosterId');
  }
}

// State management for leagues
class LeaguesState {
  final List<League> leagues;
  final bool isLoading;
  final String? error;

  LeaguesState({
    this.leagues = const [],
    this.isLoading = false,
    this.error,
  });

  LeaguesState copyWith({
    List<League>? leagues,
    bool? isLoading,
    String? error,
  }) {
    return LeaguesState(
      leagues: leagues ?? this.leagues,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LeaguesNotifier extends StateNotifier<LeaguesState> {
  final LeagueRepository _repository;

  LeaguesNotifier(this._repository) : super(LeaguesState());

  Future<void> loadLeagues() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final leagues = await _repository.getMyLeagues();
      state = state.copyWith(leagues: leagues, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createLeague({
    required String name,
    required String season,
    int totalRosters = 12,
    Map<String, dynamic>? scoringSettings,
    String? mode,
    Map<String, dynamic>? settings,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final league = await _repository.createLeague(
        name: name,
        season: season,
        totalRosters: totalRosters,
        scoringSettings: scoringSettings,
        mode: mode,
        settings: settings,
      );
      state = state.copyWith(
        leagues: [...state.leagues, league],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinLeague(String inviteCode) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final league = await _repository.joinLeague(inviteCode);
      state = state.copyWith(
        leagues: [...state.leagues, league],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final myLeaguesProvider = StateNotifierProvider<LeaguesNotifier, LeaguesState>((ref) {
  final repository = ref.watch(leagueRepositoryProvider);
  return LeaguesNotifier(repository);
});
