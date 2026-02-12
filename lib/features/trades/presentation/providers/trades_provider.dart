import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/trade_repository.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';

/// State for the trades list screen
class TradesState {
  final List<Trade> trades;
  final bool isLoading;
  final String? error;
  final String filter; // 'mine', 'all', 'pending', 'completed'
  final DateTime? lastUpdated;
  final int? userRosterId;
  final bool isForbidden;

  TradesState({
    this.trades = const [],
    this.isLoading = true,
    this.error,
    this.filter = 'mine',
    this.lastUpdated,
    this.userRosterId,
    this.isForbidden = false,
  });

  /// Check if data is stale (older than 5 minutes)
  bool get isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!) > const Duration(minutes: 5);
  }

  /// Get trades filtered by current filter, sorted with pending/active first
  List<Trade> get filteredTrades {
    List<Trade> filtered;
    if (filter == 'mine' && userRosterId != null) {
      filtered = trades
          .where((t) =>
              t.proposerRosterId == userRosterId ||
              t.recipientRosterId == userRosterId)
          .toList();
    } else if (filter == 'pending') {
      filtered = trades
          .where((t) => t.status.isPending || t.status == TradeStatus.inReview)
          .toList();
    } else if (filter == 'completed') {
      filtered = trades.where((t) => t.status.isFinal).toList();
    } else {
      filtered = List.of(trades);
    }
    // Sort: active/pending trades first, then by updatedAt descending
    filtered.sort((a, b) {
      final aActive = a.status.isActive ? 0 : 1;
      final bActive = b.status.isActive ? 0 : 1;
      if (aActive != bActive) return aActive.compareTo(bActive);
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return filtered;
  }

  /// Get only pending trades
  List<Trade> get pendingTrades =>
      trades.where((t) => t.status.isPending).toList();

  /// Get only active (non-final) trades
  List<Trade> get activeTrades =>
      trades.where((t) => t.status.isActive).toList();

  TradesState copyWith({
    List<Trade>? trades,
    bool? isLoading,
    String? error,
    String? filter,
    bool clearError = false,
    DateTime? lastUpdated,
    int? userRosterId,
    bool? isForbidden,
  }) {
    return TradesState(
      trades: trades ?? this.trades,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      userRosterId: userRosterId ?? this.userRosterId,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

/// Notifier for managing trades state with socket integration
class TradesNotifier extends StateNotifier<TradesState> {
  final TradeRepository _tradeRepo;
  final SocketService _socketService;
  final InvalidationService _invalidationService;
  final SyncService _syncService;
  final int leagueId;

  // Socket listener disposers
  VoidCallback? _proposedDisposer;
  VoidCallback? _acceptedDisposer;
  VoidCallback? _rejectedDisposer;
  VoidCallback? _counteredDisposer;
  VoidCallback? _cancelledDisposer;
  VoidCallback? _expiredDisposer;
  VoidCallback? _completedDisposer;
  VoidCallback? _vetoedDisposer;
  VoidCallback? _voteCastDisposer;
  VoidCallback? _invalidatedDisposer;
  VoidCallback? _memberKickedDisposer;
  VoidCallback? _invalidationDisposer;
  VoidCallback? _reconnectDisposer;
  VoidCallback? _syncDisposer;

  // Debounce timer for socket events that trigger loadTrades
  Timer? _loadTradesDebounceTimer;
  static const _debounceDelay = Duration(milliseconds: 300);

  TradesNotifier(
    this._tradeRepo,
    this._socketService,
    this._invalidationService,
    this._syncService,
    this.leagueId,
  ) : super(TradesState()) {
    _setupSocketListeners();
    _registerInvalidationCallback();
    _syncDisposer = _syncService.registerLeagueSync(leagueId, loadTrades);
    loadTrades();
  }

  /// Debounced version of loadTrades to prevent multiple rapid calls
  void _debouncedLoadTrades() {
    _loadTradesDebounceTimer?.cancel();
    _loadTradesDebounceTimer = Timer(_debounceDelay, () {
      if (mounted) loadTrades();
    });
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.trades,
      leagueId,
      loadTrades,
    );
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);

    // Helper to safely parse trade data - handles both full objects and tradeId-only
    void handleTradeEvent(dynamic data, {bool reloadOnPartial = true}) {
      if (!mounted) return;
      if (data is! Map) return;

      final dataMap = Map<String, dynamic>.from(data);

      // Check if this is a full trade object (has required fields)
      if (dataMap.containsKey('league_id') && dataMap.containsKey('status')) {
        try {
          final trade = Trade.fromJson(dataMap);
          _addOrUpdateTrade(trade);
        } catch (e) {
          // Failed to parse, reload trades with debounce
          if (reloadOnPartial) _debouncedLoadTrades();
        }
      } else if (reloadOnPartial) {
        // Minimal payload (just tradeId) - reload to get full data with debounce
        _debouncedLoadTrades();
      }
    }

    _proposedDisposer = _socketService.onTradeProposed((data) {
      handleTradeEvent(data);
    });

    _acceptedDisposer = _socketService.onTradeAccepted((data) {
      handleTradeEvent(data);
      // Trigger cross-provider invalidation for socket-delivered trade acceptance
      _invalidationService.invalidate(InvalidationEvent.tradeAccepted, leagueId);
    });

    _rejectedDisposer = _socketService.onTradeRejected((data) {
      // Backend sends { tradeId } - reload for full data
      handleTradeEvent(data);
    });

    _counteredDisposer = _socketService.onTradeCountered((data) {
      if (!mounted) return;
      if (data is! Map) return;

      // Counter creates a new trade, update both original and new
      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['originalTrade'] != null) {
        try {
          final original =
              Trade.fromJson(Map<String, dynamic>.from(dataMap['originalTrade']));
          _addOrUpdateTrade(original);
        } catch (e) {
          // Ignore parse errors
        }
      }
      if (dataMap['newTrade'] != null) {
        try {
          final newTrade =
              Trade.fromJson(Map<String, dynamic>.from(dataMap['newTrade']));
          _addOrUpdateTrade(newTrade);
        } catch (e) {
          // Ignore parse errors
        }
      }
      // Always reload to ensure consistency (with debounce)
      _debouncedLoadTrades();
    });

    _cancelledDisposer = _socketService.onTradeCancelled((data) {
      // Backend sends { tradeId } - reload for full data
      handleTradeEvent(data);
    });

    _expiredDisposer = _socketService.onTradeExpired((data) {
      // Backend sends { tradeId } - reload for full data
      handleTradeEvent(data);
    });

    _completedDisposer = _socketService.onTradeCompleted((data) {
      handleTradeEvent(data);
      // Trigger cross-provider invalidation for socket-delivered trade completion
      _invalidationService.invalidate(InvalidationEvent.tradeCompleted, leagueId);
    });

    _vetoedDisposer = _socketService.onTradeVetoed((data) {
      // Backend sends { tradeId } - reload for full data
      handleTradeEvent(data);
    });

    _voteCastDisposer = _socketService.onTradeVoteCast((data) {
      if (!mounted) return;
      if (data is! Map) return;

      final dataMap = Map<String, dynamic>.from(data);
      if (dataMap['trade'] != null) {
        try {
          final trade =
              Trade.fromJson(Map<String, dynamic>.from(dataMap['trade']));
          _addOrUpdateTrade(trade);
        } catch (e) {
          // Failed to parse, reload with debounce
          _debouncedLoadTrades();
        }
      } else {
        // Just vote count update, reload with debounce
        _debouncedLoadTrades();
      }
    });

    _invalidatedDisposer = _socketService.onTradeInvalidated((data) {
      if (!mounted) return;
      // Reload trades to get updated status after invalidation (with debounce)
      _debouncedLoadTrades();
    });

    // Listen for member kicked events - trades involving kicked member become invalid
    _memberKickedDisposer = _socketService.onMemberKicked((data) {
      if (!mounted) return;
      // Reload to get updated trade statuses (with debounce)
      _debouncedLoadTrades();
    });

    // Resync trades on socket reconnection (both short and long disconnects)
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('Trades: Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      // Always reload trades on reconnect to ensure consistency.
      // Short disconnects may have missed trade status transitions.
      loadTrades();
    });
  }

  /// Add or update a trade in the list, maintaining deterministic sort order.
  void _addOrUpdateTrade(Trade trade) {
    final existing = state.trades.indexWhere((t) => t.id == trade.id);
    List<Trade> updated;
    if (existing >= 0) {
      updated = [...state.trades];
      updated[existing] = trade;
    } else {
      updated = [trade, ...state.trades];
    }
    // Sort by most recently updated to prevent ordering regressions from socket events
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = state.copyWith(trades: updated);
  }

  /// Load all trades for the league
  Future<void> loadTrades() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final trades = await _tradeRepo.getTrades(leagueId);
      if (!mounted) return;
      state = state.copyWith(trades: trades, isLoading: false, lastUpdated: DateTime.now());
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(isForbidden: true, isLoading: false, trades: []);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  /// Set the user's roster ID for "My Trades" filtering
  void setUserRosterId(int? rosterId) {
    if (rosterId != state.userRosterId) {
      state = state.copyWith(userRosterId: rosterId);
    }
  }

  /// Set the filter for displaying trades
  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  /// Accept a trade
  Future<Trade?> acceptTrade(int tradeId, {String? idempotencyKey}) async {
    try {
      final trade = await _tradeRepo.acceptTrade(leagueId, tradeId, idempotencyKey: idempotencyKey);
      _addOrUpdateTrade(trade);

      // Trigger cross-provider invalidation when trade is accepted
      _invalidationService.invalidate(InvalidationEvent.tradeAccepted, leagueId);

      return trade;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return null;
    }
  }

  /// Reject a trade
  Future<Trade?> rejectTrade(int tradeId, {String? idempotencyKey}) async {
    try {
      final trade = await _tradeRepo.rejectTrade(leagueId, tradeId, idempotencyKey: idempotencyKey);
      _addOrUpdateTrade(trade);
      return trade;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return null;
    }
  }

  /// Cancel a trade (proposer only)
  Future<Trade?> cancelTrade(int tradeId, {String? idempotencyKey}) async {
    try {
      final trade = await _tradeRepo.cancelTrade(leagueId, tradeId, idempotencyKey: idempotencyKey);
      _addOrUpdateTrade(trade);
      return trade;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return null;
    }
  }

  /// Vote on a trade during review period
  Future<bool> voteTrade(int tradeId, String vote, {String? idempotencyKey}) async {
    try {
      final result = await _tradeRepo.voteTrade(leagueId, tradeId, vote, idempotencyKey: idempotencyKey);
      final tradeData = result['trade'];
      if (tradeData == null) {
        throw Exception('Vote response missing trade data');
      }
      final trade = tradeData as Trade;
      _addOrUpdateTrade(trade);
      return true;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return false;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _loadTradesDebounceTimer?.cancel();
    _socketService.leaveLeague(leagueId);
    _proposedDisposer?.call();
    _acceptedDisposer?.call();
    _rejectedDisposer?.call();
    _counteredDisposer?.call();
    _cancelledDisposer?.call();
    _expiredDisposer?.call();
    _completedDisposer?.call();
    _vetoedDisposer?.call();
    _voteCastDisposer?.call();
    _invalidatedDisposer?.call();
    _memberKickedDisposer?.call();
    _invalidationDisposer?.call();
    _reconnectDisposer?.call();
    _syncDisposer?.call();
    super.dispose();
  }
}

/// Provider for trades in a specific league
final tradesProvider =
    StateNotifierProvider.autoDispose.family<TradesNotifier, TradesState, int>(
  (ref, leagueId) => TradesNotifier(
    ref.watch(tradeRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(invalidationServiceProvider),
    ref.watch(syncServiceProvider),
    leagueId,
  ),
);
