import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../data/waiver_repository.dart';
import '../../domain/waiver_claim.dart';
import '../../domain/waiver_priority.dart';
import '../../domain/faab_budget.dart';

/// State for the waivers feature
class WaiversState {
  final List<WaiverClaim> claims;
  final List<WaiverPriority> priorities;
  final List<FaabBudget> budgets;
  final Set<int> waiverWirePlayerIds; // Player IDs currently on waiver wire
  final bool isLoading;
  final String? error;
  final String filter; // 'all', 'pending', 'completed'

  WaiversState({
    this.claims = const [],
    this.priorities = const [],
    this.budgets = const [],
    this.waiverWirePlayerIds = const {},
    this.isLoading = true,
    this.error,
    this.filter = 'pending',
  });

  /// Check if a player is on the waiver wire
  bool isOnWaiverWire(int playerId) => waiverWirePlayerIds.contains(playerId);

  /// Get claims filtered by current filter
  List<WaiverClaim> get filteredClaims {
    if (filter == 'pending') {
      return claims.where((c) => c.status.isPending).toList();
    } else if (filter == 'completed') {
      return claims.where((c) => c.status.isFinal).toList();
    }
    return claims;
  }

  /// Get only pending claims
  List<WaiverClaim> get pendingClaims =>
      claims.where((c) => c.status.isPending).toList();

  /// Get user's FAAB budget (if any)
  FaabBudget? getBudgetForRoster(int rosterId) {
    try {
      return budgets.firstWhere((b) => b.rosterId == rosterId);
    } catch (_) {
      return null;
    }
  }

  /// Get user's waiver priority (if any)
  WaiverPriority? getPriorityForRoster(int rosterId) {
    try {
      return priorities.firstWhere((p) => p.rosterId == rosterId);
    } catch (_) {
      return null;
    }
  }

  WaiversState copyWith({
    List<WaiverClaim>? claims,
    List<WaiverPriority>? priorities,
    List<FaabBudget>? budgets,
    Set<int>? waiverWirePlayerIds,
    bool? isLoading,
    String? error,
    String? filter,
    bool clearError = false,
  }) {
    return WaiversState(
      claims: claims ?? this.claims,
      priorities: priorities ?? this.priorities,
      budgets: budgets ?? this.budgets,
      waiverWirePlayerIds: waiverWirePlayerIds ?? this.waiverWirePlayerIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

/// Notifier for managing waivers state with socket integration
class WaiversNotifier extends StateNotifier<WaiversState> {
  final WaiverRepository _waiverRepo;
  final SocketService _socketService;
  final InvalidationService _invalidationService;
  final int leagueId;
  final int? userRosterId;

  // Socket listener disposers
  VoidCallback? _claimSubmittedDisposer;
  VoidCallback? _claimCancelledDisposer;
  VoidCallback? _claimUpdatedDisposer;
  VoidCallback? _processedDisposer;
  VoidCallback? _claimSuccessfulDisposer;
  VoidCallback? _claimFailedDisposer;
  VoidCallback? _priorityUpdatedDisposer;
  VoidCallback? _budgetUpdatedDisposer;
  VoidCallback? _memberKickedDisposer;
  VoidCallback? _invalidationDisposer;

  WaiversNotifier(
    this._waiverRepo,
    this._socketService,
    this._invalidationService,
    this.leagueId,
    this.userRosterId,
  ) : super(WaiversState()) {
    _setupSocketListeners();
    _registerInvalidationCallback();
    loadWaiverData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.waivers,
      leagueId,
      loadWaiverData,
    );
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);

    // Helper to safely parse waiver claim data - handles both full objects and minimal payloads
    void handleClaimEvent(dynamic data, {bool reloadOnPartial = true}) {
      if (!mounted) return;
      if (data is! Map) return;

      final dataMap = Map<String, dynamic>.from(data);

      // Check if this is a full claim object (has required fields)
      if (dataMap.containsKey('league_id') && dataMap.containsKey('status')) {
        try {
          final claim = WaiverClaim.fromJson(dataMap);
          _addOrUpdateClaim(claim);
        } catch (e) {
          // Failed to parse, reload waiver data
          if (reloadOnPartial) loadWaiverData();
        }
      } else if (reloadOnPartial) {
        // Minimal payload (just claimId) - reload to get full data
        loadWaiverData();
      }
    }

    _claimSubmittedDisposer = _socketService.onWaiverClaimSubmitted((data) {
      handleClaimEvent(data);
    });

    _claimCancelledDisposer = _socketService.onWaiverClaimCancelled((data) {
      if (!mounted) return;
      if (data is! Map) return;

      final dataMap = Map<String, dynamic>.from(data);
      final claimId = dataMap['claimId'] as int? ?? dataMap['claim_id'] as int?;
      if (claimId != null) {
        _removeClaim(claimId);
      } else {
        // No claim ID, reload to sync state
        loadWaiverData();
      }
    });

    _claimUpdatedDisposer = _socketService.onWaiverClaimUpdated((data) {
      handleClaimEvent(data);
    });

    _processedDisposer = _socketService.onWaiverProcessed((data) {
      if (!mounted) return;
      // Reload all waiver data after processing
      loadWaiverData();
    });

    _claimSuccessfulDisposer = _socketService.onWaiverClaimSuccessful((data) {
      handleClaimEvent(data);
    });

    _claimFailedDisposer = _socketService.onWaiverClaimFailed((data) {
      handleClaimEvent(data);
    });

    _priorityUpdatedDisposer = _socketService.onWaiverPriorityUpdated((data) {
      if (!mounted) return;
      if (data is! Map) {
        loadWaiverData();
        return;
      }

      try {
        final prioritiesList = (data['priorities'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map((json) => WaiverPriority.fromJson(json))
                .toList() ??
            [];
        state = state.copyWith(priorities: prioritiesList);
      } catch (e) {
        // Failed to parse, reload to sync
        loadWaiverData();
      }
    });

    _budgetUpdatedDisposer = _socketService.onWaiverBudgetUpdated((data) {
      if (!mounted) return;
      if (data is! Map) {
        loadWaiverData();
        return;
      }

      try {
        final budgetsList = (data['budgets'] as List?)
                ?.cast<Map<String, dynamic>>()
                .map((json) => FaabBudget.fromJson(json))
                .toList() ??
            [];
        state = state.copyWith(budgets: budgetsList);
      } catch (e) {
        // Failed to parse, reload to sync
        loadWaiverData();
      }
    });

    // Listen for member kicked events - refresh if kicked user had waiver claims
    _memberKickedDisposer = _socketService.onMemberKicked((data) {
      if (!mounted) return;
      // Reload waiver data as kicked member's claims may have been affected
      loadWaiverData();
    });
  }

  /// Add or update a claim in the list
  void _addOrUpdateClaim(WaiverClaim claim) {
    final existing = state.claims.indexWhere((c) => c.id == claim.id);
    List<WaiverClaim> updated;
    if (existing >= 0) {
      updated = [...state.claims];
      updated[existing] = claim;
    } else {
      // New claim - add to beginning of list
      updated = [claim, ...state.claims];
    }
    state = state.copyWith(claims: updated);
  }

  /// Remove a claim from the list
  void _removeClaim(int claimId) {
    final updated = state.claims.where((c) => c.id != claimId).toList();
    state = state.copyWith(claims: updated);
  }

  /// Load all waiver data for the league
  Future<void> loadWaiverData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load claims, priorities, budgets, and waiver wire in parallel
      final results = await Future.wait([
        _waiverRepo.getClaims(leagueId),
        _waiverRepo.getPriority(leagueId),
        _waiverRepo.getFaabBudgets(leagueId),
        _waiverRepo.getWaiverWire(leagueId),
      ]);

      if (!mounted) return;

      // Extract player IDs from waiver wire response
      final waiverWireData = results[3] as List<Map<String, dynamic>>;
      final waiverWirePlayerIds = waiverWireData
          .map((p) => p['player_id'] as int?)
          .whereType<int>()
          .toSet();

      state = state.copyWith(
        claims: results[0] as List<WaiverClaim>,
        priorities: results[1] as List<WaiverPriority>,
        budgets: results[2] as List<FaabBudget>,
        waiverWirePlayerIds: waiverWirePlayerIds,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Set the filter for displaying claims
  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  /// Submit a new waiver claim
  Future<WaiverClaim?> submitClaim({
    required int playerId,
    int? dropPlayerId,
    int bidAmount = 0,
  }) async {
    try {
      final claim = await _waiverRepo.submitClaim(
        leagueId: leagueId,
        playerId: playerId,
        dropPlayerId: dropPlayerId,
        bidAmount: bidAmount,
      );
      _addOrUpdateClaim(claim);
      return claim;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update a waiver claim
  Future<WaiverClaim?> updateClaim(
    int claimId, {
    int? dropPlayerId,
    int? bidAmount,
  }) async {
    try {
      final claim = await _waiverRepo.updateClaim(
        leagueId,
        claimId,
        dropPlayerId: dropPlayerId,
        bidAmount: bidAmount,
      );
      _addOrUpdateClaim(claim);
      return claim;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Cancel a waiver claim
  Future<bool> cancelClaim(int claimId) async {
    try {
      await _waiverRepo.cancelClaim(leagueId, claimId);
      _removeClaim(claimId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _socketService.leaveLeague(leagueId);
    _claimSubmittedDisposer?.call();
    _claimCancelledDisposer?.call();
    _claimUpdatedDisposer?.call();
    _processedDisposer?.call();
    _claimSuccessfulDisposer?.call();
    _claimFailedDisposer?.call();
    _priorityUpdatedDisposer?.call();
    _budgetUpdatedDisposer?.call();
    _memberKickedDisposer?.call();
    _invalidationDisposer?.call();
    super.dispose();
  }
}

/// Provider for waivers in a specific league
final waiversProvider =
    StateNotifierProvider.family<WaiversNotifier, WaiversState, ({int leagueId, int? userRosterId})>(
  (ref, params) => WaiversNotifier(
    ref.watch(waiverRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(invalidationServiceProvider),
    params.leagueId,
    params.userRosterId,
  ),
);
