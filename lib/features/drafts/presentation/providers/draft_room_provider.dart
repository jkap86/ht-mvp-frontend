import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../leagues/domain/league.dart';
import '../../../players/data/player_repository.dart';
import '../../../players/domain/player.dart';
import '../../data/draft_repository.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/draft_order_entry.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_status.dart';
import '../../domain/draft_type.dart';

/// Notification when user is outbid on a lot
class OutbidNotification {
  final int lotId;
  final int playerId;
  final int newBid;
  final DateTime timestamp;

  OutbidNotification({
    required this.lotId,
    required this.playerId,
    required this.newBid,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DraftRoomState {
  final Draft? draft;
  final List<Player> players;
  final List<DraftPick> picks;
  final List<DraftOrderEntry> draftOrder;
  final String? currentUserId;  // UUID string from auth
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
  });

  /// Check if this is an auction draft
  bool get isAuction => draft?.draftType == DraftType.auction;

  /// Check if this is a fast auction
  bool get isFastAuction => isAuction && auctionMode == 'fast';

  /// Check if it's the current user's turn to nominate (fast auction)
  bool get isMyNomination {
    if (!isFastAuction || myRosterId == null) return false;
    return currentNominatorRosterId == myRosterId;
  }

  /// Get the current nominator from draft order (fast auction)
  DraftOrderEntry? get currentNominator {
    if (currentNominatorRosterId == null || draftOrder.isEmpty) return null;
    return draftOrder
        .where((entry) => entry.rosterId == currentNominatorRosterId)
        .firstOrNull;
  }

  /// Get the current user's budget
  AuctionBudget? get myBudget {
    if (myRosterId == null) return null;
    return budgets.where((b) => b.rosterId == myRosterId).firstOrNull;
  }

  /// Get drafted player IDs as a set for filtering
  Set<int> get draftedPlayerIds => picks.map((p) => p.playerId).toSet();

  /// Get the current picker from draft order
  DraftOrderEntry? get currentPicker {
    if (draft?.currentRosterId == null || draftOrder.isEmpty) return null;
    return draftOrder
        .where((entry) => entry.rosterId == draft!.currentRosterId)
        .firstOrNull;
  }

  /// Check if it's the current user's turn to pick
  bool get isMyTurn {
    if (currentUserId == null || currentPicker == null) return false;
    return currentPicker!.userId == currentUserId;
  }

  /// Get the current user's roster ID
  int? get myRosterId {
    if (currentUserId == null || draftOrder.isEmpty) return null;
    return draftOrder
        .where((entry) => entry.userId == currentUserId)
        .firstOrNull
        ?.rosterId;
  }

  /// Get picks made by the current user
  List<DraftPick> get myPicks {
    if (myRosterId == null) return [];
    return picks.where((pick) => pick.rosterId == myRosterId).toList();
  }

  /// Get the draft order for current round (respects snake order)
  List<DraftOrderEntry> get currentRoundOrder {
    if (draft == null || draftOrder.isEmpty) return draftOrder;
    final isSnake = draft!.draftType == DraftType.snake;
    final isReversed = isSnake && (draft!.currentRound ?? 1) % 2 == 0;
    return isReversed ? draftOrder.reversed.toList() : draftOrder;
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
      outbidNotification: clearOutbidNotification ? null : (outbidNotification ?? this.outbidNotification),
      auctionMode: auctionMode ?? this.auctionMode,
      currentNominatorRosterId: currentNominatorRosterId ?? this.currentNominatorRosterId,
      nominationNumber: nominationNumber ?? this.nominationNumber,
    );
  }
}

/// Composite key for DraftRoomProvider
typedef DraftRoomKey = ({int leagueId, int draftId});

class DraftRoomNotifier extends StateNotifier<DraftRoomState> {
  final DraftRepository _draftRepo;
  final PlayerRepository _playerRepo;
  final SocketService _socketService;
  final int leagueId;
  final int draftId;

  // Store disposers for proper cleanup - removes only these listeners, not all listeners
  VoidCallback? _pickDisposer;
  VoidCallback? _nextPickDisposer;
  VoidCallback? _completedDisposer;
  VoidCallback? _pickUndoneDisposer;
  VoidCallback? _pausedDisposer;
  VoidCallback? _resumedDisposer;
  // Auction disposers
  VoidCallback? _lotCreatedDisposer;
  VoidCallback? _lotUpdatedDisposer;
  VoidCallback? _lotWonDisposer;
  VoidCallback? _lotPassedDisposer;
  VoidCallback? _outbidDisposer;
  VoidCallback? _nominatorChangedDisposer;

  DraftRoomNotifier(
    this._draftRepo,
    this._playerRepo,
    this._socketService,
    String? currentUserId,
    this.leagueId,
    this.draftId,
  ) : super(DraftRoomState(currentUserId: currentUserId)) {
    _setupSocketListeners();
    loadData();
  }

  void _setupSocketListeners() {
    _socketService.joinDraft(draftId);

    _pickDisposer = _socketService.onDraftPick((data) {
      if (!mounted) return;
      final pick = DraftPick.fromJson(Map<String, dynamic>.from(data));
      state = state.copyWith(
        picks: [...state.picks, pick],
      );
    });

    _nextPickDisposer = _socketService.onNextPick((data) {
      if (!mounted) return;
      final currentDraft = state.draft;
      if (currentDraft != null) {
        final statusStr = data['status'] as String?;
        state = state.copyWith(
          draft: currentDraft.copyWith(
            status: statusStr != null ? DraftStatus.fromString(statusStr) : null,
            currentPick: data['currentPick'] as int?,
            currentRound: data['currentRound'] as int?,
            currentRosterId: data['currentRosterId'] as int?,
            pickDeadline: data['pickDeadline'] != null
                ? DateTime.tryParse(data['pickDeadline'].toString())
                : null,
          ),
        );
      }
    });

    _completedDisposer = _socketService.onDraftCompleted((data) {
      if (!mounted) return;
      state = state.copyWith(draft: Draft.fromJson(data));
    });

    _pickUndoneDisposer = _socketService.onPickUndone((data) {
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
    });

    _pausedDisposer = _socketService.onDraftPaused((data) {
      if (!mounted) return;
      final currentDraft = state.draft;
      if (currentDraft != null) {
        state = state.copyWith(
          draft: currentDraft.copyWith(status: DraftStatus.paused),
        );
      }
    });

    _resumedDisposer = _socketService.onDraftResumed((data) {
      if (!mounted) return;
      final currentDraft = state.draft;
      if (currentDraft != null) {
        state = state.copyWith(
          draft: currentDraft.copyWith(status: DraftStatus.inProgress),
        );
      }
    });

    // Auction socket listeners
    _lotCreatedDisposer = _socketService.onAuctionLotCreated((data) {
      if (!mounted) return;
      final lot = AuctionLot.fromJson(Map<String, dynamic>.from(data['lot'] ?? data));
      state = state.copyWith(
        activeLots: [...state.activeLots, lot],
      );
    });

    _lotUpdatedDisposer = _socketService.onAuctionLotUpdated((data) {
      if (!mounted) return;
      final lot = AuctionLot.fromJson(Map<String, dynamic>.from(data['lot'] ?? data));
      state = state.copyWith(
        activeLots: state.activeLots.map((l) => l.id == lot.id ? lot : l).toList(),
      );
    });

    _lotWonDisposer = _socketService.onAuctionLotWon((data) {
      if (!mounted) return;
      final lotId = data['lot_id'] as int? ?? data['lotId'] as int?;
      if (lotId != null) {
        // Remove from active lots, add to picks will happen via pick_made event
        state = state.copyWith(
          activeLots: state.activeLots.where((l) => l.id != lotId).toList(),
        );
      }
      // Refresh budgets
      loadAuctionData();
    });

    _lotPassedDisposer = _socketService.onAuctionLotPassed((data) {
      if (!mounted) return;
      final lotId = data['lot_id'] as int? ?? data['lotId'] as int?;
      if (lotId != null) {
        state = state.copyWith(
          activeLots: state.activeLots.where((l) => l.id != lotId).toList(),
        );
      }
    });

    _outbidDisposer = _socketService.onAuctionOutbid((data) {
      if (!mounted) return;
      // Set outbid notification for UI to display toast
      final notification = OutbidNotification(
        lotId: data['lotId'] as int? ?? data['lot_id'] as int? ?? 0,
        playerId: data['playerId'] as int? ?? data['player_id'] as int? ?? 0,
        newBid: data['newBid'] as int? ?? data['new_bid'] as int? ?? 0,
      );
      state = state.copyWith(outbidNotification: notification);
    });

    // Fast auction nominator change listener
    _nominatorChangedDisposer = _socketService.onAuctionNominatorChanged((data) {
      if (!mounted) return;
      state = state.copyWith(
        currentNominatorRosterId: data['nominatorRosterId'] as int?,
        nominationNumber: data['nominationNumber'] as int?,
      );
    });
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Draft is required - fetch it first
      final draft = await _draftRepo.getDraft(leagueId, draftId);

      // Fetch remaining data in parallel with individual error handling
      final results = await Future.wait<dynamic>([
        _playerRepo.getPlayers().catchError((e) => <Player>[]),
        _draftRepo.getDraftOrder(leagueId, draftId).catchError((e) => <Map<String, dynamic>>[]),
        _draftRepo.getDraftPicks(leagueId, draftId).catchError((e) => <Map<String, dynamic>>[]),
      ]);

      final players = results[0] as List<Player>;
      final orderData = results[1] as List<Map<String, dynamic>>;
      final picksData = results[2] as List<Map<String, dynamic>>;

      final draftOrder = orderData.map((e) => DraftOrderEntry.fromJson(e)).toList();
      final picks = picksData.map((e) => DraftPick.fromJson(e)).toList();

      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(
        draft: draft,
        players: players,
        draftOrder: draftOrder,
        picks: picks,
        isLoading: false,
      );

      // Load auction data if this is an auction draft
      if (draft.draftType == DraftType.auction) {
        loadAuctionData();
      }
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> makePick(int playerId) async {
    try {
      await _draftRepo.makePick(leagueId, draftId, playerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Auction methods
  Future<void> loadAuctionData() async {
    if (state.draft?.draftType != DraftType.auction) return;
    try {
      // Use auction state endpoint which returns all data including fast auction fields
      final auctionState = await _draftRepo.getAuctionState(leagueId, draftId);
      if (!mounted) return;
      state = state.copyWith(
        activeLots: auctionState.activeLots,
        budgets: auctionState.budgets,
        auctionMode: auctionState.auctionMode,
        currentNominatorRosterId: auctionState.currentNominatorRosterId,
        nominationNumber: auctionState.nominationNumber,
      );
    } catch (e) {
      // Silently fail - auction data is supplemental
    }
  }

  Future<bool> nominate(int playerId) async {
    try {
      await _draftRepo.nominate(leagueId, draftId, playerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setMaxBid(int lotId, int maxBid) async {
    try {
      await _draftRepo.setMaxBid(leagueId, draftId, lotId, maxBid);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear the outbid notification after UI has shown it
  void clearOutbidNotification() {
    state = state.copyWith(clearOutbidNotification: true);
  }

  @override
  void dispose() {
    _socketService.leaveDraft(draftId);
    // Remove only this notifier's listeners, not all listeners globally
    _pickDisposer?.call();
    _nextPickDisposer?.call();
    _completedDisposer?.call();
    _pickUndoneDisposer?.call();
    _pausedDisposer?.call();
    _resumedDisposer?.call();
    // Auction disposers
    _lotCreatedDisposer?.call();
    _lotUpdatedDisposer?.call();
    _lotWonDisposer?.call();
    _lotPassedDisposer?.call();
    _outbidDisposer?.call();
    _nominatorChangedDisposer?.call();
    super.dispose();
  }
}

final draftRoomProvider =
    StateNotifierProvider.family<DraftRoomNotifier, DraftRoomState, DraftRoomKey>(
  (ref, key) {
    // Get current user ID from auth state
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user?.id;

    return DraftRoomNotifier(
      ref.watch(draftRepositoryProvider),
      ref.watch(playerRepositoryProvider),
      ref.watch(socketServiceProvider),
      currentUserId,
      key.leagueId,
      key.draftId,
    );
  },
);
