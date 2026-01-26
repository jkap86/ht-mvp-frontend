import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/league.dart';
import 'league_repository.dart';

/// State for public leagues discovery
class PublicLeaguesState {
  final List<PublicLeague> leagues;
  final bool isLoading;
  final String? error;
  final int? joiningLeagueId;

  PublicLeaguesState({
    this.leagues = const [],
    this.isLoading = false,
    this.error,
    this.joiningLeagueId,
  });

  PublicLeaguesState copyWith({
    List<PublicLeague>? leagues,
    bool? isLoading,
    String? error,
    int? joiningLeagueId,
    bool clearJoining = false,
  }) {
    return PublicLeaguesState(
      leagues: leagues ?? this.leagues,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      joiningLeagueId: clearJoining ? null : (joiningLeagueId ?? this.joiningLeagueId),
    );
  }
}

/// Notifier for public leagues discovery
class PublicLeaguesNotifier extends StateNotifier<PublicLeaguesState> {
  final LeagueRepository _repository;

  PublicLeaguesNotifier(this._repository) : super(PublicLeaguesState());

  /// Load public leagues available for discovery
  Future<void> loadPublicLeagues() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final leagues = await _repository.discoverPublicLeagues();
      state = state.copyWith(leagues: leagues, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Join a public league
  Future<League?> joinLeague(int leagueId) async {
    state = state.copyWith(joiningLeagueId: leagueId, error: null);
    try {
      final league = await _repository.joinPublicLeague(leagueId);
      // Remove the joined league from the list
      final updatedLeagues = state.leagues.where((l) => l.id != leagueId).toList();
      state = state.copyWith(
        leagues: updatedLeagues,
        clearJoining: true,
      );
      return league;
    } catch (e) {
      state = state.copyWith(error: e.toString(), clearJoining: true);
      return null;
    }
  }
}

/// Provider for public leagues discovery
final publicLeaguesProvider =
    StateNotifierProvider<PublicLeaguesNotifier, PublicLeaguesState>((ref) {
  final repository = ref.watch(leagueRepositoryProvider);
  return PublicLeaguesNotifier(repository);
});
