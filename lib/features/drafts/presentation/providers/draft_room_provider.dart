import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/league_context_provider.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/idempotency/action_idempotency_provider.dart';
import '../../../../core/idempotency/action_ids.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../../players/data/player_repository.dart';
import '../../../players/domain/player.dart';
import '../../data/draft_pick_asset_repository.dart';
import '../../data/draft_repository.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import '../../domain/derby_state.dart';
import '../../domain/draft_activity_event.dart';
import '../../domain/draft_order_entry.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';
import '../../domain/draft_phase.dart';
import '../../domain/draft_status.dart';
import '../../domain/draft_type.dart';
import '../../domain/lot_result.dart';
import '../../domain/matchup_draft_option.dart';
import 'draft_socket_handler.dart';

export 'draft_socket_handler.dart' show OutbidNotification;

class DraftRoomState {
  final Draft? draft;
  final List<Player> players;
  final List<DraftPick> picks;
  final List<DraftOrderEntry> draftOrder;
  final String? currentUserId;
  final bool isLoading;
  final String? error;
  final String? snackbarMessage;
  // Auction-specific fields
  final List<AuctionLot> activeLots;
  final List<AuctionBudget> budgets;
  final OutbidNotification? outbidNotification;
  // Fast auction-specific fields
  final String auctionMode;
  final int? currentNominatorRosterId;
  final int? nominationNumber;
  final DateTime? nominationDeadline;
  // Slow auction nomination stats
  final int? dailyNominationsRemaining;
  final int? dailyNominationLimit;
  final bool globalCapReached;
  // Auction settings
  final AuctionSettings? auctionSettings;
  // Pick asset tracking for traded picks
  final List<DraftPickAsset> pickAssets;
  // Available pick assets for vet drafts with includeRookiePicks enabled
  final List<DraftPickAsset> availablePickAssets;
  // Whether this draft includes rookie picks (vet-only draft setting)
  final bool includeRookiePicks;
  // The season for rookie picks
  final int? rookiePicksSeason;
  // Grid display preference: true = teams on X-axis (columns), false = teams on Y-axis (rows)
  final bool teamsOnXAxis;
  // Commissioner status for start draft button
  final bool isCommissioner;
  // Derby phase state (draft order selection)
  final DerbyState? derbyState;
  // Whether a derby action is in progress
  final bool isDerbySubmitting;
  // Roster ID to team name mapping for derby phase (when draftOrder is empty)
  final Map<int, String> rosterNames;
  // Server clock offset in milliseconds (serverTime - localTime)
  // Used to correct countdown timers for client clock drift
  final int? serverClockOffsetMs;
  // Activity feed for the draft room log
  final List<DraftActivityEvent> activityFeed;
  final bool isForbidden;
  final bool isPickSubmitting;
  // Lot result announcement
  final LotResult? lastLotResult;
  final List<LotResult> completedLotResults;
  // Autopick explanation shown after reconnect (e.g., "You were autopicked: Player X (you were away)")
  final String? autopickExplanation;
  // Timestamp of last successful data load or socket update
  final DateTime? lastUpdated;
  // Overnight pause state
  final bool isInOvernightPause;
  // Matchups draft specific fields
  final List<MatchupDraftOption> availableMatchups;
  // Player IDs with pending nominations (optimistic local state)
  // Cleared when lot_created socket event confirms or after cleanup timeout
  final Set<int> pendingNominations;
  // Chess clock remaining seconds per roster (rosterId -> seconds)
  final Map<int, double> chessClocks;

  // Cache for currentRoundOrder computation
  List<DraftOrderEntry>? _cachedRoundOrder;
  int? _cachedRound;

  DraftRoomState({
    this.draft,
    this.players = const [],
    this.picks = const [],
    this.draftOrder = const [],
    this.currentUserId,
    this.isLoading = true,
    this.error,
    this.snackbarMessage,
    this.activeLots = const [],
    this.budgets = const [],
    this.outbidNotification,
    this.auctionMode = 'slow',
    this.currentNominatorRosterId,
    this.nominationNumber,
    this.nominationDeadline,
    this.dailyNominationsRemaining,
    this.dailyNominationLimit,
    this.globalCapReached = false,
    this.auctionSettings,
    this.pickAssets = const [],
    this.availablePickAssets = const [],
    this.includeRookiePicks = false,
    this.rookiePicksSeason,
    this.teamsOnXAxis = true,
    this.isCommissioner = false,
    this.derbyState,
    this.isDerbySubmitting = false,
    this.rosterNames = const {},
    this.serverClockOffsetMs,
    this.activityFeed = const [],
    this.isForbidden = false,
    this.isPickSubmitting = false,
    this.lastLotResult,
    this.completedLotResults = const [],
    this.autopickExplanation,
    this.lastUpdated,
    this.isInOvernightPause = false,
    this.availableMatchups = const [],
    this.pendingNominations = const {},
    this.chessClocks = const {},
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Relative time string for display: "Just now", "2m ago", "1h ago", etc.
  String get lastUpdatedDisplay {
    if (lastUpdated == null) return '';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }

  bool get isAuction => draft?.draftType == DraftType.auction;
  bool get isFastAuction => isAuction && auctionMode == 'fast';
  bool get isMatchupsDraft => draft?.draftType == DraftType.matchups;
  bool get isChessClockMode => draft?.isChessClockMode ?? false;

  /// Get remaining chess clock seconds for the current user
  double? get myChessClockRemaining {
    final rid = myRosterId;
    if (rid == null || chessClocks.isEmpty) return null;
    return chessClocks[rid];
  }

  /// Whether the draft is currently in derby phase (draft order selection)
  bool get isDerbyPhase => draft?.phase == DraftPhase.derby;

  /// Whether it's the current user's turn to pick a slot in derby phase
  bool get isMyDerbyTurn {
    if (!isDerbyPhase || myRosterId == null || derbyState == null) return false;
    return derbyState!.currentPickerRosterId == myRosterId;
  }

  /// Get the available slots in derby phase
  List<int> get availableDerbySlots => derbyState?.availableSlots ?? [];

  /// Get the derby slot claimed by a specific roster (null if none)
  int? getDerbySlotForRoster(int rosterId) {
    return derbyState?.getSlotForRoster(rosterId);
  }

  bool get isMyNomination {
    if (!isFastAuction || myRosterId == null) return false;
    return currentNominatorRosterId == myRosterId;
  }

  DraftOrderEntry? get currentNominator {
    if (currentNominatorRosterId == null || draftOrder.isEmpty) return null;
    return draftOrder
        .where((entry) => entry.rosterId == currentNominatorRosterId)
        .firstOrNull;
  }

  AuctionBudget? get myBudget {
    if (myRosterId == null) return null;
    return budgets.where((b) => b.rosterId == myRosterId).firstOrNull;
  }

  /// Get the set of drafted player IDs.
  /// Filters out pick asset selections which have null playerId.
  Set<int> get draftedPlayerIds => picks
      .where((p) => p.playerId != null && !p.isPickAsset)
      .map((p) => p.playerId!)
      .toSet();

  /// Get the set of drafted pick asset IDs.
  /// Derived directly from picks that have a draftPickAssetId (pick asset selections).
  /// Note: The backend handles queue cleanup when a pick asset is drafted.
  Set<int> get draftedPickAssetIds {
    return picks
        .where((p) => p.draftPickAssetId != null)
        .map((p) => p.draftPickAssetId!)
        .toSet();
  }

  DraftOrderEntry? get currentPicker {
    final d = draft;
    if (d?.currentRosterId == null || draftOrder.isEmpty) return null;
    return draftOrder
        .where((entry) => entry.rosterId == d!.currentRosterId)
        .firstOrNull;
  }

  bool get isMyTurn {
    if (currentUserId == null) return false;
    return currentPicker?.userId == currentUserId;
  }

  int? get myRosterId {
    if (currentUserId == null || draftOrder.isEmpty) return null;
    return draftOrder
        .where((entry) => entry.userId == currentUserId)
        .firstOrNull
        ?.rosterId;
  }

  List<DraftPick> get myPicks {
    if (myRosterId == null) return [];
    return picks.where((pick) => pick.rosterId == myRosterId).toList();
  }

  /// Whether autodraft is enabled for the current user
  bool get isMyAutodraftEnabled {
    if (myRosterId == null || draftOrder.isEmpty) return false;
    final myEntry =
        draftOrder.where((entry) => entry.rosterId == myRosterId).firstOrNull;
    return myEntry?.isAutodraftEnabled ?? false;
  }

  List<DraftOrderEntry> get currentRoundOrder {
    final d = draft;
    if (d == null || draftOrder.isEmpty) return draftOrder;

    final currentRound = (d.currentRound ?? 1).clamp(1, d.rounds);

    // Check cache
    if (_cachedRoundOrder != null && _cachedRound == currentRound) {
      return _cachedRoundOrder!;
    }

    // Compute and cache
    final isSnake = d.draftType == DraftType.snake;
    final isReversed = isSnake && currentRound % 2 == 0;
    final result = isReversed ? draftOrder.reversed.toList() : draftOrder;

    _cachedRoundOrder = result;
    _cachedRound = currentRound;

    return result;
  }

  /// Invalidate the round order cache
  void _invalidateRoundOrderCache() {
    _cachedRoundOrder = null;
    _cachedRound = null;
  }

  /// Get pick asset for a specific round and roster
  /// Used to determine if a pick slot has been traded
  DraftPickAsset? getPickAssetForSlot(int round, int originalRosterId) {
    return pickAssets
        .where((asset) =>
            asset.round == round && asset.originalRosterId == originalRosterId)
        .firstOrNull;
  }

  DraftRoomState copyWith({
    Draft? draft,
    List<Player>? players,
    List<DraftPick>? picks,
    List<DraftOrderEntry>? draftOrder,
    String? currentUserId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? snackbarMessage,
    bool clearSnackbarMessage = false,
    List<AuctionLot>? activeLots,
    List<AuctionBudget>? budgets,
    OutbidNotification? outbidNotification,
    bool clearOutbidNotification = false,
    String? auctionMode,
    int? currentNominatorRosterId,
    bool clearNominator = false,
    int? nominationNumber,
    bool clearNominationNumber = false,
    DateTime? nominationDeadline,
    bool clearNominationDeadline = false,
    int? dailyNominationsRemaining,
    bool clearDailyNominationsRemaining = false,
    int? dailyNominationLimit,
    bool clearDailyNominationLimit = false,
    bool? globalCapReached,
    AuctionSettings? auctionSettings,
    List<DraftPickAsset>? pickAssets,
    List<DraftPickAsset>? availablePickAssets,
    bool? includeRookiePicks,
    int? rookiePicksSeason,
    bool? teamsOnXAxis,
    bool? isCommissioner,
    DerbyState? derbyState,
    bool clearDerbyState = false,
    bool? isDerbySubmitting,
    Map<int, String>? rosterNames,
    int? serverClockOffsetMs,
    List<DraftActivityEvent>? activityFeed,
    bool? isForbidden,
    bool? isPickSubmitting,
    LotResult? lastLotResult,
    bool clearLastLotResult = false,
    List<LotResult>? completedLotResults,
    String? autopickExplanation,
    bool clearAutopickExplanation = false,
    DateTime? lastUpdated,
    bool? isInOvernightPause,
    List<MatchupDraftOption>? availableMatchups,
    Set<int>? pendingNominations,
    Map<int, double>? chessClocks,
  }) {
    final newState = DraftRoomState(
      draft: draft ?? this.draft,
      players: players ?? this.players,
      picks: picks ?? this.picks,
      draftOrder: draftOrder ?? this.draftOrder,
      currentUserId: currentUserId ?? this.currentUserId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      snackbarMessage: clearSnackbarMessage ? null : (snackbarMessage ?? this.snackbarMessage),
      activeLots: activeLots ?? this.activeLots,
      budgets: budgets ?? this.budgets,
      outbidNotification: clearOutbidNotification
          ? null
          : (outbidNotification ?? this.outbidNotification),
      auctionMode: auctionMode ?? this.auctionMode,
      currentNominatorRosterId: clearNominator
          ? null
          : (currentNominatorRosterId ?? this.currentNominatorRosterId),
      nominationNumber: clearNominationNumber
          ? null
          : (nominationNumber ?? this.nominationNumber),
      nominationDeadline: clearNominationDeadline
          ? null
          : (nominationDeadline ?? this.nominationDeadline),
      dailyNominationsRemaining: clearDailyNominationsRemaining
          ? null
          : (dailyNominationsRemaining ?? this.dailyNominationsRemaining),
      dailyNominationLimit: clearDailyNominationLimit
          ? null
          : (dailyNominationLimit ?? this.dailyNominationLimit),
      globalCapReached: globalCapReached ?? this.globalCapReached,
      auctionSettings: auctionSettings ?? this.auctionSettings,
      pickAssets: pickAssets ?? this.pickAssets,
      availablePickAssets: availablePickAssets ?? this.availablePickAssets,
      includeRookiePicks: includeRookiePicks ?? this.includeRookiePicks,
      rookiePicksSeason: rookiePicksSeason ?? this.rookiePicksSeason,
      teamsOnXAxis: teamsOnXAxis ?? this.teamsOnXAxis,
      isCommissioner: isCommissioner ?? this.isCommissioner,
      derbyState: clearDerbyState ? null : (derbyState ?? this.derbyState),
      isDerbySubmitting: isDerbySubmitting ?? this.isDerbySubmitting,
      rosterNames: rosterNames ?? this.rosterNames,
      serverClockOffsetMs: serverClockOffsetMs ?? this.serverClockOffsetMs,
      activityFeed: activityFeed ?? this.activityFeed,
      isForbidden: isForbidden ?? this.isForbidden,
      isPickSubmitting: isPickSubmitting ?? this.isPickSubmitting,
      lastLotResult:
          clearLastLotResult ? null : (lastLotResult ?? this.lastLotResult),
      completedLotResults: completedLotResults ?? this.completedLotResults,
      autopickExplanation: clearAutopickExplanation
          ? null
          : (autopickExplanation ?? this.autopickExplanation),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isInOvernightPause: isInOvernightPause ?? this.isInOvernightPause,
      availableMatchups: availableMatchups ?? this.availableMatchups,
      pendingNominations: pendingNominations ?? this.pendingNominations,
      chessClocks: chessClocks ?? this.chessClocks,
    );

    // Invalidate cache if draftOrder or draft changed
    if (draftOrder != null || draft != null) {
      newState._invalidateRoundOrderCache();
    }

    return newState;
  }
}

typedef DraftRoomKey = ({int leagueId, int draftId});

class DraftRoomNotifier extends StateNotifier<DraftRoomState>
    implements DraftSocketCallbacks {
  final DraftRepository _draftRepo;
  final PlayerRepository _playerRepo;
  final DraftPickAssetRepository _pickAssetRepo;
  final LeagueRepository _leagueRepo;
  final SocketService _socketService;
  final ActionIdempotencyNotifier _idempotency;
  final int leagueId;
  final int draftId;

  late final DraftSocketHandler _socketHandler;
  Timer? _budgetRefreshTimer;
  Timer? _outbidDismissTimer;
  Timer? _lotResultDismissTimer;
  Timer? _pendingNominationsCleanupTimer;
  VoidCallback? _reconnectUnsubscribe;
  VoidCallback? _memberKickedDisposer;

  /// Extract playerPool from draft settings, defaulting to veteran + rookie
  List<String>? _extractPlayerPool(Map<String, dynamic>? settings) {
    if (settings == null) return null;
    final pool = settings['playerPool'];
    if (pool is List) {
      return pool.map((e) => e.toString()).toList();
    }
    return null; // Use default on backend if not specified
  }

  DraftRoomNotifier(
    this._draftRepo,
    this._playerRepo,
    this._pickAssetRepo,
    this._leagueRepo,
    this._socketService,
    this._idempotency,
    String? currentUserId,
    this.leagueId,
    this.draftId,
  ) : super(DraftRoomState(currentUserId: currentUserId)) {
    _socketHandler = DraftSocketHandler(
      socketService: _socketService,
      draftId: draftId,
      callbacks: this,
    );
    _socketHandler.setupListeners();

    // Subscribe to socket reconnection events to refresh state
    _reconnectUnsubscribe = _socketService.onReconnected(_onSocketReconnected);

    // Join league room to receive membership events (member:kicked)
    _socketService.joinLeague(leagueId);
    _memberKickedDisposer = _socketService.onMemberKicked((data) {
      if (!mounted) return;
      // Reload data - if we were kicked, API returns 403 -> isForbidden is set
      loadData();
    });

    // Start cleanup timer for stale pending nominations
    _startPendingNominationsCleanup();

    loadData();
  }

  /// Handle socket reconnection - refresh state if disconnected too long.
  /// Also detects if an autopick happened while disconnected.
  void _onSocketReconnected(bool needsFullRefresh) {
    if (!mounted) return;

    // Capture pick count before reconnect for autopick detection
    final pickCountBefore = state.picks.length;
    final myRosterId = state.myRosterId;

    if (needsFullRefresh) {
      // Long disconnect (>30s) - do a full reload to ensure consistency
      if (kDebugMode) {
        debugPrint(
            'DraftRoom: Socket reconnected after long disconnect, refreshing all data');
      }
      _loadDataAndCheckAutopick(pickCountBefore, myRosterId);
    } else {
      // Short disconnect - just resync draft state and picks
      if (kDebugMode) {
        debugPrint('DraftRoom: Socket reconnected, doing lightweight resync');
      }
      _refreshDraftStateAndCheckAutopick(pickCountBefore, myRosterId);
      if (state.isAuction) {
        loadAuctionData();
      }
    }
  }

  /// Load data after reconnect and check for autopicks that happened while away.
  Future<void> _loadDataAndCheckAutopick(
      int pickCountBefore, int? myRosterId) async {
    await loadData();
    _detectAutopickWhileAway(pickCountBefore, myRosterId);
  }

  /// Lightweight resync after reconnect with autopick detection.
  Future<void> _refreshDraftStateAndCheckAutopick(
      int pickCountBefore, int? myRosterId) async {
    await _refreshDraftState();
    _detectAutopickWhileAway(pickCountBefore, myRosterId);
  }

  /// Detect if the user was autopicked while disconnected and show explanation.
  void _detectAutopickWhileAway(int pickCountBefore, int? myRosterId) {
    if (!mounted || myRosterId == null) return;
    // Find new picks for my roster that are autopicks and weren't in the previous state
    final newAutopicks = state.picks
        .where((p) =>
            p.rosterId == myRosterId &&
            p.isAutoPick &&
            p.pickNumber > pickCountBefore)
        .toList();

    if (newAutopicks.isNotEmpty) {
      final lastAutopick = newAutopicks.last;
      final pickLabel = lastAutopick.isPickAsset
          ? '${lastAutopick.pickAssetSeason} Rd ${lastAutopick.pickAssetRound} pick'
          : (lastAutopick.playerName ?? 'a player');
      state = state.copyWith(
        autopickExplanation: 'You were autopicked: $pickLabel (you were away)',
      );
    }
  }

  /// Clear the autopick explanation banner
  void clearAutopickExplanation() {
    state = state.copyWith(clearAutopickExplanation: true);
  }

  /// Helper to resolve a roster ID to a team/username for activity messages.
  String _teamNameForRoster(int rosterId) {
    final entry =
        state.draftOrder.where((e) => e.rosterId == rosterId).firstOrNull;
    if (entry != null) return entry.username;
    return state.rosterNames[rosterId] ?? 'Team';
  }

  /// Add an activity event to the feed (prepends, capped at 50).
  void _addActivityEvent(DraftActivityType type, String message) {
    final event = DraftActivityEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );
    final updated = [event, ...state.activityFeed];
    state = state.copyWith(
      activityFeed: updated.length > 50 ? updated.sublist(0, 50) : updated,
    );
  }

  /// Start periodic cleanup of stale pending nominations.
  void _startPendingNominationsCleanup() {
    _pendingNominationsCleanupTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _cleanupStalePendingNominations(),
    );
  }

  /// Remove pending nominations that now exist in activeLots.
  void _cleanupStalePendingNominations() {
    if (!mounted || state.pendingNominations.isEmpty) return;

    // Remove pending nominations that now exist in activeLots
    final activePlayerIds = state.activeLots.map((l) => l.playerId).toSet();
    final stillPending = state.pendingNominations
        .where((id) => !activePlayerIds.contains(id))
        .toSet();

    if (stillPending.length != state.pendingNominations.length) {
      state = state.copyWith(pendingNominations: stillPending);
    }
  }

  // Socket callback implementations
  @override
  void onPickReceived(DraftPick pick) {
    if (!mounted) return;
    // Dedupe: prevent duplicate picks from socket replays or reconnection
    if (state.picks.any((p) => p.id == pick.id)) return;

    // Conflict detection: if we already have a DIFFERENT pick at this pickNumber,
    // something is wrong (stale state) - trigger full resync
    final existingAtNumber = state.picks
        .where((p) => p.pickNumber == pick.pickNumber && p.id != pick.id)
        .firstOrNull;
    if (existingAtNumber != null) {
      if (kDebugMode) {
        debugPrint(
            'DraftRoom: Pick conflict detected at pickNumber ${pick.pickNumber}, triggering full resync');
      }
      loadData(); // Full resync to recover from any desync (stale picks, traded picks, queue cleanup, etc.)
      return;
    }

    // Add pick and sort by pickNumber to handle out-of-order socket events
    final updatedPicks = [...state.picks, pick]
      ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    state = state.copyWith(picks: updatedPicks, lastUpdated: DateTime.now());

    // Reload available matchups for matchups drafts (reciprocal picks affect availability)
    if (state.isMatchupsDraft) {
      loadAvailableMatchups();
    }

    // Add activity event
    final teamName = _teamNameForRoster(pick.rosterId);
    final pickLabel = pick.isPickAsset
        ? '${pick.pickAssetSeason} Rd ${pick.pickAssetRound} pick (${pick.pickAssetOriginalTeam ?? 'unknown'})'
        : (pick.playerName ?? 'unknown');
    if (pick.isAutoPick) {
      _addActivityEvent(
          DraftActivityType.autoPick, '$teamName autopicked $pickLabel');
    } else {
      _addActivityEvent(
          DraftActivityType.pickMade, '$teamName picked $pickLabel');
    }
  }

  @override
  void onNextPickReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final currentDraft = state.draft;
    if (currentDraft != null) {
      final statusStr = data['status'] as String?;

      // Parse chess clocks if present
      Map<int, double>? chessClocks;
      final clocksRaw = data['chessClocks'] ?? data['chess_clocks'];
      if (clocksRaw is Map) {
        chessClocks = {};
        for (final entry in clocksRaw.entries) {
          final key = entry.key is int ? entry.key as int : int.tryParse(entry.key.toString());
          final value = entry.value is num ? (entry.value as num).toDouble() : double.tryParse(entry.value.toString());
          if (key != null && value != null) {
            chessClocks[key] = value;
          }
        }
      }

      state = state.copyWith(
        draft: currentDraft.copyWith(
          status: statusStr != null ? DraftStatus.fromString(statusStr) : null,
          // Use safe numeric conversion - socket.io may send ints as doubles
          currentPick: (data['currentPick'] as num?)?.toInt(),
          currentRound: (data['currentRound'] as num?)?.toInt(),
          currentRosterId: (data['currentRosterId'] as num?)?.toInt(),
          pickDeadline: data['pickDeadline'] != null
              ? DateTime.tryParse(data['pickDeadline'].toString())
              : null,
        ),
        chessClocks: chessClocks,
      );
    }
  }

  @override
  void onDraftCompletedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    state = state.copyWith(
        draft: Draft.fromJson(data), lastUpdated: DateTime.now());
    _addActivityEvent(DraftActivityType.draftCompleted, 'Draft completed');
  }

  @override
  void onPickUndoneReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final pickData = data['pick'] as Map<String, dynamic>?;
    final draftData = data['draft'] as Map<String, dynamic>?;

    if (pickData != null) {
      final undonePickId = pickData['id'] as int?;
      if (undonePickId != null) {
        state = state.copyWith(
          picks: state.picks.where((p) => p.id != undonePickId).toList(),
        );
      }
    }

    if (draftData != null) {
      state = state.copyWith(draft: Draft.fromJson(draftData));
    }

    // Parse chess clocks if present
    final clocksRaw = data['chessClocks'] ?? data['chess_clocks'];
    if (clocksRaw is Map) {
      final chessClocks = <int, double>{};
      for (final entry in clocksRaw.entries) {
        final key = entry.key is int ? entry.key as int : int.tryParse(entry.key.toString());
        final value = entry.value is num ? (entry.value as num).toDouble() : double.tryParse(entry.value.toString());
        if (key != null && value != null) {
          chessClocks[key] = value;
        }
      }
      state = state.copyWith(chessClocks: chessClocks);
    }

    _addActivityEvent(
        DraftActivityType.pickUndone, 'Last pick undone by commissioner');
  }

  @override
  void onDraftPausedReceived() {
    if (!mounted) return;
    final currentDraft = state.draft;
    if (currentDraft != null) {
      state = state.copyWith(
        draft: currentDraft.copyWith(status: DraftStatus.paused),
      );
    }
    _addActivityEvent(
        DraftActivityType.draftPaused, 'Draft paused by commissioner');
  }

  @override
  void onDraftResumedReceived() {
    if (!mounted) return;
    final currentDraft = state.draft;
    if (currentDraft != null) {
      state = state.copyWith(
        draft: currentDraft.copyWith(status: DraftStatus.inProgress),
      );
    }
    _addActivityEvent(DraftActivityType.draftResumed, 'Draft resumed');
    // Refresh auction data to get restored lot deadlines
    if (state.isAuction) {
      loadAuctionData();
    }
    // Refresh chess clocks on resume
    if (state.isChessClockMode) {
      loadChessClocks();
    }
  }

  /// Update server clock offset based on serverTime from socket events.
  /// Used to correct countdown timers for client clock drift.
  void _updateServerClockOffset(int? serverTime) {
    if (serverTime == null) return;
    final localNow = DateTime.now().millisecondsSinceEpoch;
    final offset = serverTime - localNow;
    // Only update if significantly different (>500ms) to avoid jitter
    final currentOffset = state.serverClockOffsetMs ?? 0;
    if ((offset - currentOffset).abs() > 500) {
      state = state.copyWith(serverClockOffsetMs: offset);
    }
  }

  /// Helper to upsert a lot and maintain sorted order by bidDeadline.
  /// Prevents duplicates and preserves user's myMaxBid on updates.
  void _upsertAndSortLot(AuctionLot lot) {
    final existingIndex = state.activeLots.indexWhere((l) => l.id == lot.id);
    List<AuctionLot> updated;
    if (existingIndex >= 0) {
      // Update existing, preserving myMaxBid if the new lot doesn't have it
      final existing = state.activeLots[existingIndex];
      final merged = lot.myMaxBid == null && existing.myMaxBid != null
          ? lot.copyWith(myMaxBid: existing.myMaxBid)
          : lot;
      updated = [...state.activeLots];
      updated[existingIndex] = merged;
    } else {
      updated = [...state.activeLots, lot];
    }
    // Sort by bidDeadline ASC (matches backend ordering)
    updated.sort((a, b) => a.bidDeadline.compareTo(b.bidDeadline));
    state = state.copyWith(activeLots: updated);
  }

  @override
  void onLotCreatedReceived(AuctionLot lot,
      {int? serverTime, bool isAutoNomination = false}) {
    if (!mounted) return;
    _updateServerClockOffset(serverTime);
    _upsertAndSortLot(lot);

    // Clear from pending nominations (socket confirmed)
    if (state.pendingNominations.contains(lot.playerId)) {
      final updated = {...state.pendingNominations}..remove(lot.playerId);
      state = state.copyWith(pendingNominations: updated);
    }

    // Handle auto-nomination feedback
    if (isAutoNomination) {
      final nominatorRosterId = lot.nominatorRosterId;
      final teamName = _teamNameForRoster(nominatorRosterId);
      final player =
          state.players.where((p) => p.id == lot.playerId).firstOrNull;
      final playerName = player?.fullName ?? 'a player';

      // Distinguish between auto_nominate_no_open_bid and auto_nominate_and_open_bid
      if (lot.currentBidderRosterId == null) {
        // auto_nominate_no_open_bid mode
        _addActivityEvent(
          DraftActivityType.autoNominated,
          '$teamName auto-nominated $playerName (no opening bid)',
        );
      } else {
        // auto_nominate_and_open_bid mode (default behavior)
        _addActivityEvent(
          DraftActivityType.autoNominated,
          '$teamName auto-nominated $playerName (timeout)',
        );
      }

      // Show snackbar notification if current user was auto-nominated
      if (nominatorRosterId == state.myRosterId) {
        state = state.copyWith(
          snackbarMessage: lot.currentBidderRosterId == null
              ? 'You missed your nomination window - $playerName was auto-nominated (no opening bid)'
              : 'You missed your nomination window - $playerName was auto-nominated',
        );
      }
    }
  }

  @override
  void onLotUpdatedReceived(AuctionLot lot, {int? serverTime}) {
    if (!mounted) return;
    _updateServerClockOffset(serverTime);
    final myRosterId = state.myRosterId;

    // Preserve user's myMaxBid and re-sort by deadline (deadline extensions change order)
    final existingLot =
        state.activeLots.where((l) => l.id == lot.id).firstOrNull;
    final mergedLot = (lot.myMaxBid == null && existingLot?.myMaxBid != null)
        ? lot.copyWith(myMaxBid: existingLot!.myMaxBid)
        : lot;
    _upsertAndSortLot(mergedLot);

    // Instant refresh for own bid updates (user needs immediate budget feedback)
    // Keep 200ms debounce for other events to avoid spamming API during rapid bidding
    if (myRosterId != null && lot.currentBidderRosterId == myRosterId) {
      _budgetRefreshTimer?.cancel();
      if (mounted) loadAuctionData();
    } else {
      _budgetRefreshTimer?.cancel();
      _budgetRefreshTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) loadAuctionData();
      });
    }
  }

  @override
  void onLotWonReceived(LotResult result) {
    if (!mounted) return;

    final isMyWin = result.winnerRosterId == state.myRosterId;

    state = state.copyWith(
      activeLots: state.activeLots.where((l) => l.id != result.lotId).toList(),
      lastLotResult: result,
      completedLotResults: [...state.completedLotResults, result],
    );
    _startLotResultDismissTimer(result.lotId);

    // Instant refresh for user's own wins (critical for next bid decision)
    // Budget updates come from the authoritative API response
    if (isMyWin) {
      _budgetRefreshTimer?.cancel();
      if (mounted) loadAuctionData(); // Immediate budget update
    } else {
      // Keep debounce for other users' wins (prevents API spam)
      _budgetRefreshTimer?.cancel();
      _budgetRefreshTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) loadAuctionData();
      });
    }
  }

  @override
  void onLotPassedReceived(LotResult result) {
    if (!mounted) return;
    state = state.copyWith(
      activeLots: state.activeLots.where((l) => l.id != result.lotId).toList(),
      lastLotResult: result,
      completedLotResults: [...state.completedLotResults, result],
    );
    _startLotResultDismissTimer(result.lotId);
  }

  void _startLotResultDismissTimer(int lotId) {
    _lotResultDismissTimer?.cancel();
    _lotResultDismissTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      // Only clear if this is still the same result
      if (state.lastLotResult?.lotId == lotId) {
        state = state.copyWith(clearLastLotResult: true);
      }
    });
  }

  void dismissLotResult() {
    _lotResultDismissTimer?.cancel();
    state = state.copyWith(clearLastLotResult: true);
  }

  @override
  void onOutbidReceived(OutbidNotification notification) {
    if (!mounted) return;
    state = state.copyWith(outbidNotification: notification);

    // Cancel any pending dismiss timer and start a new one
    _outbidDismissTimer?.cancel();
    _outbidDismissTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      // Only clear if this is still the same notification (prevent clearing newer ones)
      if (state.outbidNotification?.lotId == notification.lotId &&
          state.outbidNotification?.playerId == notification.playerId) {
        clearOutbidNotification();
      }
    });
  }

  @override
  void onNominatorChangedReceived(
      int? rosterId, int? nominationNumber, DateTime? nominationDeadline,
      {int? timeoutSkippedRosterId}) {
    if (!mounted) return;

    // Handle timeout skip notification
    if (timeoutSkippedRosterId != null) {
      final teamName = _teamNameForRoster(timeoutSkippedRosterId);
      _addActivityEvent(
        DraftActivityType.nominationTimeout,
        '$teamName missed nomination (skipped)',
      );
      if (timeoutSkippedRosterId == state.myRosterId) {
        state = state.copyWith(
          snackbarMessage: 'You missed your nomination window (skipped)',
        );
      }
    }

    state = state.copyWith(
      currentNominatorRosterId: rosterId,
      clearNominator: rosterId == null,
      nominationNumber: nominationNumber,
      clearNominationNumber: nominationNumber == null,
      nominationDeadline: nominationDeadline,
      clearNominationDeadline: nominationDeadline == null,
    );
  }

  @override
  void onAuctionErrorReceived(String message) {
    if (!mounted) return;
    final lower = message.toLowerCase();
    if (lower.contains('expired') ||
        lower.contains('ended') ||
        lower.contains('closed') ||
        lower.contains('closing')) {
      // Transient auction errors -> snackbar (not full error page)
      state = state.copyWith(snackbarMessage: message);
      loadAuctionData();
    } else {
      state = state.copyWith(error: message);
    }
  }

  // Data loading methods
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final draft = await _draftRepo.getDraft(leagueId, draftId);

      // Extract playerPool from draft settings for filtering players
      final playerPool = _extractPlayerPool(draft.rawSettings);

      // Extract includeRookiePicks settings
      final includeRookiePicks =
          draft.rawSettings?['includeRookiePicks'] as bool? ?? false;
      final rookiePicksSeason = draft.rawSettings?['rookiePicksSeason'] as int?;

      final results = await Future.wait<dynamic>([
        _playerRepo
            .getPlayers(playerPool: playerPool)
            .catchError((e) => <Player>[]),
        _draftRepo
            .getDraftOrder(leagueId, draftId)
            .catchError((e) => <Map<String, dynamic>>[]),
        _draftRepo
            .getDraftPicks(leagueId, draftId)
            .catchError((e) => <Map<String, dynamic>>[]),
        _pickAssetRepo
            .getLeaguePickAssets(leagueId)
            .catchError((e) => <DraftPickAsset>[]),
        _leagueRepo.getLeagueMembers(leagueId).catchError((e) => <Roster>[]),
      ]);

      final players = results[0] as List<Player>;
      final orderData = results[1] as List<Map<String, dynamic>>;
      final picksData = results[2] as List<Map<String, dynamic>>;
      final pickAssets = results[3] as List<DraftPickAsset>;
      final rosters = results[4] as List<Roster>;

      final draftOrder =
          orderData.map((e) => DraftOrderEntry.fromJson(e)).toList();
      final picks = picksData.map((e) => DraftPick.fromJson(e)).toList()
        ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));

      // Build roster ID to name map for derby phase (when draftOrder is empty)
      final rosterNames = <int, String>{};
      for (final roster in rosters) {
        rosterNames[roster.id] = roster.teamName ?? roster.username;
      }

      if (!mounted) return;

      state = state.copyWith(
        draft: draft,
        players: players,
        draftOrder: draftOrder,
        picks: picks,
        pickAssets: pickAssets,
        includeRookiePicks: includeRookiePicks,
        rookiePicksSeason: rookiePicksSeason,
        rosterNames: rosterNames,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      if (mounted && draft.draftType == DraftType.auction) {
        loadAuctionData();
      }

      // Load available pick assets for vet drafts with includeRookiePicks enabled
      if (mounted && includeRookiePicks) {
        loadAvailablePickAssets();
      }

      // Load derby state if in derby phase
      if (mounted && draft.phase == DraftPhase.derby) {
        loadDerbyState();
      }

      // Load available matchups for matchups drafts
      if (mounted && draft.draftType == DraftType.matchups) {
        loadAvailableMatchups();
      }

      // Load chess clocks if chess clock mode
      if (mounted && draft.isChessClockMode) {
        loadChessClocks();
      }
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(
          isForbidden: true, isLoading: false, players: [], picks: []);
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  /// Load available pick assets for vet drafts with rookie picks enabled
  Future<void> loadAvailablePickAssets() async {
    if (!state.includeRookiePicks) return;
    try {
      final assets = await _draftRepo.getAvailablePickAssets(leagueId, draftId);
      if (!mounted) return;
      // Sort by round (earlier rounds first)
      assets.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      state = state.copyWith(availablePickAssets: assets);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load available pick assets: $e');
    }
  }

  Future<void> loadAuctionData() async {
    if (state.draft?.draftType != DraftType.auction) return;
    try {
      final auctionState = await _draftRepo.getAuctionState(leagueId, draftId);
      if (!mounted) return;
      // Sort activeLots by bidDeadline ASC to match _upsertAndSortLot() invariant
      // This ensures activeLots.first is always the earliest-deadline lot
      final sortedActiveLots = [...auctionState.activeLots]
        ..sort((a, b) => a.bidDeadline.compareTo(b.bidDeadline));
      state = state.copyWith(
        activeLots: sortedActiveLots,
        budgets: auctionState.budgets,
        auctionMode: auctionState.auctionMode,
        currentNominatorRosterId: auctionState.currentNominatorRosterId,
        nominationNumber: auctionState.nominationNumber,
        nominationDeadline: auctionState.nominationDeadline,
        dailyNominationsRemaining: auctionState.dailyNominationsRemaining,
        dailyNominationLimit: auctionState.dailyNominationLimit,
        globalCapReached: auctionState.globalCapReached,
        auctionSettings: auctionState.settings,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      // Auction data is supplemental - log for debugging but don't block UI
      if (kDebugMode) debugPrint('Failed to load auction data: $e');
      // Still update state with snackbar for potential UI feedback
      if (mounted) {
        state = state.copyWith(snackbarMessage: 'Failed to load auction data');
      }
    }
  }

  /// Lightweight resync of draft state and picks (for when socket may have missed events)
  Future<void> _refreshDraftState() async {
    try {
      final results = await Future.wait<dynamic>([
        _draftRepo.getDraft(leagueId, draftId),
        _draftRepo.getDraftPicks(leagueId, draftId),
      ]);

      final draft = results[0] as Draft;
      final picksData = results[1] as List<Map<String, dynamic>>;
      final picks = picksData.map((e) => DraftPick.fromJson(e)).toList()
        ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));

      if (!mounted) return;
      state = state.copyWith(
          draft: draft, picks: picks, lastUpdated: DateTime.now());
    } catch (e) {
      // Resync failed silently - socket events are primary update mechanism
    }
  }

  // Action methods
  Future<String?> makePick(int playerId) async {
    if (state.isPickSubmitting) return 'Pick already in progress';
    final pickNumber = state.picks.length + 1;
    final rosterId = state.myRosterId ?? 0;
    final actionId = ActionIds.draftPick(draftId, rosterId, pickNumber);
    if (_idempotency.isInFlight(actionId)) return 'Pick already in progress';
    state = state.copyWith(isPickSubmitting: true);
    try {
      await _idempotency.run(
        actionId: actionId,
        op: (key) => _draftRepo.makePick(leagueId, draftId, playerId, idempotencyKey: key),
      );
      // Resync to ensure UI is updated even if socket event was missed
      if (mounted) await _refreshDraftState();
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    } finally {
      if (mounted) state = state.copyWith(isPickSubmitting: false);
    }
  }

  /// Make a pick using a draft pick asset instead of a player
  Future<String?> makePickAssetSelection(int pickAssetId) async {
    if (state.isPickSubmitting) return 'Pick already in progress';
    final pickNumber = state.picks.length + 1;
    final rosterId = state.myRosterId ?? 0;
    final actionId = ActionIds.draftPickAsset(draftId, rosterId, pickNumber);
    if (_idempotency.isInFlight(actionId)) return 'Pick already in progress';
    state = state.copyWith(isPickSubmitting: true);
    try {
      await _idempotency.run(
        actionId: actionId,
        op: (key) => _draftRepo.makePickAssetSelection(
            leagueId, draftId, pickAssetId,
            idempotencyKey: key),
      );
      // Resync state and reload available pick assets
      if (mounted) {
        await _refreshDraftState();
        await loadAvailablePickAssets();
      }
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    } finally {
      if (mounted) state = state.copyWith(isPickSubmitting: false);
    }
  }

  Future<String?> nominate(int playerId) async {
    final rosterId = state.myRosterId ?? 0;
    final nominationNumber = state.activeLots.length;
    final actionId = ActionIds.auctionNominate(draftId, rosterId, nominationNumber);
    if (_idempotency.isInFlight(actionId)) return 'Nomination already in progress';

    // Optimistically add to pending nominations
    if (mounted) {
      state = state.copyWith(
        pendingNominations: {...state.pendingNominations, playerId},
      );
    }

    try {
      final lot = await _idempotency.run(
        actionId: actionId,
        op: (key) => _draftRepo.nominate(leagueId, draftId, playerId, idempotencyKey: key),
      );
      // Immediately add the new lot to state (don't wait for WebSocket)
      // Use upsert to prevent duplicates if socket message arrives first
      if (mounted && lot != null) {
        _upsertAndSortLot(lot);
      }
      return null;
    } catch (e) {
      // Remove from pending on error
      if (mounted) {
        final updated = {...state.pendingNominations}..remove(playerId);
        state = state.copyWith(pendingNominations: updated);
      }
      return ErrorSanitizer.sanitize(e);
    }
  }

  Future<String?> setMaxBid(int lotId, int maxBid) async {
    final rosterId = state.myRosterId ?? 0;
    final lot = state.activeLots.where((l) => l.id == lotId).firstOrNull;
    final actionId = ActionIds.auctionMaxBid(draftId, rosterId, lot?.playerId ?? 0);
    if (_idempotency.isInFlight(actionId)) return 'Bid already in progress';

    // Save previous myMaxBid for this specific lot (for targeted rollback)
    final previousMaxBid = lot?.myMaxBid;

    // Optimistic update: immediately reflect user's max bid in state
    if (mounted) {
      state = state.copyWith(
        activeLots: state.activeLots.map((l) {
          if (l.id == lotId) return l.copyWith(myMaxBid: maxBid);
          return l;
        }).toList(),
      );
    }

    try {
      await _idempotency.run(
        actionId: actionId,
        op: (key) => _draftRepo.setMaxBid(leagueId, draftId, lotId, maxBid, idempotencyKey: key),
      );
      return null;
    } catch (e) {
      // Rollback only the specific myMaxBid change, preserving any socket updates
      // that may have arrived during the API call (e.g., currentBid changes)
      if (mounted) {
        state = state.copyWith(
          activeLots: state.activeLots.map((l) {
            if (l.id == lotId) return l.copyWith(myMaxBid: previousMaxBid);
            return l;
          }).toList(),
        );
      }
      return ErrorSanitizer.sanitize(e);
    }
  }

  void clearOutbidNotification() {
    state = state.copyWith(clearOutbidNotification: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSnackbarMessage() {
    state = state.copyWith(clearSnackbarMessage: true);
  }

  /// Toggle the grid axis orientation
  void toggleGridAxis() {
    state = state.copyWith(teamsOnXAxis: !state.teamsOnXAxis);
  }

  /// Toggle autodraft for the current user
  Future<String?> toggleAutodraft(bool enabled,
      {String? idempotencyKey}) async {
    try {
      await _draftRepo.toggleAutodraft(leagueId, draftId, enabled,
          idempotencyKey: idempotencyKey);
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Start the draft (commissioner only)
  Future<String?> startDraft({String? idempotencyKey}) async {
    try {
      final updatedDraft = await _draftRepo.startDraft(leagueId, draftId,
          idempotencyKey: idempotencyKey);
      if (mounted) {
        state = state.copyWith(draft: updatedDraft);
        _addActivityEvent(DraftActivityType.draftStarted, 'Draft started');
      }
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Pause the draft (commissioner only)
  Future<String?> pauseDraft() async {
    try {
      await _draftRepo.pauseDraft(leagueId, draftId);
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Resume the draft (commissioner only)
  Future<String?> resumeDraft() async {
    try {
      await _draftRepo.resumeDraft(leagueId, draftId);
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Confirm draft order without randomizing (commissioner only)
  Future<String?> confirmDraftOrder() async {
    try {
      await _draftRepo.confirmDraftOrder(leagueId, draftId);
      // Update local state to reflect confirmed order
      final currentDraft = state.draft;
      if (mounted && currentDraft != null) {
        state = state.copyWith(
          draft: currentDraft.copyWith(orderConfirmed: true),
        );
      }
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Update scheduled start time (commissioner only)
  Future<String?> updateScheduledStart(DateTime? scheduledStart) async {
    try {
      final updatedDraft = await _draftRepo.updateDraftSettings(
        leagueId,
        draftId,
        scheduledStart: scheduledStart,
        clearScheduledStart: scheduledStart == null,
      );
      if (mounted) {
        state = state.copyWith(draft: updatedDraft);
      }
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Set commissioner status
  void setCommissioner(bool isCommissioner) {
    state = state.copyWith(isCommissioner: isCommissioner);
  }

  @override
  void onAutodraftToggledReceived(int rosterId, bool enabled, bool forced) {
    if (!mounted) return;
    // Update the draft order with the new autodraft state
    state = state.copyWith(
      draftOrder: state.draftOrder.map((entry) {
        if (entry.rosterId == rosterId) {
          return entry.copyWith(isAutodraftEnabled: enabled);
        }
        return entry;
      }).toList(),
    );

    final teamName = _teamNameForRoster(rosterId);
    final toggle = enabled ? 'on' : 'off';
    _addActivityEvent(DraftActivityType.autodraftToggled,
        '$teamName turned autodraft $toggle');
  }

  @override
  void onPickTradedReceived(DraftPickAsset pickAsset) {
    if (!mounted) return;
    // Update or add the pick asset in the state
    final existingIndex =
        state.pickAssets.indexWhere((a) => a.id == pickAsset.id);
    if (existingIndex >= 0) {
      // Update existing pick asset
      final updatedAssets = [...state.pickAssets];
      updatedAssets[existingIndex] = pickAsset;
      state = state.copyWith(pickAssets: updatedAssets);
    } else {
      // Add new pick asset
      state = state.copyWith(pickAssets: [...state.pickAssets, pickAsset]);
    }
  }

  @override
  void onDraftSettingsUpdatedReceived(Map<String, dynamic> data) {
    if (!mounted) return;

    // Handle full draft object if present (from updateDraftSettings)
    if (data.containsKey('id')) {
      final updatedDraft = Draft.fromJson(data);
      state = state.copyWith(draft: updatedDraft);
    } else if (data['order_confirmed'] == true) {
      // Partial update for order confirmation only
      final currentDraft = state.draft;
      if (currentDraft != null) {
        state = state.copyWith(
          draft: currentDraft.copyWith(orderConfirmed: true),
        );
      }
    }

    // If draft order was included, update it immediately
    final orderData = data['draft_order'] as List?;
    if (orderData != null) {
      final newOrder = orderData
          .map((json) =>
              DraftOrderEntry.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
      state = state.copyWith(draftOrder: newOrder);
    }
  }

  // Derby callback implementations

  @override
  void onDerbyStateReceived(DerbyState derbyState) {
    if (!mounted) return;
    state = state.copyWith(derbyState: derbyState, lastUpdated: DateTime.now());
  }

  @override
  void onDerbySlotPickedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final currentState = state.derbyState;
    if (currentState == null) return;

    final slotNumber =
        data['slotNumber'] as int? ?? data['slot_number'] as int?;
    final rosterId = data['rosterId'] as int? ?? data['roster_id'] as int?;
    final nextPickerRosterId = data['nextPickerRosterId'] as int? ??
        data['next_picker_roster_id'] as int?;
    final deadlineStr =
        data['deadline'] as String? ?? data['slotPickDeadline'] as String?;
    final deadline =
        deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;

    // Parse remaining slots from event
    final remainingSlotsRaw =
        data['remainingSlots'] ?? data['remaining_slots'] ?? [];
    final List<int> remainingSlots = [];
    if (remainingSlotsRaw is List) {
      for (final item in remainingSlotsRaw) {
        final value = item is int ? item : int.tryParse(item.toString());
        if (value != null) remainingSlots.add(value);
      }
    }

    if (slotNumber != null && rosterId != null) {
      final updatedClaimedSlots = Map<int, int>.from(currentState.claimedSlots);
      updatedClaimedSlots[slotNumber] = rosterId;

      // Note: currentTurnIndex is NOT mutated here - server is authoritative
      // via derby:turn_changed events for timeout policies (PUSH_BACK_ONE, PUSH_TO_END)
      state = state.copyWith(
        derbyState: currentState.copyWith(
          claimedSlots: updatedClaimedSlots,
          currentPickerRosterId: nextPickerRosterId,
          slotPickDeadline: deadline,
          availableSlots: remainingSlots,
        ),
        lastUpdated: DateTime.now(),
      );

      // Add activity event for derby slot pick
      final teamName = _teamNameForRoster(rosterId);
      _addActivityEvent(DraftActivityType.derbySlotPicked,
          '$teamName picked slot #$slotNumber');
    }
  }

  @override
  void onDerbyTurnChangedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final currentState = state.derbyState;
    if (currentState == null) return;

    final currentPickerRosterId = data['currentPickerRosterId'] as int? ??
        data['current_picker_roster_id'] as int?;
    final deadlineStr =
        data['deadline'] as String? ?? data['slotPickDeadline'] as String?;
    final deadline =
        deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;

    state = state.copyWith(
      derbyState: currentState.copyWith(
        currentPickerRosterId: currentPickerRosterId,
        slotPickDeadline: deadline,
      ),
    );
  }

  @override
  void onDerbyPhaseTransitionReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final phaseStr = data['phase'] as String?;
    if (phaseStr == null) return;

    final newPhase = DraftPhase.fromString(phaseStr);
    final currentDraft = state.draft;

    if (currentDraft != null) {
      state = state.copyWith(
        draft: currentDraft.copyWith(phase: newPhase),
        clearDerbyState: newPhase ==
            DraftPhase.live, // Clear derby state when transitioning to live
      );

      // If transitioning to LIVE, reload the draft order
      if (newPhase == DraftPhase.live) {
        _addActivityEvent(
            DraftActivityType.derbyCompleted, 'Draft order selection complete');
        _refreshDraftState();
      }
    }
  }

  // Derby action methods

  /// Start the derby phase (commissioner only)
  Future<String?> startDerby({String? idempotencyKey}) async {
    try {
      state = state.copyWith(isDerbySubmitting: true);
      final derbyState = await _draftRepo.startDerby(leagueId, draftId,
          idempotencyKey: idempotencyKey);
      if (mounted) {
        // Update draft phase and derby state
        final currentDraft = state.draft;
        state = state.copyWith(
          derbyState: derbyState,
          isDerbySubmitting: false,
          draft: currentDraft?.copyWith(phase: DraftPhase.derby),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isDerbySubmitting: false);
      }
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Pick a slot during derby phase
  Future<String?> pickDerbySlot(int slotNumber) async {
    try {
      state = state.copyWith(isDerbySubmitting: true);
      await _draftRepo.pickDerbySlot(leagueId, draftId, slotNumber);
      if (mounted) {
        state = state.copyWith(isDerbySubmitting: false);
      }
      return null;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isDerbySubmitting: false);
      }
      return ErrorSanitizer.sanitize(e);
    }
  }

  /// Load derby state from the server
  Future<void> loadDerbyState() async {
    if (state.draft?.phase != DraftPhase.derby) return;
    try {
      final derbyState = await _draftRepo.getDerbyState(leagueId, draftId);
      if (!mounted) return;
      state =
          state.copyWith(derbyState: derbyState, lastUpdated: DateTime.now());
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load derby state: $e');
    }
  }

  /// Load chess clock remaining times from the server
  Future<void> loadChessClocks() async {
    if (state.draft?.isChessClockMode != true) return;
    try {
      final clocks = await _draftRepo.getChessClocks(leagueId, draftId);
      if (!mounted) return;
      state = state.copyWith(chessClocks: clocks);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load chess clocks: $e');
    }
  }

  /// Load available matchups for matchups drafts
  Future<void> loadAvailableMatchups() async {
    if (state.draft?.draftType != DraftType.matchups) return;
    try {
      final matchupsData =
          await _draftRepo.getAvailableMatchups(leagueId, draftId);
      final matchups = matchupsData
          .map((json) => MatchupDraftOption.fromJson(json))
          .toList();
      if (!mounted) return;
      state = state.copyWith(availableMatchups: matchups);
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load available matchups: $e');
    }
  }

  /// Pick a matchup (week/opponent combination) in a matchups draft
  Future<String?> pickMatchup(int week, int opponentRosterId) async {
    if (state.isPickSubmitting) return 'Pick already in progress';
    state = state.copyWith(isPickSubmitting: true);
    try {
      await _draftRepo.pickMatchup(leagueId, draftId, week, opponentRosterId);
      // Resync to ensure UI is updated even if socket event was missed
      if (mounted) {
        await _refreshDraftState();
        await loadAvailableMatchups();
      }
      return null;
    } catch (e) {
      return ErrorSanitizer.sanitize(e);
    } finally {
      if (mounted) state = state.copyWith(isPickSubmitting: false);
    }
  }

  @override
  void onOvernightPauseStartedReceived() {
    if (!mounted) return;
    state = state.copyWith(isInOvernightPause: true);
    _addActivityEvent(DraftActivityType.draftPaused,
        'Draft paused: overnight pause window started');
  }

  @override
  void onOvernightPauseEndedReceived() {
    if (!mounted) return;
    state = state.copyWith(isInOvernightPause: false);
    _addActivityEvent(DraftActivityType.draftResumed,
        'Draft resumed: overnight pause window ended');
  }

  @override
  void onChessClockUpdatedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final clocksData = data['chessClocks'] ?? data['chess_clocks'];
    if (clocksData is Map) {
      final chessClocks = <int, double>{};
      for (final entry in clocksData.entries) {
        final rosterId = int.tryParse(entry.key.toString());
        final seconds = (entry.value as num?)?.toDouble();
        if (rosterId != null && seconds != null) {
          chessClocks[rosterId] = seconds;
        }
      }
      state = state.copyWith(chessClocks: chessClocks);
    }
  }

  @override
  void dispose() {
    _budgetRefreshTimer?.cancel();
    _outbidDismissTimer?.cancel();
    _lotResultDismissTimer?.cancel();
    _pendingNominationsCleanupTimer?.cancel();
    _reconnectUnsubscribe?.call();
    _memberKickedDisposer?.call();
    _socketService.leaveLeague(leagueId);
    _socketHandler.dispose();
    _idempotency.clearPrefix('draft.pick:$draftId:');
    _idempotency.clearPrefix('draft.pickAsset:$draftId:');
    _idempotency.clearPrefix('auction.nominate:$draftId:');
    _idempotency.clearPrefix('auction.maxBid:$draftId:');
    _idempotency.clearPrefix('auction.bid:');
    super.dispose();
  }
}

final draftRoomProvider = StateNotifierProvider.autoDispose
    .family<DraftRoomNotifier, DraftRoomState, DraftRoomKey>(
  (ref, key) {
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;

    final notifier = DraftRoomNotifier(
      ref.watch(draftRepositoryProvider),
      ref.watch(playerRepositoryProvider),
      ref.watch(draftPickAssetRepositoryProvider),
      ref.watch(leagueRepositoryProvider),
      ref.watch(socketServiceProvider),
      ref.read(actionIdempotencyProvider.notifier),
      currentUserId,
      key.leagueId,
      key.draftId,
    );

    // Fetch commissioner status from league context
    final leagueContext = ref.watch(leagueContextProvider(key.leagueId));
    leagueContext.whenData((context) {
      notifier.setCommissioner(context.isCommissioner);
    });

    return notifier;
  },
);
