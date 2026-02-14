import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../drafts/domain/draft_order_entry.dart';
import '../../../drafts/domain/draft_status.dart';
import '../../../drafts/domain/draft_type.dart';
import '../../../drafts/data/draft_repository.dart';
import '../../../matchups/domain/matchup.dart';
import '../../../matchups/data/matchup_repository.dart';
import '../../../rosters/domain/roster_player.dart';
import '../../../rosters/domain/roster_lineup.dart';
import '../../../rosters/data/roster_repository.dart';
import '../../data/league_repository.dart';
import '../../domain/league.dart';

class LeagueDetailState {
  final League? league;
  final List<Roster> members;
  final List<Draft> drafts;
  final Matchup? currentMatchup;
  final List<Standing> standings;
  final List<RosterPlayer> rosterPlayers;
  final RosterLineup? currentLineup;
  final bool isLoading;
  final String? error;
  final bool isForbidden;

  LeagueDetailState({
    this.league,
    this.members = const [],
    this.drafts = const [],
    this.currentMatchup,
    this.standings = const [],
    this.rosterPlayers = const [],
    this.currentLineup,
    this.isLoading = true,
    this.error,
    this.isForbidden = false,
  });

  bool get isCommissioner {
    final l = league;
    if (l == null) return false;
    return l.userRosterId == l.commissionerRosterId;
  }

  Draft? get activeDraft {
    try {
      return drafts.firstWhere(
        (d) => d.status == DraftStatus.inProgress || d.status == DraftStatus.notStarted,
      );
    } catch (_) {
      return null;
    }
  }

  String get draftTypeLabel {
    if (drafts.isEmpty) return 'Snake';
    return drafts.first.draftType.label;
  }

  /// Get the user's standing from the standings list
  Standing? get userStanding {
    if (league?.userRosterId == null || standings.isEmpty) return null;
    return standings.where((s) => s.rosterId == league!.userRosterId).firstOrNull;
  }

  /// Get the opponent's standing from current matchup
  Standing? get opponentStanding {
    if (league?.userRosterId == null || currentMatchup == null || standings.isEmpty) return null;
    final opponentId = currentMatchup!.opponentId(league!.userRosterId!);
    if (opponentId == null) return null;
    return standings.where((s) => s.rosterId == opponentId).firstOrNull;
  }

  /// Get starters from roster players based on current lineup
  List<RosterPlayer> get starters {
    if (currentLineup == null) return [];
    return rosterPlayers.where((p) => currentLineup!.lineup.isStarter(p.playerId)).toList();
  }

  /// Check if the league is in season (has matchups)
  bool get isInSeason {
    final status = league?.seasonStatus;
    return status == SeasonStatus.regularSeason || status == SeasonStatus.playoffs;
  }

  LeagueDetailState copyWith({
    League? league,
    List<Roster>? members,
    List<Draft>? drafts,
    Matchup? currentMatchup,
    List<Standing>? standings,
    List<RosterPlayer>? rosterPlayers,
    RosterLineup? currentLineup,
    bool? isLoading,
    String? error,
    bool? isForbidden,
    bool clearError = false,
    bool clearMatchup = false,
    bool clearLineup = false,
  }) {
    return LeagueDetailState(
      league: league ?? this.league,
      members: members ?? this.members,
      drafts: drafts ?? this.drafts,
      currentMatchup: clearMatchup ? null : (currentMatchup ?? this.currentMatchup),
      standings: standings ?? this.standings,
      rosterPlayers: rosterPlayers ?? this.rosterPlayers,
      currentLineup: clearLineup ? null : (currentLineup ?? this.currentLineup),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class LeagueDetailNotifier extends StateNotifier<LeagueDetailState> {
  final LeagueRepository _leagueRepo;
  final DraftRepository _draftRepo;
  final MatchupRepository _matchupRepo;
  final RosterRepository _rosterRepo;
  final SocketService _socketService;
  final InvalidationService _invalidationService;
  final int leagueId;
  VoidCallback? _memberJoinedDisposer;
  VoidCallback? _memberKickedDisposer;
  VoidCallback? _memberBenchedDisposer;
  VoidCallback? _draftCreatedDisposer;
  VoidCallback? _leagueSettingsDisposer;
  VoidCallback? _seasonRolledOverDisposer;
  VoidCallback? _invalidationDisposer;
  VoidCallback? _reconnectDisposer;

  LeagueDetailNotifier(this._leagueRepo, this._draftRepo, this._matchupRepo, this._rosterRepo, this._socketService, this._invalidationService, this.leagueId) : super(LeagueDetailState()) {
    _setupSocketListeners();
    _registerInvalidationCallback();
    loadData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.leagueDetail,
      leagueId,
      loadData,
    );
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);
    _memberJoinedDisposer = _socketService.onMemberJoined((data) {
      if (!mounted) return;
      _refreshMembers();
    });
    _memberKickedDisposer = _socketService.onMemberKicked((data) {
      if (!mounted) return;
      _refreshMembers();
    });
    _memberBenchedDisposer = _socketService.onMemberBenched((data) {
      if (!mounted) return;
      _refreshMembers();
    });
    _draftCreatedDisposer = _socketService.onDraftCreated((data) {
      if (!mounted) return;
      _refreshDrafts();
    });
    _leagueSettingsDisposer = _socketService.onLeagueSettingsUpdated((data) {
      if (!mounted) return;
      loadData(); // Full refresh when settings change
    });
    _seasonRolledOverDisposer = _socketService.onSeasonRolledOver((data) {
      if (!mounted) return;
      // Season rollover changes everything - invalidate all caches and full refresh
      _invalidationService.invalidate(InvalidationEvent.seasonRolledOver, leagueId);
      loadData();
    });

    // Resync league detail on socket reconnection
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('LeagueDetail($leagueId): Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      // Always reload on reconnect -- members, drafts, standings may have changed
      loadData();
    });
  }

  Future<void> _refreshMembers() async {
    try {
      final members = await _leagueRepo.getLeagueMembers(leagueId);
      state = state.copyWith(members: members);
    } on ForbiddenException {
      state = state.copyWith(isForbidden: true, isLoading: false, members: [], drafts: [], standings: []);
    } catch (_) {}
  }

  Future<void> _refreshDrafts() async {
    try {
      final drafts = await _leagueRepo.getLeagueDrafts(leagueId);
      state = state.copyWith(drafts: drafts);
    } on ForbiddenException {
      state = state.copyWith(isForbidden: true, isLoading: false, members: [], drafts: [], standings: []);
    } catch (_) {}
  }

  @override
  void dispose() {
    _memberJoinedDisposer?.call();
    _memberKickedDisposer?.call();
    _memberBenchedDisposer?.call();
    _draftCreatedDisposer?.call();
    _leagueSettingsDisposer?.call();
    _seasonRolledOverDisposer?.call();
    _invalidationDisposer?.call();
    _reconnectDisposer?.call();
    _socketService.leaveLeague(leagueId);
    super.dispose();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // First load basic league data
      final results = await Future.wait([
        _leagueRepo.getLeague(leagueId),
        _leagueRepo.getLeagueMembers(leagueId),
        _leagueRepo.getLeagueDrafts(leagueId),
      ]);

      final league = results[0] as League;
      final members = results[1] as List<Roster>;
      final drafts = results[2] as List<Draft>;

      // Load in-season data if applicable
      Matchup? currentMatchup;
      List<Standing> standings = [];
      List<RosterPlayer> rosterPlayers = [];
      RosterLineup? currentLineup;

      final isInSeason = league.seasonStatus == SeasonStatus.regularSeason ||
          league.seasonStatus == SeasonStatus.playoffs;

      if (isInSeason && league.userRosterId != null) {
        // Load matchup and standings in parallel
        final inSeasonResults = await Future.wait([
          _matchupRepo.getMatchups(leagueId, week: league.currentWeek),
          _matchupRepo.getStandings(leagueId),
          _rosterRepo.getRosterPlayers(leagueId, league.userRosterId!),
          _loadLineupSafe(leagueId, league.userRosterId!, league.currentWeek),
        ]);

        final matchups = inSeasonResults[0] as List<Matchup>;
        standings = inSeasonResults[1] as List<Standing>;
        rosterPlayers = inSeasonResults[2] as List<RosterPlayer>;
        currentLineup = inSeasonResults[3] as RosterLineup?;

        // Find user's matchup
        currentMatchup = matchups.where((m) =>
            m.roster1Id == league.userRosterId ||
            m.roster2Id == league.userRosterId).firstOrNull;
      }

      state = state.copyWith(
        league: league,
        members: members,
        drafts: drafts,
        currentMatchup: currentMatchup,
        standings: standings,
        rosterPlayers: rosterPlayers,
        currentLineup: currentLineup,
        isLoading: false,
        clearMatchup: currentMatchup == null,
        clearLineup: currentLineup == null,
      );
    } on ForbiddenException {
      state = state.copyWith(isForbidden: true, isLoading: false, members: [], drafts: [], standings: []);
    } catch (e) {
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  Future<RosterLineup?> _loadLineupSafe(int leagueId, int rosterId, int week) async {
    try {
      return await _rosterRepo.getLineup(leagueId, rosterId, week);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createDraft({
    String draftType = 'snake',
    int rounds = 15,
    int pickTimeSeconds = 90,
    Map<String, dynamic>? settings,
    List<String>? playerPool,
    DateTime? scheduledStart,
    String? idempotencyKey,
  }) async {
    try {
      final draft = await _leagueRepo.createDraft(
        leagueId,
        draftType: draftType,
        rounds: rounds,
        pickTimeSeconds: pickTimeSeconds,
        settings: settings,
        playerPool: playerPool,
        scheduledStart: scheduledStart,
        idempotencyKey: idempotencyKey,
      );
      state = state.copyWith(drafts: [...state.drafts, draft]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startDraft(int draftId, {String? idempotencyKey}) async {
    try {
      final updatedDraft = await _leagueRepo.startDraft(leagueId, draftId, idempotencyKey: idempotencyKey);
      final index = state.drafts.indexWhere((d) => d.id == draftId);
      if (index != -1) {
        final updatedDrafts = [...state.drafts];
        updatedDrafts[index] = updatedDraft;
        state = state.copyWith(drafts: updatedDrafts);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<DraftOrderEntry>?> randomizeDraftOrder(int draftId, {String? idempotencyKey}) async {
    try {
      final order = await _draftRepo.randomizeDraftOrder(leagueId, draftId, idempotencyKey: idempotencyKey);
      // Update the draft to mark orderConfirmed as true
      final index = state.drafts.indexWhere((d) => d.id == draftId);
      if (index != -1) {
        final updatedDrafts = [...state.drafts];
        updatedDrafts[index] = updatedDrafts[index].copyWith(orderConfirmed: true);
        state = state.copyWith(drafts: updatedDrafts);
      }
      return order;
    } catch (e) {
      return null;
    }
  }

  Future<List<DraftOrderEntry>?> setOrderFromPickOwnership(int draftId, {String? idempotencyKey}) async {
    try {
      final order = await _draftRepo.setOrderFromPickOwnership(leagueId, draftId, idempotencyKey: idempotencyKey);
      // Update the draft to mark orderConfirmed as true
      final index = state.drafts.indexWhere((d) => d.id == draftId);
      if (index != -1) {
        final updatedDrafts = [...state.drafts];
        updatedDrafts[index] = updatedDrafts[index].copyWith(orderConfirmed: true);
        state = state.copyWith(drafts: updatedDrafts);
      }
      return order;
    } catch (e) {
      return null;
    }
  }

  /// Update draft settings (commissioner only)
  Future<bool> updateDraftSettings(
    int draftId, {
    String? draftType,
    int? rounds,
    int? pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
    List<String>? playerPool,
    DateTime? scheduledStart,
    bool? includeRookiePicks,
    int? rookiePicksSeason,
    int? rookiePicksRounds,
    bool? overnightPauseEnabled,
    String? overnightPauseStart,
    String? overnightPauseEnd,
    String? timerMode,
    int? chessClockTotalSeconds,
    int? chessClockMinPickSeconds,
    String? idempotencyKey,
  }) async {
    try {
      final updatedDraft = await _draftRepo.updateDraftSettings(
        leagueId,
        draftId,
        draftType: draftType,
        rounds: rounds,
        pickTimeSeconds: pickTimeSeconds,
        auctionSettings: auctionSettings,
        playerPool: playerPool,
        scheduledStart: scheduledStart,
        clearScheduledStart: scheduledStart == null && draftType == null && rounds == null && pickTimeSeconds == null && auctionSettings == null && playerPool == null && includeRookiePicks == null && rookiePicksSeason == null && rookiePicksRounds == null && overnightPauseEnabled == null && overnightPauseStart == null && overnightPauseEnd == null && timerMode == null && chessClockTotalSeconds == null && chessClockMinPickSeconds == null,
        includeRookiePicks: includeRookiePicks,
        rookiePicksSeason: rookiePicksSeason,
        rookiePicksRounds: rookiePicksRounds,
        overnightPauseEnabled: overnightPauseEnabled,
        overnightPauseStart: overnightPauseStart,
        overnightPauseEnd: overnightPauseEnd,
        timerMode: timerMode,
        chessClockTotalSeconds: chessClockTotalSeconds,
        chessClockMinPickSeconds: chessClockMinPickSeconds,
        idempotencyKey: idempotencyKey,
      );
      // Update the draft in state
      final index = state.drafts.indexWhere((d) => d.id == draftId);
      if (index != -1) {
        final updatedDrafts = [...state.drafts];
        updatedDrafts[index] = updatedDraft;
        // Re-sort drafts: scheduled first (by date), then unscheduled
        updatedDrafts.sort((a, b) {
          final aScheduled = a.scheduledStart;
          final bScheduled = b.scheduledStart;
          if (aScheduled != null && bScheduled != null) {
            return aScheduled.compareTo(bScheduled);
          }
          if (aScheduled != null) return -1;
          if (bScheduled != null) return 1;
          return b.id.compareTo(a.id);
        });
        // Create a new list reference to ensure state change is detected
        state = state.copyWith(drafts: List<Draft>.from(updatedDrafts));
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final leagueDetailProvider =
    StateNotifierProvider.autoDispose.family<LeagueDetailNotifier, LeagueDetailState, int>(
  (ref, leagueId) => LeagueDetailNotifier(
    ref.watch(leagueRepositoryProvider),
    ref.watch(draftRepositoryProvider),
    ref.watch(matchupRepositoryProvider),
    ref.watch(rosterRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(invalidationServiceProvider),
    leagueId,
  ),
);
