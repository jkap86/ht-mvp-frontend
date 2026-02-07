import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/invalidation_service.dart';
import '../../data/commissioner_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../../playoffs/domain/playoff.dart';

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
  final CommissionerRepository _repo;
  final InvalidationService _invalidationService;
  final int leagueId;

  CommissionerNotifier(
    this._repo,
    this._invalidationService,
    this.leagueId,
  ) : super(CommissionerState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _repo.loadCommissionerData(leagueId);

      state = state.copyWith(
        league: data.league,
        members: data.members,
        bracketView: data.bracketView,
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
      await _repo.kickMember(leagueId, rosterId);
      // Reload members
      final members = await _repo.getMembers(leagueId);
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
      await _repo.generateSchedule(leagueId, weeks: weeks);
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
      await _repo.finalizeMatchups(leagueId, week);
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
      final bracketView = await _repo.generatePlayoffBracket(
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
      final bracketView = await _repo.advanceWinners(leagueId, week);
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
      await _repo.deleteLeague(leagueId);
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

  Future<bool> updateLeague({
    String? name,
    String? mode,
    bool? isPublic,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? leagueSettings,
    Map<String, dynamic>? scoringSettings,
    int? totalRosters,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final updatedLeague = await _repo.updateLeague(
        leagueId,
        name: name,
        mode: mode,
        isPublic: isPublic,
        settings: settings,
        leagueSettings: leagueSettings,
        scoringSettings: scoringSettings,
        totalRosters: totalRosters,
      );
      // Reload members to reflect benching changes
      final members = await _repo.getMembers(leagueId);
      state = state.copyWith(
        league: updatedLeague,
        members: members,
        isProcessing: false,
        successMessage: 'League settings updated successfully',
      );
      // Notify other providers that league data changed
      await _invalidationService.invalidateType(InvalidationType.leagueDetail, leagueId);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> reinstateMember(int rosterId, String teamName) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.reinstateMember(leagueId, rosterId);
      // Reload members
      final members = await _repo.getMembers(leagueId);
      state = state.copyWith(
        members: members,
        isProcessing: false,
        successMessage: '$teamName has been reinstated',
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

  Future<bool> resetLeague({
    required String newSeason,
    required String confirmationName,
    bool keepMembers = false,
    bool clearChat = true,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.resetLeague(
        leagueId,
        newSeason: newSeason,
        confirmationName: confirmationName,
        keepMembers: keepMembers,
        clearChat: clearChat,
      );
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'League reset for $newSeason season',
      );
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> initializeWaivers({int? faabBudget}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.initializeWaivers(leagueId, faabBudget: faabBudget);
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
      final result = await _repo.processWaivers(leagueId);
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
final commissionerProvider = StateNotifierProvider.autoDispose.family<CommissionerNotifier, CommissionerState, int>(
  (ref, leagueId) => CommissionerNotifier(
    ref.watch(commissionerRepositoryProvider),
    ref.watch(invalidationServiceProvider),
    leagueId,
  ),
);
