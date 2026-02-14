import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/socket/socket_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/trade_block_repository.dart';
import '../../domain/trade_block_item.dart';

class TradeBlockState {
  final List<TradeBlockItem> items;
  final bool isLoading;
  final String? error;
  final String positionFilter; // 'All', 'QB', 'RB', 'WR', 'TE'

  TradeBlockState({
    this.items = const [],
    this.isLoading = true,
    this.error,
    this.positionFilter = 'All',
  });

  List<TradeBlockItem> get filteredItems {
    if (positionFilter == 'All') return items;
    return items.where((item) => item.position == positionFilter).toList();
  }

  /// Group items by rosterId for display
  Map<int, List<TradeBlockItem>> get groupedByRoster {
    final map = <int, List<TradeBlockItem>>{};
    for (final item in filteredItems) {
      map.putIfAbsent(item.rosterId, () => []).add(item);
    }
    return map;
  }

  TradeBlockState copyWith({
    List<TradeBlockItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? positionFilter,
  }) {
    return TradeBlockState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      positionFilter: positionFilter ?? this.positionFilter,
    );
  }
}

class TradeBlockNotifier extends StateNotifier<TradeBlockState> {
  final TradeBlockRepository _repo;
  final SocketService _socketService;
  final int leagueId;

  VoidCallback? _socketDisposer;
  VoidCallback? _reconnectDisposer;
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(milliseconds: 500);

  TradeBlockNotifier(this._repo, this._socketService, this.leagueId)
      : super(TradeBlockState()) {
    _setupSocket();
    loadItems();
  }

  void _setupSocket() {
    _socketService.joinLeague(leagueId);
    _socketDisposer = _socketService.onTradeBlockUpdated((_) {
      _debouncedReload();
    });
    _reconnectDisposer = _socketService.onReconnected((_) {
      loadItems();
    });
  }

  void _debouncedReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (mounted) loadItems();
    });
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.getItems(leagueId);
      if (!mounted) return;
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  Future<bool> addItem(int playerId, {String? note}) async {
    try {
      final item = await _repo.addItem(leagueId, playerId: playerId, note: note);
      if (!mounted) return true;
      state = state.copyWith(items: [item, ...state.items]);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return false;
    }
  }

  Future<bool> removeItem(int playerId) async {
    try {
      await _repo.removeItem(leagueId, playerId);
      if (!mounted) return true;
      state = state.copyWith(
        items: state.items.where((i) => i.playerId != playerId).toList(),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(error: ErrorSanitizer.sanitize(e));
      return false;
    }
  }

  void setPositionFilter(String filter) {
    state = state.copyWith(positionFilter: filter);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _socketDisposer?.call();
    _reconnectDisposer?.call();
    super.dispose();
  }
}

final tradeBlockProvider = StateNotifierProvider.autoDispose
    .family<TradeBlockNotifier, TradeBlockState, int>(
  (ref, leagueId) => TradeBlockNotifier(
    ref.watch(tradeBlockRepositoryProvider),
    ref.watch(socketServiceProvider),
    leagueId,
  ),
);
