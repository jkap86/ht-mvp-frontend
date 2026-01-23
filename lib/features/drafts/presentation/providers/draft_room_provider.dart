import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../leagues/domain/league.dart';
import '../../../players/data/player_repository.dart';
import '../../../players/domain/player.dart';
import '../../data/draft_repository.dart';
import '../../domain/draft_order_entry.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_status.dart';

class DraftRoomState {
  final Draft? draft;
  final List<Player> players;
  final List<DraftPick> picks;
  final List<DraftOrderEntry> draftOrder;
  final int? currentUserId;
  final bool isLoading;
  final String? error;

  DraftRoomState({
    this.draft,
    this.players = const [],
    this.picks = const [],
    this.draftOrder = const [],
    this.currentUserId,
    this.isLoading = true,
    this.error,
  });

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
    final isSnake = draft!.draftType == 'snake';
    final isReversed = isSnake && (draft!.currentRound ?? 1) % 2 == 0;
    return isReversed ? draftOrder.reversed.toList() : draftOrder;
  }

  DraftRoomState copyWith({
    Draft? draft,
    List<Player>? players,
    List<DraftPick>? picks,
    List<DraftOrderEntry>? draftOrder,
    int? currentUserId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DraftRoomState(
      draft: draft ?? this.draft,
      players: players ?? this.players,
      picks: picks ?? this.picks,
      draftOrder: draftOrder ?? this.draftOrder,
      currentUserId: currentUserId ?? this.currentUserId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Composite key for DraftRoomProvider
typedef DraftRoomKey = ({int leagueId, int draftId});

class DraftRoomNotifier extends StateNotifier<DraftRoomState> {
  final DraftRepository _draftRepo;
  final PlayerRepository _playerRepo;
  final SocketService _socketService;
  final int? _currentUserId;
  final int leagueId;
  final int draftId;

  // Store disposers for proper cleanup - removes only these listeners, not all listeners
  VoidCallback? _pickDisposer;
  VoidCallback? _nextPickDisposer;
  VoidCallback? _completedDisposer;
  VoidCallback? _pickUndoneDisposer;

  DraftRoomNotifier(
    this._draftRepo,
    this._playerRepo,
    this._socketService,
    this._currentUserId,
    this.leagueId,
    this.draftId,
  ) : super(DraftRoomState(currentUserId: _currentUserId)) {
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

  @override
  void dispose() {
    _socketService.leaveDraft(draftId);
    // Remove only this notifier's listeners, not all listeners globally
    _pickDisposer?.call();
    _nextPickDisposer?.call();
    _completedDisposer?.call();
    _pickUndoneDisposer?.call();
    super.dispose();
  }
}

final draftRoomProvider =
    StateNotifierProvider.family<DraftRoomNotifier, DraftRoomState, DraftRoomKey>(
  (ref, key) {
    // Get current user ID from auth state
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.user != null ? int.tryParse(authState.user!.id) : null;

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
