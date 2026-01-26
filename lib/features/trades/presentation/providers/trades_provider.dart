import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/socket/socket_service.dart';
import '../../data/trade_repository.dart';
import '../../domain/trade.dart';
import '../../domain/trade_status.dart';

/// State for the trades list screen
class TradesState {
  final List<Trade> trades;
  final bool isLoading;
  final String? error;
  final String filter; // 'all', 'pending', 'completed'

  TradesState({
    this.trades = const [],
    this.isLoading = true,
    this.error,
    this.filter = 'all',
  });

  /// Get trades filtered by current filter
  List<Trade> get filteredTrades {
    if (filter == 'pending') {
      return trades
          .where((t) => t.status.isPending || t.status == TradeStatus.inReview)
          .toList();
    } else if (filter == 'completed') {
      return trades.where((t) => t.status.isFinal).toList();
    }
    return trades;
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
  }) {
    return TradesState(
      trades: trades ?? this.trades,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

/// Notifier for managing trades state with socket integration
class TradesNotifier extends StateNotifier<TradesState> {
  final TradeRepository _tradeRepo;
  final SocketService _socketService;
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

  TradesNotifier(
    this._tradeRepo,
    this._socketService,
    this.leagueId,
  ) : super(TradesState()) {
    _setupSocketListeners();
    loadTrades();
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
          // Failed to parse, reload trades
          if (reloadOnPartial) loadTrades();
        }
      } else if (reloadOnPartial) {
        // Minimal payload (just tradeId) - reload to get full data
        loadTrades();
      }
    }

    _proposedDisposer = _socketService.onTradeProposed((data) {
      handleTradeEvent(data);
    });

    _acceptedDisposer = _socketService.onTradeAccepted((data) {
      // Backend sends { tradeId, reviewEndsAt } - reload for full data
      handleTradeEvent(data);
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
      // Always reload to ensure consistency
      loadTrades();
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
      // Backend sends { tradeId } - reload for full data
      handleTradeEvent(data);
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
          // Failed to parse, reload
          loadTrades();
        }
      } else {
        // Just vote count update, reload
        loadTrades();
      }
    });

    _invalidatedDisposer = _socketService.onTradeInvalidated((data) {
      if (!mounted) return;
      // Reload trades to get updated status after invalidation
      loadTrades();
    });
  }

  /// Add or update a trade in the list
  void _addOrUpdateTrade(Trade trade) {
    final existing = state.trades.indexWhere((t) => t.id == trade.id);
    List<Trade> updated;
    if (existing >= 0) {
      updated = [...state.trades];
      updated[existing] = trade;
    } else {
      // New trade - add to beginning of list
      updated = [trade, ...state.trades];
    }
    state = state.copyWith(trades: updated);
  }

  /// Load all trades for the league
  Future<void> loadTrades() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final trades = await _tradeRepo.getTrades(leagueId);
      if (!mounted) return;
      state = state.copyWith(trades: trades, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Set the filter for displaying trades
  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  /// Accept a trade
  Future<Trade?> acceptTrade(int tradeId) async {
    try {
      final trade = await _tradeRepo.acceptTrade(leagueId, tradeId);
      _addOrUpdateTrade(trade);
      return trade;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Reject a trade
  Future<Trade?> rejectTrade(int tradeId) async {
    try {
      final trade = await _tradeRepo.rejectTrade(leagueId, tradeId);
      _addOrUpdateTrade(trade);
      return trade;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Cancel a trade (proposer only)
  Future<Trade?> cancelTrade(int tradeId) async {
    try {
      final trade = await _tradeRepo.cancelTrade(leagueId, tradeId);
      _addOrUpdateTrade(trade);
      return trade;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Vote on a trade during review period
  Future<bool> voteTrade(int tradeId, String vote) async {
    try {
      final result = await _tradeRepo.voteTrade(leagueId, tradeId, vote);
      final trade = result['trade'] as Trade;
      _addOrUpdateTrade(trade);
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
    super.dispose();
  }
}

/// Provider for trades in a specific league
final tradesProvider =
    StateNotifierProvider.family<TradesNotifier, TradesState, int>(
  (ref, leagueId) => TradesNotifier(
    ref.watch(tradeRepositoryProvider),
    ref.watch(socketServiceProvider),
    leagueId,
  ),
);
