import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/invalidation_service.dart';
import '../../../../core/idempotency/action_idempotency_provider.dart';
import '../../../../core/idempotency/action_ids.dart';
import '../../../../core/utils/error_sanitizer.dart';
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
  final ActionIdempotencyNotifier _idempotency;
  final int leagueId;

  CommissionerNotifier(
    this._repo,
    this._invalidationService,
    this._idempotency,
    this.leagueId,
  ) : super(CommissionerState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _repo.loadCommissionerData(leagueId);
      if (!mounted) return;

      state = state.copyWith(
        league: data.league,
        members: data.members,
        bracketView: data.bracketView,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  Future<bool> kickMember(int rosterId, String teamName, {String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.kickMember(leagueId, rosterId, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      // Reload members
      final members = await _repo.getMembers(leagueId);
      if (!mounted) return false;
      state = state.copyWith(
        members: members,
        isProcessing: false,
        successMessage: '$teamName has been removed from the league',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> generateSchedule(int weeks, {String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.generateSchedule(leagueId, weeks: weeks, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Schedule generated for $weeks weeks',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> finalizeWeek(int week, {String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.finalizeMatchups(leagueId, week, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Week $week has been finalized',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> generatePlayoffBracket({
    required int playoffTeams,
    required int startWeek,
    List<int>? weeksByRound,
    bool? enableThirdPlaceGame,
    String? consolationType,
    int? consolationTeams,
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _repo.generatePlayoffBracket(
        leagueId,
        playoffTeams: playoffTeams,
        startWeek: startWeek,
        weeksByRound: weeksByRound,
        enableThirdPlaceGame: enableThirdPlaceGame,
        consolationType: consolationType,
        consolationTeams: consolationTeams,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Playoff bracket generated successfully',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> advanceWinners(int week, {String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _repo.advanceWinners(leagueId, week, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Winners advanced to next round',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> deleteLeague({required String confirmationName, String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.deleteLeague(leagueId, confirmationName: confirmationName, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'League deleted successfully',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> updateSeasonControls({String? seasonStatus, int? currentWeek, String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final updatedLeague = await _repo.updateSeasonControls(
        leagueId,
        seasonStatus: seasonStatus,
        currentWeek: currentWeek,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        league: updatedLeague,
        isProcessing: false,
        successMessage: 'Season controls updated successfully',
      );
      await _invalidationService.invalidateType(InvalidationType.leagueDetail, leagueId);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
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
    String? idempotencyKey,
  }) async {
    final actionId = ActionIds.commishSave(leagueId, {
      if (name != null) 'name': name,
      if (mode != null) 'mode': mode,
      if (settings != null) 'settings': settings,
      if (leagueSettings != null) 'leagueSettings': leagueSettings,
      if (scoringSettings != null) 'scoringSettings': scoringSettings,
    });
    if (_idempotency.isInFlight(actionId)) return false;

    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final updatedLeague = await _idempotency.run(
        actionId: actionId,
        op: (key) => _repo.updateLeague(
          leagueId,
          name: name,
          mode: mode,
          isPublic: isPublic,
          settings: settings,
          leagueSettings: leagueSettings,
          scoringSettings: scoringSettings,
          totalRosters: totalRosters,
          idempotencyKey: key,
        ),
      );
      if (!mounted) return false;
      if (updatedLeague == null) {
        state = state.copyWith(isProcessing: false);
        return false;
      }
      // Reload members to reflect benching changes
      final members = await _repo.getMembers(leagueId);
      if (!mounted) return false;
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
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> reinstateMember(int rosterId, String teamName, {String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.reinstateMember(leagueId, rosterId, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      // Reload members
      final members = await _repo.getMembers(leagueId);
      if (!mounted) return false;
      state = state.copyWith(
        members: members,
        isProcessing: false,
        successMessage: '$teamName has been reinstated',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
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
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.resetLeague(
        leagueId,
        newSeason: newSeason,
        confirmationName: confirmationName,
        keepMembers: keepMembers,
        clearChat: clearChat,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'League reset for $newSeason season',
      );
      await loadData();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> initializeWaivers({int? faabBudget, String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _repo.initializeWaivers(leagueId, faabBudget: faabBudget, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        waiversInitialized: true,
        isProcessing: false,
        successMessage: 'Waiver system initialized successfully',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> processWaivers({String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final result = await _repo.processWaivers(leagueId, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      final processed = result['processed'] ?? 0;
      final successful = result['successful'] ?? 0;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Processed $processed claims ($successful successful)',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<int?> startMatchupsDraft({
    required int weeks,
    required int pickTimeSeconds,
    required bool randomizeDraftOrder,
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final draftId = await _repo.createMatchupsDraft(
        leagueId,
        weeks: weeks,
        pickTimeSeconds: pickTimeSeconds,
        randomizeDraftOrder: randomizeDraftOrder,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return null;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Matchups draft created successfully',
      );
      return draftId;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return null;
    }
  }
}

/// Provider for commissioner screen
final commissionerProvider = StateNotifierProvider.autoDispose.family<CommissionerNotifier, CommissionerState, int>(
  (ref, leagueId) => CommissionerNotifier(
    ref.watch(commissionerRepositoryProvider),
    ref.watch(invalidationServiceProvider),
    ref.read(actionIdempotencyProvider.notifier),
    leagueId,
  ),
);
