import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/invalidation_service.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../data/roster_repository.dart';
import '../../domain/roster_player.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/lineup_optimizer.dart';

export '../../../leagues/domain/league.dart' show Roster;

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
  final DateTime? lastUpdated;
  final List<Roster> leagueMembers;
  final bool isForbidden;

  TeamState({
    this.league,
    this.players = const [],
    this.lineup,
    this.currentWeek = 1,
    this.isLoading = true,
    this.error,
    this.isSaving = false,
    this.lastUpdated,
    this.leagueMembers = const [],
    this.isForbidden = false,
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

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
    return _buildOptimizer().calculateOptimalPoints(players);
  }

  /// Build a LineupOptimizer from the league's roster config, falling back to defaults
  LineupOptimizer _buildOptimizer() {
    final configMap = league?.settings['roster_config'];
    if (configMap is Map<String, dynamic>) {
      return LineupOptimizer.fromConfig(RosterConfig.fromJson(configMap));
    }
    return const LineupOptimizer();
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
    DateTime? lastUpdated,
    List<Roster>? leagueMembers,
    bool? isForbidden,
  }) {
    return TeamState(
      league: league ?? this.league,
      players: players ?? this.players,
      lineup: lineup ?? this.lineup,
      currentWeek: currentWeek ?? this.currentWeek,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      leagueMembers: leagueMembers ?? this.leagueMembers,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final RosterRepository _rosterRepo;
  final LeagueRepository _leagueRepo;
  final InvalidationService _invalidationService;
  final int leagueId;
  final int rosterId;

  VoidCallback? _invalidationDisposer;

  // Idempotency keys for retry safety
  String? _lineupIdempotencyKey;
  String? _movePlayerIdempotencyKey;
  String? _dropPlayerIdempotencyKey;

  TeamNotifier(
    this._rosterRepo,
    this._leagueRepo,
    this._invalidationService,
    this.leagueId,
    this.rosterId,
  ) : super(TeamState()) {
    _registerInvalidationCallback();
    loadData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.team,
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
      // Load league info first to get current week
      final league = await _leagueRepo.getLeague(leagueId);
      if (!mounted) return;
      final currentWeek = league.currentWeek;

      // Load roster players and league members in parallel
      final results = await Future.wait([
        _rosterRepo.getRosterPlayers(leagueId, rosterId),
        _leagueRepo.getLeagueMembers(leagueId),
      ]);
      if (!mounted) return;
      final players = results[0] as List<RosterPlayer>;
      final members = results[1] as List<Roster>;

      // Try to load lineup (may not exist yet)
      RosterLineup? lineup;
      try {
        lineup = await _rosterRepo.getLineup(leagueId, rosterId, currentWeek);
      } catch (_) {
        // Lineup doesn't exist yet - that's OK
      }
      if (!mounted) return;

      state = state.copyWith(
        league: league,
        players: players,
        lineup: lineup,
        currentWeek: currentWeek,
        isLoading: false,
        lastUpdated: DateTime.now(),
        leagueMembers: members,
      );
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(isForbidden: true, isLoading: false, players: []);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
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
      if (!mounted) return;
      state = state.copyWith(
        lineup: lineup,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      // Lineup may not exist yet for future weeks - that's OK
      state = state.copyWith(
        lineup: null,
        isLoading: false,
      );
    }
  }

  /// Move a player to a different lineup slot
  Future<bool> movePlayer(int playerId, String toSlot, {String? idempotencyKey}) async {
    if (state.lineup?.isLocked == true) {
      state = state.copyWith(error: 'Lineup is locked for this week');
      return false;
    }

    // Generate or reuse idempotency key for retry safety
    _movePlayerIdempotencyKey ??= idempotencyKey ?? const Uuid().v4();

    state = state.copyWith(isSaving: true);

    try {
      final updatedLineup = await _rosterRepo.movePlayer(
        leagueId,
        rosterId,
        state.currentWeek,
        playerId,
        toSlot,
        idempotencyKey: _movePlayerIdempotencyKey,
      );
      if (!mounted) return false;

      // Clear key on success
      _movePlayerIdempotencyKey = null;

      state = state.copyWith(
        lineup: updatedLineup,
        isSaving: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Keep key for retry
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isSaving: false,
      );
      return false;
    }
  }

  /// Save the entire lineup
  Future<bool> saveLineup(LineupSlots lineup, {String? idempotencyKey}) async {
    if (state.lineup?.isLocked == true) {
      state = state.copyWith(error: 'Lineup is locked for this week');
      return false;
    }

    // Generate or reuse idempotency key for retry safety
    _lineupIdempotencyKey ??= idempotencyKey ?? const Uuid().v4();

    state = state.copyWith(isSaving: true);

    try {
      final updatedLineup = await _rosterRepo.setLineup(
        leagueId,
        rosterId,
        state.currentWeek,
        lineup,
        idempotencyKey: _lineupIdempotencyKey,
      );
      if (!mounted) return false;

      // Clear key on success
      _lineupIdempotencyKey = null;

      state = state.copyWith(
        lineup: updatedLineup,
        isSaving: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Keep key for retry
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isSaving: false,
      );
      return false;
    }
  }

  /// Drop a player from the roster
  Future<bool> dropPlayer(int playerId, {String? idempotencyKey}) async {
    // Generate or reuse idempotency key for retry safety
    _dropPlayerIdempotencyKey ??= idempotencyKey ?? const Uuid().v4();

    state = state.copyWith(isSaving: true);

    try {
      await _rosterRepo.dropPlayer(
        leagueId,
        rosterId,
        playerId,
        idempotencyKey: _dropPlayerIdempotencyKey,
      );
      if (!mounted) return false;

      // Clear key on success
      _dropPlayerIdempotencyKey = null;

      // Remove from local state
      state = state.copyWith(
        players: state.players.where((p) => p.playerId != playerId).toList(),
        isSaving: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Keep key for retry
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
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
  Future<bool> setOptimalLineup({String? idempotencyKey}) async {
    if (state.lineup?.isLocked == true) {
      state = state.copyWith(error: 'Lineup is locked for this week');
      return false;
    }

    if (state.players.isEmpty) {
      state = state.copyWith(error: 'No players on roster');
      return false;
    }

    // Generate or reuse idempotency key for retry safety
    _lineupIdempotencyKey ??= idempotencyKey ?? const Uuid().v4();

    state = state.copyWith(isSaving: true);

    try {
      final optimizer = state._buildOptimizer();
      final optimized = optimizer.buildOptimalLineup(state.players);

      final updatedLineup = await _rosterRepo.setLineup(
        leagueId,
        rosterId,
        state.currentWeek,
        optimized.slots,
        idempotencyKey: _lineupIdempotencyKey,
      );
      if (!mounted) return false;

      // Clear key on success
      _lineupIdempotencyKey = null;

      state = state.copyWith(
        lineup: updatedLineup,
        isSaving: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Keep key for retry
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isSaving: false,
      );
      return false;
    }
  }
}

final teamProvider = StateNotifierProvider.autoDispose.family<TeamNotifier, TeamState, TeamKey>(
  (ref, key) => TeamNotifier(
    ref.watch(rosterRepositoryProvider),
    ref.watch(leagueRepositoryProvider),
    ref.watch(invalidationServiceProvider),
    key.leagueId,
    key.rosterId,
  ),
);
