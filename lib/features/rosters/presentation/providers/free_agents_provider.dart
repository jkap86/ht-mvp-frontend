import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../players/domain/player.dart';
import '../../data/roster_repository.dart';

class FreeAgentsState {
  final List<Player> players;
  final String? selectedPosition;
  final String searchQuery;
  final bool isLoading;
  final String? error;
  final bool isAddingPlayer;
  final int? addingPlayerId;
  final bool isForbidden;
  final DateTime? lastUpdated;

  FreeAgentsState({
    this.players = const [],
    this.selectedPosition,
    this.searchQuery = '',
    this.isLoading = true,
    this.error,
    this.isAddingPlayer = false,
    this.addingPlayerId,
    this.isForbidden = false,
    this.lastUpdated,
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Get filtered players based on position and search
  List<Player> get filteredPlayers {
    var result = players;

    if (selectedPosition != null) {
      result = result.where((p) => p.position == selectedPosition).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        final name = p.fullName.toLowerCase();
        final team = (p.team ?? '').toLowerCase();
        return name.contains(query) || team.contains(query);
      }).toList();
    }

    return result;
  }

  FreeAgentsState copyWith({
    List<Player>? players,
    String? selectedPosition,
    bool clearPosition = false,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isAddingPlayer,
    int? addingPlayerId,
    bool clearAddingPlayer = false,
    bool? isForbidden,
    DateTime? lastUpdated,
  }) {
    return FreeAgentsState(
      players: players ?? this.players,
      selectedPosition: clearPosition ? null : (selectedPosition ?? this.selectedPosition),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAddingPlayer: isAddingPlayer ?? this.isAddingPlayer,
      addingPlayerId: clearAddingPlayer ? null : (addingPlayerId ?? this.addingPlayerId),
      isForbidden: isForbidden ?? this.isForbidden,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class FreeAgentsNotifier extends StateNotifier<FreeAgentsState> {
  final RosterRepository _rosterRepo;
  final InvalidationService _invalidationService;
  final int leagueId;
  final int rosterId;

  VoidCallback? _invalidationDisposer;

  FreeAgentsNotifier(
    this._rosterRepo,
    this._invalidationService,
    this.leagueId,
    this.rosterId,
  ) : super(FreeAgentsState()) {
    _registerInvalidationCallback();
    loadData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.freeAgents,
      leagueId,
      loadData,
    );
  }

  @override
  void dispose() {
    _invalidationDisposer?.call();
    super.dispose();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final players = await _rosterRepo.getFreeAgents(
        leagueId,
        position: state.selectedPosition,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        limit: 100,
      );

      state = state.copyWith(
        players: players,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } on ForbiddenException {
      state = state.copyWith(isForbidden: true, isLoading: false, players: []);
    } catch (e) {
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  /// Filter by position
  void setPosition(String? position) {
    if (position == state.selectedPosition) return;

    if (position == null) {
      state = state.copyWith(clearPosition: true);
    } else {
      state = state.copyWith(selectedPosition: position);
    }
    loadData();
  }

  /// Search by name
  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    // Don't reload on every keystroke - let the UI filter locally
  }

  /// Search and reload from server
  void searchAndReload(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  /// Add a player to the roster with optimistic update and rollback on failure
  Future<bool> addPlayer(int playerId, {String? idempotencyKey}) async {
    // Save state for rollback
    final previousState = state;
    final playerName = state.players.where((p) => p.id == playerId).firstOrNull?.fullName ?? 'Player';

    // Optimistic update - remove player from list immediately
    state = state.copyWith(
      isAddingPlayer: true,
      addingPlayerId: playerId,
      players: state.players.where((p) => p.id != playerId).toList(),
    );

    try {
      await _rosterRepo.addPlayer(leagueId, rosterId, playerId, idempotencyKey: idempotencyKey);

      // Success - just clear loading state
      state = state.copyWith(
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );

      // Trigger cross-provider invalidation
      _invalidationService.invalidate(InvalidationEvent.playerAdded, leagueId);

      return true;
    } catch (e) {
      // ROLLBACK: Restore previous state on failure
      final baseError = ErrorSanitizer.sanitize(e);
      String errorMsg;
      if (baseError.contains('full') || baseError.contains('capacity') || baseError.contains('max')) {
        errorMsg = 'Cannot add $playerName: Your roster is full. Drop a player first.';
      } else if (baseError.contains('already on') || baseError.contains('already owned')) {
        errorMsg = '$playerName is already on a roster.';
      } else {
        errorMsg = 'Failed to add $playerName: $baseError';
      }

      state = previousState.copyWith(
        error: errorMsg,
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );
      return false;
    }
  }

  /// Add a player and drop another in the same transaction with optimistic update
  Future<bool> addDropPlayer(int addPlayerId, int dropPlayerId, {String? idempotencyKey}) async {
    // Save state for rollback
    final previousState = state;
    final playerName = state.players.where((p) => p.id == addPlayerId).firstOrNull?.fullName ?? 'Player';

    // Optimistic update - remove added player from list
    state = state.copyWith(
      isAddingPlayer: true,
      addingPlayerId: addPlayerId,
      players: state.players.where((p) => p.id != addPlayerId).toList(),
    );

    try {
      await _rosterRepo.addDropPlayer(leagueId, rosterId, addPlayerId, dropPlayerId, idempotencyKey: idempotencyKey);

      // Success - just clear loading state
      state = state.copyWith(
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );

      // Trigger cross-provider invalidation for both add and drop
      _invalidationService.invalidate(InvalidationEvent.playerAdded, leagueId);
      _invalidationService.invalidate(InvalidationEvent.playerDropped, leagueId);

      return true;
    } catch (e) {
      // ROLLBACK: Restore previous state on failure
      final baseError = ErrorSanitizer.sanitize(e);
      String errorMsg;
      if (baseError.contains('not on') || baseError.contains('not found')) {
        errorMsg = 'The player to drop is no longer on your roster. Try refreshing.';
      } else if (baseError.contains('already on') || baseError.contains('already owned')) {
        errorMsg = '$playerName is already on a roster.';
      } else {
        errorMsg = 'Failed to add $playerName: $baseError';
      }

      state = previousState.copyWith(
        error: errorMsg,
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Key for free agents provider
typedef FreeAgentsKey = ({int leagueId, int rosterId});

final freeAgentsProvider =
    StateNotifierProvider.autoDispose.family<FreeAgentsNotifier, FreeAgentsState, FreeAgentsKey>(
  (ref, key) => FreeAgentsNotifier(
    ref.watch(rosterRepositoryProvider),
    ref.watch(invalidationServiceProvider),
    key.leagueId,
    key.rosterId,
  ),
);
