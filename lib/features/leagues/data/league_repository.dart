import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/league.dart';
import '../domain/invitation.dart';

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LeagueRepository(apiClient);
});

class LeagueRepository {
  final ApiClient _apiClient;

  LeagueRepository(this._apiClient);

  Future<List<League>> getMyLeagues() async {
    final response = await _apiClient.get('/leagues/my-leagues');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of leagues', 500);
    }
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
    bool isPublic = false,
  }) async {
    final response = await _apiClient.post('/leagues', body: {
      'name': name,
      'season': season,
      'total_rosters': totalRosters,
      'is_public': isPublic,
      if (scoringSettings != null) 'scoring_settings': scoringSettings,
      if (mode != null) 'mode': mode,
      if (settings != null) 'settings': settings,
    });
    return League.fromJson(response);
  }

  /// Discover public leagues available to join
  Future<List<PublicLeague>> discoverPublicLeagues() async {
    final response = await _apiClient.get('/leagues/discover');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of leagues', 500);
    }
    return response.map((json) => PublicLeague.fromJson(json)).toList();
  }

  /// Join a public league by its ID
  Future<League> joinPublicLeague(int leagueId) async {
    final response = await _apiClient.post('/leagues/$leagueId/join');
    return League.fromJson(response);
  }

  Future<League> joinLeague(String inviteCode) async {
    final response = await _apiClient.post('/leagues/join/$inviteCode');
    return League.fromJson(response);
  }

  Future<List<Roster>> getLeagueMembers(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/members');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of members', 500);
    }
    return response.map((json) => Roster.fromJson(json)).toList();
  }

  Future<List<Draft>> getLeagueDrafts(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/drafts');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of drafts', 500);
    }
    return response.map((json) => Draft.fromJson(json)).toList();
  }

  Future<Draft> createDraft(
    int leagueId, {
    String draftType = 'snake',
    int rounds = 15,
    int pickTimeSeconds = 90,
    Map<String, dynamic>? settings,
    List<String>? playerPool,
  }) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts', body: {
      'draft_type': draftType,
      'rounds': rounds,
      'pick_time_seconds': pickTimeSeconds,
      if (settings != null) 'auction_settings': settings,
      if (playerPool != null) 'player_pool': playerPool,
    });
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
    if (response is! List) {
      throw ApiException('Invalid response: expected list of members', 500);
    }
    return response.cast<Map<String, dynamic>>();
  }

  /// Kick a member from the league (commissioner only)
  Future<void> kickMember(int leagueId, int rosterId) async {
    await _apiClient.delete('/leagues/$leagueId/members/$rosterId');
  }

  /// Delete league (commissioner only)
  Future<void> deleteLeague(int leagueId) async {
    await _apiClient.delete('/leagues/$leagueId');
  }

  /// Reset league for new season (commissioner only)
  Future<League> resetLeague(
    int leagueId, {
    required String newSeason,
    required String confirmationName,
    bool keepMembers = false,
    bool clearChat = true,
  }) async {
    final response = await _apiClient.post('/leagues/$leagueId/reset', body: {
      'new_season': newSeason,
      'keep_members': keepMembers,
      'clear_chat': clearChat,
      'confirmation_name': confirmationName,
    });
    return League.fromJson(response);
  }

  // ============= Invitation Methods =============

  /// Get pending invitations for the current user
  Future<List<LeagueInvitation>> getPendingInvitations() async {
    final response = await _apiClient.get('/invitations/pending');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of invitations', 500);
    }
    return response.map((json) => LeagueInvitation.fromJson(json)).toList();
  }

  /// Accept an invitation and join the league
  Future<League> acceptInvitation(int invitationId) async {
    final response = await _apiClient.post('/invitations/$invitationId/accept');
    return League.fromJson(response['league']);
  }

  /// Decline an invitation
  Future<void> declineInvitation(int invitationId) async {
    await _apiClient.post('/invitations/$invitationId/decline');
  }

  /// Send an invitation (commissioner only)
  Future<LeagueInvitation> sendInvitation(
    int leagueId,
    String username, {
    String? message,
  }) async {
    final response = await _apiClient.post('/leagues/$leagueId/invitations', body: {
      'username': username,
      if (message != null && message.isNotEmpty) 'message': message,
    });
    return LeagueInvitation.fromJson(response);
  }

  /// Get pending invitations for a league (commissioner only)
  Future<List<Map<String, dynamic>>> getLeagueInvitations(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/invitations');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of invitations', 500);
    }
    return response.cast<Map<String, dynamic>>();
  }

  /// Cancel an invitation (commissioner only)
  Future<void> cancelInvitation(int invitationId) async {
    await _apiClient.delete('/invitations/$invitationId');
  }

  /// Search users for inviting (commissioner only)
  Future<List<UserSearchResult>> searchUsersForInvite(int leagueId, String query) async {
    final encodedQuery = Uri.encodeQueryComponent(query);
    final response = await _apiClient.get('/leagues/$leagueId/users/search?q=$encodedQuery');
    if (response is! List) {
      throw ApiException('Invalid response: expected list of users', 500);
    }
    return response.map((json) => UserSearchResult.fromJson(json)).toList();
  }

  /// Get NFL state from Sleeper API (includes league_create_season)
  Future<Map<String, dynamic>> getNflState() async {
    final response = await _apiClient.get('/players/nfl-state');
    return response as Map<String, dynamic>;
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
    bool isPublic = false,
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
        isPublic: isPublic,
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
