import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/league_context_provider.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../leagues/domain/league.dart';
import '../../../players/data/player_repository.dart';
import '../../../players/domain/player.dart';
import '../../data/draft_pick_asset_repository.dart';
import '../../data/draft_repository.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import '../../domain/draft_order_entry.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';
import '../../domain/draft_status.dart';
import '../../domain/draft_type.dart';
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

  DraftRoomState({
    this.draft,
    this.players = const [],
    this.picks = const [],
    this.draftOrder = const [],
    this.currentUserId,
    this.isLoading = true,
    this.error,
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
  });

  bool get isAuction => draft?.draftType == DraftType.auction;
  bool get isFastAuction => isAuction && auctionMode == 'fast';

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
    final myEntry = draftOrder
        .where((entry) => entry.rosterId == myRosterId)
        .firstOrNull;
    return myEntry?.isAutodraftEnabled ?? false;
  }

  List<DraftOrderEntry> get currentRoundOrder {
    final d = draft;
    if (d == null || draftOrder.isEmpty) return draftOrder;
    final isSnake = d.draftType == DraftType.snake;
    final currentRound = (d.currentRound ?? 1).clamp(1, d.rounds);
    final isReversed = isSnake && currentRound % 2 == 0;
    return isReversed ? draftOrder.reversed.toList() : draftOrder;
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
    List<AuctionLot>? activeLots,
    List<AuctionBudget>? budgets,
    OutbidNotification? outbidNotification,
    bool clearOutbidNotification = false,
    String? auctionMode,
    int? currentNominatorRosterId,
    int? nominationNumber,
    DateTime? nominationDeadline,
    int? dailyNominationsRemaining,
    int? dailyNominationLimit,
    bool? globalCapReached,
    AuctionSettings? auctionSettings,
    List<DraftPickAsset>? pickAssets,
    List<DraftPickAsset>? availablePickAssets,
    bool? includeRookiePicks,
    int? rookiePicksSeason,
    bool? teamsOnXAxis,
    bool? isCommissioner,
  }) {
    return DraftRoomState(
      draft: draft ?? this.draft,
      players: players ?? this.players,
      picks: picks ?? this.picks,
      draftOrder: draftOrder ?? this.draftOrder,
      currentUserId: currentUserId ?? this.currentUserId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeLots: activeLots ?? this.activeLots,
      budgets: budgets ?? this.budgets,
      outbidNotification: clearOutbidNotification
          ? null
          : (outbidNotification ?? this.outbidNotification),
      auctionMode: auctionMode ?? this.auctionMode,
      currentNominatorRosterId:
          currentNominatorRosterId ?? this.currentNominatorRosterId,
      nominationNumber: nominationNumber ?? this.nominationNumber,
      nominationDeadline: nominationDeadline ?? this.nominationDeadline,
      dailyNominationsRemaining:
          dailyNominationsRemaining ?? this.dailyNominationsRemaining,
      dailyNominationLimit: dailyNominationLimit ?? this.dailyNominationLimit,
      globalCapReached: globalCapReached ?? this.globalCapReached,
      auctionSettings: auctionSettings ?? this.auctionSettings,
      pickAssets: pickAssets ?? this.pickAssets,
      availablePickAssets: availablePickAssets ?? this.availablePickAssets,
      includeRookiePicks: includeRookiePicks ?? this.includeRookiePicks,
      rookiePicksSeason: rookiePicksSeason ?? this.rookiePicksSeason,
      teamsOnXAxis: teamsOnXAxis ?? this.teamsOnXAxis,
      isCommissioner: isCommissioner ?? this.isCommissioner,
    );
  }
}

typedef DraftRoomKey = ({int leagueId, int draftId});

class DraftRoomNotifier extends StateNotifier<DraftRoomState>
    implements DraftSocketCallbacks {
  final DraftRepository _draftRepo;
  final PlayerRepository _playerRepo;
  final DraftPickAssetRepository _pickAssetRepo;
  final SocketService _socketService;
  final int leagueId;
  final int draftId;

  late final DraftSocketHandler _socketHandler;
  Timer? _budgetRefreshTimer;
  VoidCallback? _reconnectUnsubscribe;

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
    this._socketService,
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

    loadData();
  }

  /// Handle socket reconnection - refresh state if disconnected too long
  void _onSocketReconnected(bool needsFullRefresh) {
    if (!mounted) return;

    if (needsFullRefresh) {
      // Long disconnect (>30s) - do a full reload to ensure consistency
      debugPrint('DraftRoom: Socket reconnected after long disconnect, refreshing all data');
      loadData();
    } else {
      // Short disconnect - just resync draft state and picks
      debugPrint('DraftRoom: Socket reconnected, doing lightweight resync');
      _refreshDraftState();
      if (state.isAuction) {
        loadAuctionData();
      }
    }
  }

  // Socket callback implementations
  @override
  void onPickReceived(DraftPick pick) {
    if (!mounted) return;
    // Dedupe: prevent duplicate picks from socket replays or reconnection
    if (state.picks.any((p) => p.id == pick.id)) return;
    // Add pick and sort by pickNumber to handle out-of-order socket events
    final updatedPicks = [...state.picks, pick]
      ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    state = state.copyWith(picks: updatedPicks);
  }

  @override
  void onNextPickReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    final currentDraft = state.draft;
    if (currentDraft != null) {
      final statusStr = data['status'] as String?;
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
      );
    }
  }

  @override
  void onDraftCompletedReceived(Map<String, dynamic> data) {
    if (!mounted) return;
    state = state.copyWith(draft: Draft.fromJson(data));
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
  void onLotCreatedReceived(AuctionLot lot) {
    if (!mounted) return;
    _upsertAndSortLot(lot);
  }

  @override
  void onLotUpdatedReceived(AuctionLot lot) {
    if (!mounted) return;
    state = state.copyWith(
      activeLots: state.activeLots.map((l) {
        if (l.id == lot.id) {
          // Preserve user's myMaxBid when merging socket update
          // (socket broadcasts don't include user-specific data)
          return lot.copyWith(myMaxBid: l.myMaxBid);
        }
        return l;
      }).toList(),
    );

    // Debounce budget refresh to avoid spamming API during rapid bidding
    // Using 200ms for faster UI responsiveness in fast auctions
    _budgetRefreshTimer?.cancel();
    _budgetRefreshTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) loadAuctionData();
    });
  }

  @override
  void onLotWonReceived(int lotId) {
    if (!mounted) return;
    state = state.copyWith(
      activeLots: state.activeLots.where((l) => l.id != lotId).toList(),
    );
    if (mounted) loadAuctionData();
  }

  @override
  void onLotPassedReceived(int lotId) {
    if (!mounted) return;
    state = state.copyWith(
      activeLots: state.activeLots.where((l) => l.id != lotId).toList(),
    );
  }

  @override
  void onOutbidReceived(OutbidNotification notification) {
    if (!mounted) return;
    state = state.copyWith(outbidNotification: notification);
  }

  @override
  void onNominatorChangedReceived(int? rosterId, int? nominationNumber, DateTime? nominationDeadline) {
    if (!mounted) return;
    state = state.copyWith(
      currentNominatorRosterId: rosterId,
      nominationNumber: nominationNumber,
      nominationDeadline: nominationDeadline,
    );
  }

  @override
  void onAuctionErrorReceived(String message) {
    if (!mounted) return;
    state = state.copyWith(error: message);
  }

  // Data loading methods
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final draft = await _draftRepo.getDraft(leagueId, draftId);

      // Extract playerPool from draft settings for filtering players
      final playerPool = _extractPlayerPool(draft.rawSettings);

      // Extract includeRookiePicks settings
      final includeRookiePicks = draft.rawSettings?['includeRookiePicks'] as bool? ?? false;
      final rookiePicksSeason = draft.rawSettings?['rookiePicksSeason'] as int?;

      final results = await Future.wait<dynamic>([
        _playerRepo.getPlayers(playerPool: playerPool).catchError((e) => <Player>[]),
        _draftRepo.getDraftOrder(leagueId, draftId).catchError((e) => <Map<String, dynamic>>[]),
        _draftRepo.getDraftPicks(leagueId, draftId).catchError((e) => <Map<String, dynamic>>[]),
        _pickAssetRepo.getLeaguePickAssets(leagueId).catchError((e) => <DraftPickAsset>[]),
      ]);

      final players = results[0] as List<Player>;
      final orderData = results[1] as List<Map<String, dynamic>>;
      final picksData = results[2] as List<Map<String, dynamic>>;
      final pickAssets = results[3] as List<DraftPickAsset>;

      final draftOrder = orderData.map((e) => DraftOrderEntry.fromJson(e)).toList();
      final picks = picksData.map((e) => DraftPick.fromJson(e)).toList()
        ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));

      if (!mounted) return;

      state = state.copyWith(
        draft: draft,
        players: players,
        draftOrder: draftOrder,
        picks: picks,
        pickAssets: pickAssets,
        includeRookiePicks: includeRookiePicks,
        rookiePicksSeason: rookiePicksSeason,
        isLoading: false,
      );

      if (mounted && draft.draftType == DraftType.auction) {
        loadAuctionData();
      }

      // Load available pick assets for vet drafts with includeRookiePicks enabled
      if (mounted && includeRookiePicks) {
        loadAvailablePickAssets();
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
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
      debugPrint('Failed to load available pick assets: $e');
    }
  }

  Future<void> loadAuctionData() async {
    if (state.draft?.draftType != DraftType.auction) return;
    try {
      final auctionState = await _draftRepo.getAuctionState(leagueId, draftId);
      if (!mounted) return;
      state = state.copyWith(
        activeLots: auctionState.activeLots,
        budgets: auctionState.budgets,
        auctionMode: auctionState.auctionMode,
        currentNominatorRosterId: auctionState.currentNominatorRosterId,
        nominationNumber: auctionState.nominationNumber,
        nominationDeadline: auctionState.nominationDeadline,
        dailyNominationsRemaining: auctionState.dailyNominationsRemaining,
        dailyNominationLimit: auctionState.dailyNominationLimit,
        globalCapReached: auctionState.globalCapReached,
        auctionSettings: auctionState.settings,
      );
    } catch (e) {
      // Auction data is supplemental - log for debugging but don't block UI
      debugPrint('Failed to load auction data: $e');
      // Still update state with error for potential UI feedback
      if (mounted) {
        state = state.copyWith(error: 'Failed to load auction data');
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
      state = state.copyWith(draft: draft, picks: picks);
    } catch (e) {
      // Resync failed silently - socket events are primary update mechanism
    }
  }

  // Action methods
  Future<String?> makePick(int playerId) async {
    try {
      await _draftRepo.makePick(leagueId, draftId, playerId);
      // Resync to ensure UI is updated even if socket event was missed
      if (mounted) await _refreshDraftState();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Make a pick using a draft pick asset instead of a player
  Future<String?> makePickAssetSelection(int pickAssetId) async {
    try {
      await _draftRepo.makePickAssetSelection(leagueId, draftId, pickAssetId);
      // Resync state and reload available pick assets
      if (mounted) {
        await _refreshDraftState();
        await loadAvailablePickAssets();
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> nominate(int playerId) async {
    try {
      final lot = await _draftRepo.nominate(leagueId, draftId, playerId);
      // Immediately add the new lot to state (don't wait for WebSocket)
      // Use upsert to prevent duplicates if socket message arrives first
      if (mounted) {
        _upsertAndSortLot(lot);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> setMaxBid(int lotId, int maxBid) async {
    // Save previous myMaxBid for this specific lot (for targeted rollback)
    final previousMaxBid = state.activeLots
        .where((l) => l.id == lotId)
        .firstOrNull
        ?.myMaxBid;

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
      await _draftRepo.setMaxBid(leagueId, draftId, lotId, maxBid);
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
      return e.toString();
    }
  }

  void clearOutbidNotification() {
    state = state.copyWith(clearOutbidNotification: true);
  }

  /// Toggle the grid axis orientation
  void toggleGridAxis() {
    state = state.copyWith(teamsOnXAxis: !state.teamsOnXAxis);
  }

  /// Toggle autodraft for the current user
  Future<String?> toggleAutodraft(bool enabled) async {
    try {
      await _draftRepo.toggleAutodraft(leagueId, draftId, enabled);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Start the draft (commissioner only)
  Future<String?> startDraft() async {
    try {
      final updatedDraft = await _draftRepo.startDraft(leagueId, draftId);
      if (mounted) {
        state = state.copyWith(draft: updatedDraft);
      }
      return null;
    } catch (e) {
      return e.toString();
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
      return e.toString();
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
      return e.toString();
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
  }

  @override
  void onPickTradedReceived(DraftPickAsset pickAsset) {
    if (!mounted) return;
    // Update or add the pick asset in the state
    final existingIndex = state.pickAssets.indexWhere((a) => a.id == pickAsset.id);
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

  @override
  void dispose() {
    _budgetRefreshTimer?.cancel();
    _reconnectUnsubscribe?.call();
    _socketHandler.dispose();
    super.dispose();
  }
}

final draftRoomProvider =
    StateNotifierProvider.autoDispose.family<DraftRoomNotifier, DraftRoomState, DraftRoomKey>(
  (ref, key) {
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;

    final notifier = DraftRoomNotifier(
      ref.watch(draftRepositoryProvider),
      ref.watch(playerRepositoryProvider),
      ref.watch(draftPickAssetRepositoryProvider),
      ref.watch(socketServiceProvider),
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
