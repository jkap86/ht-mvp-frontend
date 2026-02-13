import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/waiver_repository.dart';
import '../../domain/waiver_claim.dart';
import '../../domain/waiver_priority.dart';
import '../../domain/faab_budget.dart';
import 'waivers_socket_handler.dart';

/// State for the waivers feature
class WaiversState {
  final List<WaiverClaim> claims;
  final List<WaiverPriority> priorities;
  final List<FaabBudget> budgets;
  final Set<int> waiverWirePlayerIds; // Player IDs currently on waiver wire
  final bool isLoading;
  final String? error;
  final bool isForbidden;
  final String filter; // 'all', 'pending', 'completed'
  final bool isReordering; // True while a reorder API call is in flight

  WaiversState({
    this.claims = const [],
    this.priorities = const [],
    this.budgets = const [],
    this.waiverWirePlayerIds = const {},
    this.isLoading = true,
    this.error,
    this.isForbidden = false,
    this.filter = 'pending',
    this.isReordering = false,
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

  /// Get pending claims sorted by claim_order
  List<WaiverClaim> get sortedPendingClaims {
    final pending = claims.where((c) => c.status.isPending).toList();
    pending.sort((a, b) => a.claimOrder.compareTo(b.claimOrder));
    return pending;
  }

  /// Get user's FAAB budget (if any)
  FaabBudget? getBudgetForRoster(int rosterId) {
    return budgets.where((b) => b.rosterId == rosterId).firstOrNull;
  }

  /// Get user's waiver priority (if any)
  WaiverPriority? getPriorityForRoster(int rosterId) {
    return priorities.where((p) => p.rosterId == rosterId).firstOrNull;
  }

  /// Get the total number of teams in the league (from priority list)
  int get totalTeams => priorities.length;

  /// Whether this league uses FAAB bidding (has budget data)
  bool get isFaabLeague => budgets.isNotEmpty;

  /// Summary counts for quick display
  int get pendingCount => claims.where((c) => c.status.isPending).length;
  int get successfulCount => claims.where((c) => c.status.isSuccessful).length;
  int get failedCount => claims.where((c) => c.status.isFailed).length;

  WaiversState copyWith({
    List<WaiverClaim>? claims,
    List<WaiverPriority>? priorities,
    List<FaabBudget>? budgets,
    Set<int>? waiverWirePlayerIds,
    bool? isLoading,
    String? error,
    bool? isForbidden,
    String? filter,
    bool? isReordering,
    bool clearError = false,
  }) {
    return WaiversState(
      claims: claims ?? this.claims,
      priorities: priorities ?? this.priorities,
      budgets: budgets ?? this.budgets,
      waiverWirePlayerIds: waiverWirePlayerIds ?? this.waiverWirePlayerIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isForbidden: isForbidden ?? this.isForbidden,
      filter: filter ?? this.filter,
      isReordering: isReordering ?? this.isReordering,
    );
  }
}

/// Notifier for managing waivers state with socket integration
class WaiversNotifier extends StateNotifier<WaiversState>
    implements WaiversSocketCallbacks {
  final WaiverRepository _waiverRepo;
  final SocketService _socketService;
  final InvalidationService _invalidationService;
  final SyncService _syncService;
  final int leagueId;
  final int? userRosterId;

  // Socket handler for managing subscriptions
  WaiversSocketHandler? _socketHandler;
  VoidCallback? _invalidationDisposer;
  VoidCallback? _syncDisposer;

  // Debounce timer for reload operations
  Timer? _loadWaiverDataDebounceTimer;
  static const _debounceDelay = Duration(milliseconds: 300);

  WaiversNotifier(
    this._waiverRepo,
    this._socketService,
    this._invalidationService,
    this._syncService,
    this.leagueId,
    this.userRosterId,
  ) : super(WaiversState()) {
    _setupSocketListeners();
    _registerInvalidationCallback();
    _syncDisposer = _syncService.registerLeagueSync(leagueId, loadWaiverData);
    loadWaiverData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.waivers,
      leagueId,
      loadWaiverData,
    );
  }

  /// Debounced version of loadWaiverData to prevent multiple rapid calls
  void _debouncedLoadWaiverData() {
    _loadWaiverDataDebounceTimer?.cancel();
    _loadWaiverDataDebounceTimer = Timer(_debounceDelay, () {
      if (mounted) loadWaiverData();
    });
  }

  void _setupSocketListeners() {
    _socketHandler = WaiversSocketHandler(
      socketService: _socketService,
      leagueId: leagueId,
      callbacks: this,
    );
    _socketHandler!.setupListeners();
  }

  // Helper to safely parse waiver claim data - handles both full objects and minimal payloads
  void _handleClaimEvent(dynamic data, {bool reloadOnPartial = true}) {
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
        if (reloadOnPartial) _debouncedLoadWaiverData();
      }
    } else if (reloadOnPartial) {
      // Minimal payload (just claimId) - reload to get full data
      _debouncedLoadWaiverData();
    }
  }

  @override
  void onClaimSubmittedReceived(dynamic data) {
    _handleClaimEvent(data);
  }

  @override
  void onClaimCancelledReceived(dynamic data) {
    if (!mounted) return;
    if (data is! Map) return;

    final dataMap = Map<String, dynamic>.from(data);
    final claimId = dataMap['claimId'] as int? ?? dataMap['claim_id'] as int?;
    if (claimId != null) {
      _removeClaim(claimId);
    } else {
      // No claim ID, reload to sync state
      _debouncedLoadWaiverData();
    }
  }

  @override
  void onClaimUpdatedReceived(dynamic data) {
    _handleClaimEvent(data);
  }

  @override
  void onClaimsReorderedReceived(dynamic data) {
    if (!mounted) return;
    if (data is! Map) {
      _debouncedLoadWaiverData();
      return;
    }

    try {
      final claimsList = (data['claims'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((json) => WaiverClaim.fromJson(json))
              .toList() ??
          [];
      // Update claims with new order
      final currentClaims = [...state.claims];
      for (final updated in claimsList) {
        final index = currentClaims.indexWhere((c) => c.id == updated.id);
        if (index >= 0) {
          currentClaims[index] = updated;
        }
      }
      state = state.copyWith(claims: currentClaims);
    } catch (e) {
      // Failed to parse, reload to sync
      _debouncedLoadWaiverData();
    }
  }

  @override
  void onWaiverProcessedReceived(dynamic data) {
    if (!mounted) return;
    // Reload all waiver data after processing
    _debouncedLoadWaiverData();
    // Trigger cross-provider invalidation (rosters, free agents, matchups changed)
    _invalidationService.invalidate(
        InvalidationEvent.waiverProcessed, leagueId);
  }

  @override
  void onClaimSuccessfulReceived(dynamic data) {
    _handleClaimEvent(data);
    // Trigger cross-provider invalidation (roster changed)
    _invalidationService.invalidate(
        InvalidationEvent.waiverClaimSuccessful, leagueId);
  }

  @override
  void onClaimFailedReceived(dynamic data) {
    _handleClaimEvent(data);
  }

  @override
  void onPriorityUpdatedReceived(dynamic data) {
    if (!mounted) return;
    if (data is! Map) {
      _debouncedLoadWaiverData();
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
      _debouncedLoadWaiverData();
    }
  }

  @override
  void onBudgetUpdatedReceived(dynamic data) {
    if (!mounted) return;
    if (data is! Map) {
      _debouncedLoadWaiverData();
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
      _debouncedLoadWaiverData();
    }
  }

  @override
  void onMemberKickedReceived(dynamic data) {
    if (!mounted) return;
    // Reload waiver data as kicked member's claims may have been affected
    _debouncedLoadWaiverData();
  }

  @override
  void onReconnectedReceived(bool needsFullRefresh) {
    if (!mounted) return;
    // Always reload waiver data on reconnect to ensure consistency.
    // Short disconnects may have missed claim status changes.
    loadWaiverData();
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
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(
          isForbidden: true,
          isLoading: false,
          claims: [],
          priorities: [],
          budgets: []);
    } catch (e) {
      if (!mounted) return;
      state =
          state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
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
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? const Uuid().v4();
    try {
      final claim = await _waiverRepo.submitClaim(
        leagueId: leagueId,
        playerId: playerId,
        dropPlayerId: dropPlayerId,
        bidAmount: bidAmount,
        idempotencyKey: key,
      );
      _addOrUpdateClaim(claim);
      return claim;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return null;
    }
  }

  /// Update a waiver claim
  Future<WaiverClaim?> updateClaim(
    int claimId, {
    int? dropPlayerId,
    int? bidAmount,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? const Uuid().v4();
    try {
      final claim = await _waiverRepo.updateClaim(
        leagueId,
        claimId,
        dropPlayerId: dropPlayerId,
        bidAmount: bidAmount,
        idempotencyKey: key,
      );
      _addOrUpdateClaim(claim);
      return claim;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return null;
    }
  }

  /// Cancel a waiver claim
  Future<bool> cancelClaim(int claimId, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? const Uuid().v4();
    try {
      await _waiverRepo.cancelClaim(leagueId, claimId, idempotencyKey: key);
      _removeClaim(claimId);
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return false;
    }
  }

  /// Reorder waiver claims
  /// Takes a list of claim IDs in the desired order
  Future<bool> reorderClaims(List<int> claimIds,
      {String? idempotencyKey}) async {
    // Prevent concurrent reorders to avoid state inconsistencies
    if (state.isReordering) return false;

    final key = idempotencyKey ?? const Uuid().v4();
    // Save previous claims for rollback on error
    final previousClaims = [...state.claims];

    // Apply optimistic reorder: update claim_order based on position in claimIds
    final optimisticClaims = [...state.claims];
    for (int i = 0; i < claimIds.length; i++) {
      final index = optimisticClaims.indexWhere((c) => c.id == claimIds[i]);
      if (index >= 0) {
        optimisticClaims[index] =
            optimisticClaims[index].copyWith(claimOrder: i + 1);
      }
    }
    state = state.copyWith(claims: optimisticClaims, isReordering: true);

    try {
      final updatedClaims = await _waiverRepo.reorderClaims(leagueId, claimIds,
          idempotencyKey: key);
      if (!mounted) return true;
      // Update local state with server-confirmed claim orders
      final currentClaims = [...state.claims];
      for (final updated in updatedClaims) {
        final index = currentClaims.indexWhere((c) => c.id == updated.id);
        if (index >= 0) {
          currentClaims[index] = updated;
        }
      }
      state = state.copyWith(claims: currentClaims, isReordering: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      // Rollback to previous claim order on error
      state = state.copyWith(
          claims: previousClaims,
          error: ErrorSanitizer.sanitize(e),
          isReordering: false);
      return false;
    }
  }

  /// Move a claim up in priority (decrease claim_order)
  Future<bool> moveClaimUp(int claimId) async {
    final pending = state.sortedPendingClaims;
    final index = pending.indexWhere((c) => c.id == claimId);
    if (index <= 0) return false; // Already at top or not found

    final ids = pending.map((c) => c.id).toList();
    // Swap with previous
    final temp = ids[index];
    ids[index] = ids[index - 1];
    ids[index - 1] = temp;

    return reorderClaims(ids);
  }

  /// Move a claim down in priority (increase claim_order)
  Future<bool> moveClaimDown(int claimId) async {
    final pending = state.sortedPendingClaims;
    final index = pending.indexWhere((c) => c.id == claimId);
    if (index < 0 || index >= pending.length - 1)
      return false; // At bottom or not found

    final ids = pending.map((c) => c.id).toList();
    // Swap with next
    final temp = ids[index];
    ids[index] = ids[index + 1];
    ids[index + 1] = temp;

    return reorderClaims(ids);
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _loadWaiverDataDebounceTimer?.cancel();
    _socketHandler?.dispose();
    _invalidationDisposer?.call();
    _syncDisposer?.call();
    super.dispose();
  }
}

/// Provider for waivers in a specific league
final waiversProvider = StateNotifierProvider.autoDispose
    .family<WaiversNotifier, WaiversState, ({int leagueId, int? userRosterId})>(
  (ref, params) => WaiversNotifier(
    ref.watch(waiverRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(invalidationServiceProvider),
    ref.watch(syncServiceProvider),
    params.leagueId,
    params.userRosterId,
  ),
);
