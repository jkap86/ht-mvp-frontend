import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../data/roster_repository.dart';
import '../../domain/roster_player.dart';
import '../../domain/roster_lineup.dart';

/// Key for team provider - needs leagueId to identify the context
typedef TeamKey = ({int leagueId, int rosterId});

/// Represents a lineup optimization issue
class LineupIssue {
  final LineupSlot slot;
  final RosterPlayer currentPlayer;
  final RosterPlayer suggestedPlayer;
  final double projectionDiff;

  LineupIssue({
    required this.slot,
    required this.currentPlayer,
    required this.suggestedPlayer,
    required this.projectionDiff,
  });
}

class TeamState {
  final League? league;
  final List<RosterPlayer> players;
  final RosterLineup? lineup;
  final int currentWeek;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  TeamState({
    this.league,
    this.players = const [],
    this.lineup,
    this.currentWeek = 1,
    this.isLoading = true,
    this.error,
    this.isSaving = false,
  });

  /// Group players by their lineup slot for display
  Map<LineupSlot, List<RosterPlayer>> get playersBySlot {
    if (lineup == null) return {};

    final result = <LineupSlot, List<RosterPlayer>>{};
    for (final slot in LineupSlot.values) {
      result[slot] = [];
    }

    for (final player in players) {
      final slot = lineup!.lineup.getPlayerSlot(player.playerId);
      if (slot != null) {
        result[slot]!.add(player);
      } else {
        // Player not in lineup yet - add to bench by default
        result[LineupSlot.bn]!.add(player);
      }
    }

    return result;
  }

  /// Get starters (non-bench players)
  List<RosterPlayer> get starters {
    if (lineup == null) return [];
    return players.where((p) => lineup!.lineup.isStarter(p.playerId)).toList();
  }

  /// Get bench players
  List<RosterPlayer> get bench {
    if (lineup == null) return players;
    return players.where((p) => !lineup!.lineup.isStarter(p.playerId)).toList();
  }

  /// Total projected/actual points for starters
  double get totalPoints => lineup?.totalPoints ?? 0.0;

  /// Calculate projected points for starters based on player projections
  double get projectedStarterPoints {
    return starters.fold(0.0, (sum, p) => sum + (p.projectedPoints ?? 0.0));
  }

  /// Find lineup issues (bench players projected higher than starters at same position)
  List<LineupIssue> get lineupIssues {
    final issues = <LineupIssue>[];
    if (lineup == null) return issues;

    // Check each starter slot against bench players
    for (final slot in LineupSlot.values.where((s) => s != LineupSlot.bn)) {
      final startersInSlot = playersBySlot[slot] ?? [];
      final benchPlayers = bench;

      for (final starter in startersInSlot) {
        final starterProj = starter.projectedPoints ?? 0.0;

        // Find bench players who could fill this slot with higher projections
        for (final benchPlayer in benchPlayers) {
          if (slot.canFill(benchPlayer.position)) {
            final benchProj = benchPlayer.projectedPoints ?? 0.0;
            if (benchProj > starterProj) {
              issues.add(LineupIssue(
                slot: slot,
                currentPlayer: starter,
                suggestedPlayer: benchPlayer,
                projectionDiff: benchProj - starterProj,
              ));
            }
          }
        }
      }
    }

    // Sort by projection difference (biggest gains first)
    issues.sort((a, b) => b.projectionDiff.compareTo(a.projectionDiff));
    return issues;
  }

  /// Check if lineup is optimal
  bool get isOptimalLineup => lineupIssues.isEmpty;

  /// Calculate what the optimal lineup would score
  double get optimalProjectedPoints {
    if (players.isEmpty) return 0.0;

    // Simple greedy algorithm: for each slot, pick the highest projected available player
    final used = <int>{};
    var total = 0.0;

    // Process non-flex slots first, then flex
    final slots = [LineupSlot.qb, LineupSlot.rb, LineupSlot.wr, LineupSlot.te,
                   LineupSlot.k, LineupSlot.def, LineupSlot.flex];

    for (final slot in slots) {
      final slotCount = _getSlotCount(slot);
      final eligible = players
          .where((p) => !used.contains(p.playerId) && slot.canFill(p.position))
          .toList()
        ..sort((a, b) => (b.projectedPoints ?? 0).compareTo(a.projectedPoints ?? 0));

      for (var i = 0; i < slotCount && i < eligible.length; i++) {
        used.add(eligible[i].playerId);
        total += eligible[i].projectedPoints ?? 0;
      }
    }

    return total;
  }

  int _getSlotCount(LineupSlot slot) {
    // Default slot counts - could be configured per league
    switch (slot) {
      case LineupSlot.qb: return 1;
      case LineupSlot.rb: return 2;
      case LineupSlot.wr: return 2;
      case LineupSlot.te: return 1;
      case LineupSlot.flex: return 1;
      case LineupSlot.k: return 1;
      case LineupSlot.def: return 1;
      case LineupSlot.bn: return 99; // unlimited
    }
  }

  TeamState copyWith({
    League? league,
    List<RosterPlayer>? players,
    RosterLineup? lineup,
    int? currentWeek,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return TeamState(
      league: league ?? this.league,
      players: players ?? this.players,
      lineup: lineup ?? this.lineup,
      currentWeek: currentWeek ?? this.currentWeek,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final RosterRepository _rosterRepo;
  final LeagueRepository _leagueRepo;
  final int leagueId;
  final int rosterId;

  TeamNotifier(
    this._rosterRepo,
    this._leagueRepo,
    this.leagueId,
    this.rosterId,
  ) : super(TeamState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load league info first to get current week
      final league = await _leagueRepo.getLeague(leagueId);
      final currentWeek = league.currentWeek;

      // Load roster players
      final players = await _rosterRepo.getRosterPlayers(leagueId, rosterId);

      // Try to load lineup (may not exist yet)
      RosterLineup? lineup;
      try {
        lineup = await _rosterRepo.getLineup(leagueId, rosterId, currentWeek);
      } catch (_) {
        // Lineup doesn't exist yet - that's OK
      }

      state = state.copyWith(
        league: league,
        players: players,
        lineup: lineup,
        currentWeek: currentWeek,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Change the week being viewed
  Future<void> changeWeek(int week) async {
    if (week == state.currentWeek) return;

    state = state.copyWith(isLoading: true, currentWeek: week);

    try {
      final lineup = await _rosterRepo.getLineup(leagueId, rosterId, week);
      state = state.copyWith(
        lineup: lineup,
        isLoading: false,
      );
    } catch (e) {
      // Lineup may not exist yet for future weeks - that's OK
      state = state.copyWith(
        lineup: null,
        isLoading: false,
      );
    }
  }

  /// Move a player to a different lineup slot
  Future<bool> movePlayer(int playerId, String toSlot) async {
    if (state.lineup?.isLocked == true) {
      state = state.copyWith(error: 'Lineup is locked for this week');
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final updatedLineup = await _rosterRepo.movePlayer(
        leagueId,
        rosterId,
        state.currentWeek,
        playerId,
        toSlot,
      );

      state = state.copyWith(
        lineup: updatedLineup,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSaving: false,
      );
      return false;
    }
  }

  /// Save the entire lineup
  Future<bool> saveLineup(LineupSlots lineup) async {
    if (state.lineup?.isLocked == true) {
      state = state.copyWith(error: 'Lineup is locked for this week');
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      final updatedLineup = await _rosterRepo.setLineup(
        leagueId,
        rosterId,
        state.currentWeek,
        lineup,
      );

      state = state.copyWith(
        lineup: updatedLineup,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSaving: false,
      );
      return false;
    }
  }

  /// Drop a player from the roster
  Future<bool> dropPlayer(int playerId) async {
    state = state.copyWith(isSaving: true);

    try {
      await _rosterRepo.dropPlayer(leagueId, rosterId, playerId);

      // Remove from local state
      state = state.copyWith(
        players: state.players.where((p) => p.playerId != playerId).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSaving: false,
      );
      return false;
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Set the optimal lineup automatically based on projections
  Future<bool> setOptimalLineup() async {
    if (state.lineup?.isLocked == true) {
      state = state.copyWith(error: 'Lineup is locked for this week');
      return false;
    }

    if (state.players.isEmpty) {
      state = state.copyWith(error: 'No players on roster');
      return false;
    }

    state = state.copyWith(isSaving: true);

    try {
      // Build optimal lineup using greedy algorithm
      final used = <int>{};
      final newLineup = <String, List<int>>{
        'QB': [],
        'RB': [],
        'WR': [],
        'TE': [],
        'FLEX': [],
        'K': [],
        'DEF': [],
        'BN': [],
      };

      // Process slots in order: position-specific first, then flex
      final slotOrder = [
        (slot: 'QB', positions: ['QB'], count: 1),
        (slot: 'RB', positions: ['RB'], count: 2),
        (slot: 'WR', positions: ['WR'], count: 2),
        (slot: 'TE', positions: ['TE'], count: 1),
        (slot: 'K', positions: ['K'], count: 1),
        (slot: 'DEF', positions: ['DEF'], count: 1),
        (slot: 'FLEX', positions: ['RB', 'WR', 'TE'], count: 1),
      ];

      for (final config in slotOrder) {
        final eligible = state.players
            .where((p) =>
                !used.contains(p.playerId) &&
                config.positions.contains(p.position?.toUpperCase()))
            .toList()
          ..sort((a, b) =>
              (b.projectedPoints ?? 0).compareTo(a.projectedPoints ?? 0));

        for (var i = 0; i < config.count && i < eligible.length; i++) {
          newLineup[config.slot]!.add(eligible[i].playerId);
          used.add(eligible[i].playerId);
        }
      }

      // Put remaining players on bench
      for (final player in state.players) {
        if (!used.contains(player.playerId)) {
          newLineup['BN']!.add(player.playerId);
        }
      }

      // Save the lineup
      final lineupSlots = LineupSlots(
        qb: newLineup['QB']!,
        rb: newLineup['RB']!,
        wr: newLineup['WR']!,
        te: newLineup['TE']!,
        flex: newLineup['FLEX']!,
        k: newLineup['K']!,
        def: newLineup['DEF']!,
        bn: newLineup['BN']!,
      );

      final updatedLineup = await _rosterRepo.setLineup(
        leagueId,
        rosterId,
        state.currentWeek,
        lineupSlots,
      );

      state = state.copyWith(
        lineup: updatedLineup,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isSaving: false,
      );
      return false;
    }
  }
}

final teamProvider = StateNotifierProvider.family<TeamNotifier, TeamState, TeamKey>(
  (ref, key) => TeamNotifier(
    ref.watch(rosterRepositoryProvider),
    ref.watch(leagueRepositoryProvider),
    key.leagueId,
    key.rosterId,
  ),
);
