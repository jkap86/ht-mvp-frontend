import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  FreeAgentsState({
    this.players = const [],
    this.selectedPosition,
    this.searchQuery = '',
    this.isLoading = true,
    this.error,
    this.isAddingPlayer = false,
    this.addingPlayerId,
  });

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
  }) {
    return FreeAgentsState(
      players: players ?? this.players,
      selectedPosition: clearPosition ? null : (selectedPosition ?? this.selectedPosition),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isAddingPlayer: isAddingPlayer ?? this.isAddingPlayer,
      addingPlayerId: clearAddingPlayer ? null : (addingPlayerId ?? this.addingPlayerId),
    );
  }
}

class FreeAgentsNotifier extends StateNotifier<FreeAgentsState> {
  final RosterRepository _rosterRepo;
  final int leagueId;
  final int rosterId;

  FreeAgentsNotifier(
    this._rosterRepo,
    this.leagueId,
    this.rosterId,
  ) : super(FreeAgentsState()) {
    loadData();
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
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
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

  /// Add a player to the roster
  Future<bool> addPlayer(int playerId) async {
    state = state.copyWith(isAddingPlayer: true, addingPlayerId: playerId);

    try {
      await _rosterRepo.addPlayer(leagueId, rosterId, playerId);

      // Remove the player from the list
      state = state.copyWith(
        players: state.players.where((p) => p.id != playerId).toList(),
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );
      return false;
    }
  }

  /// Add a player and drop another in the same transaction
  Future<bool> addDropPlayer(int addPlayerId, int dropPlayerId) async {
    state = state.copyWith(isAddingPlayer: true, addingPlayerId: addPlayerId);

    try {
      await _rosterRepo.addDropPlayer(leagueId, rosterId, addPlayerId, dropPlayerId);

      // Remove the added player from the free agents list
      state = state.copyWith(
        players: state.players.where((p) => p.id != addPlayerId).toList(),
        isAddingPlayer: false,
        clearAddingPlayer: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
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
    StateNotifierProvider.family<FreeAgentsNotifier, FreeAgentsState, FreeAgentsKey>(
  (ref, key) => FreeAgentsNotifier(
    ref.watch(rosterRepositoryProvider),
    key.leagueId,
    key.rosterId,
  ),
);
