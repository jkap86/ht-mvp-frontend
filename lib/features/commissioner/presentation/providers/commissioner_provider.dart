import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../../matchups/data/matchup_repository.dart';
import '../../../playoffs/data/playoff_repository.dart';
import '../../../playoffs/domain/playoff.dart';
import '../../../waivers/data/waiver_repository.dart';

/// Commissioner dashboard state
class CommissionerState {
  final League? league;
  final List<Map<String, dynamic>> members;
  final PlayoffBracketView? bracketView;
  final bool waiversInitialized;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String? successMessage;

  CommissionerState({
    this.league,
    this.members = const [],
    this.bracketView,
    this.waiversInitialized = false,
    this.isLoading = true,
    this.isProcessing = false,
    this.error,
    this.successMessage,
  });

  bool get hasPlayoffs => bracketView?.hasPlayoffs ?? false;

  CommissionerState copyWith({
    League? league,
    List<Map<String, dynamic>>? members,
    PlayoffBracketView? bracketView,
    bool? waiversInitialized,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearBracket = false,
  }) {
    return CommissionerState(
      league: league ?? this.league,
      members: members ?? this.members,
      bracketView: clearBracket ? null : (bracketView ?? this.bracketView),
      waiversInitialized: waiversInitialized ?? this.waiversInitialized,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Commissioner dashboard notifier
class CommissionerNotifier extends StateNotifier<CommissionerState> {
  final LeagueRepository _leagueRepo;
  final MatchupRepository _matchupRepo;
  final PlayoffRepository _playoffRepo;
  final WaiverRepository _waiverRepo;
  final int leagueId;

  CommissionerNotifier(
    this._leagueRepo,
    this._matchupRepo,
    this._playoffRepo,
    this._waiverRepo,
    this.leagueId,
  ) : super(CommissionerState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _leagueRepo.getLeague(leagueId),
        _leagueRepo.getMembers(leagueId),
        _playoffRepo.getBracket(leagueId),
      ]);

      state = state.copyWith(
        league: results[0] as League,
        members: results[1] as List<Map<String, dynamic>>,
        bracketView: results[2] as PlayoffBracketView?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> kickMember(int rosterId, String teamName) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _leagueRepo.kickMember(leagueId, rosterId);
      // Reload members
      final members = await _leagueRepo.getMembers(leagueId);
      state = state.copyWith(
        members: members,
        isProcessing: false,
        successMessage: '$teamName has been removed from the league',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> generateSchedule(int weeks) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _matchupRepo.generateSchedule(leagueId, weeks: weeks);
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Schedule generated for $weeks weeks',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> finalizeWeek(int week) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _matchupRepo.finalizeMatchups(leagueId, week);
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Week $week has been finalized',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> generatePlayoffBracket({
    required int playoffTeams,
    required int startWeek,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _playoffRepo.generateBracket(
        leagueId,
        playoffTeams: playoffTeams,
        startWeek: startWeek,
      );
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Playoff bracket generated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> advanceWinners(int week) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _playoffRepo.advanceWinners(leagueId, week);
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Winners advanced to next round',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> deleteLeague() async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _leagueRepo.deleteLeague(leagueId);
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'League deleted successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<bool> initializeWaivers({int? faabBudget}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _waiverRepo.initializeWaivers(leagueId, faabBudget: faabBudget);
      state = state.copyWith(
        waiversInitialized: true,
        isProcessing: false,
        successMessage: 'Waiver system initialized successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> processWaivers() async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final result = await _waiverRepo.processWaivers(leagueId);
      final processed = result['processed'] ?? 0;
      final successful = result['successful'] ?? 0;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Processed $processed claims ($successful successful)',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }
}

/// Provider for commissioner screen
final commissionerProvider = StateNotifierProvider.family<CommissionerNotifier, CommissionerState, int>(
  (ref, leagueId) => CommissionerNotifier(
    ref.watch(leagueRepositoryProvider),
    ref.watch(matchupRepositoryProvider),
    ref.watch(playoffRepositoryProvider),
    ref.watch(waiverRepositoryProvider),
    leagueId,
  ),
);
