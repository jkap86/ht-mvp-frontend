import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/draft_repository.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import 'draft_socket_handler.dart';

export 'draft_socket_handler.dart' show OutbidNotification;

/// State for auction-specific functionality
class AuctionState {
  final List<AuctionLot> activeLots;
  final List<AuctionBudget> budgets;
  final OutbidNotification? outbidNotification;
  final String auctionMode;
  final int? currentNominatorRosterId;
  final int? nominationNumber;
  final DateTime? nominationDeadline;
  final int? dailyNominationsRemaining;
  final int? dailyNominationLimit;
  final bool globalCapReached;
  final AuctionSettings? auctionSettings;
  final bool isLoading;
  final String? error;

  const AuctionState({
    this.activeLots = const [],
    this.budgets = const [],
    this.outbidNotification,
    this.auctionMode = 'slow',
    this.currentNominatorRosterId,
    this.nominationNumber,
    this.nominationDeadline,
    this.dailyNominationsRemaining,
    this.dailyNominationLimit,
    this.globalCapReached = false,
    this.auctionSettings,
    this.isLoading = false,
    this.error,
  });

  bool get isFastAuction => auctionMode == 'fast';

  AuctionBudget? getBudgetForRoster(int? rosterId) {
    if (rosterId == null) return null;
    return budgets.where((b) => b.rosterId == rosterId).firstOrNull;
  }

  AuctionState copyWith({
    List<AuctionLot>? activeLots,
    List<AuctionBudget>? budgets,
    OutbidNotification? outbidNotification,
    bool clearOutbidNotification = false,
    String? auctionMode,
    int? currentNominatorRosterId,
    int? nominationNumber,
    DateTime? nominationDeadline,
    int? dailyNominationsRemaining,
    int? dailyNominationLimit,
    bool? globalCapReached,
    AuctionSettings? auctionSettings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuctionState(
      activeLots: activeLots ?? this.activeLots,
      budgets: budgets ?? this.budgets,
      outbidNotification: clearOutbidNotification
          ? null
          : (outbidNotification ?? this.outbidNotification),
      auctionMode: auctionMode ?? this.auctionMode,
      currentNominatorRosterId:
          currentNominatorRosterId ?? this.currentNominatorRosterId,
      nominationNumber: nominationNumber ?? this.nominationNumber,
      nominationDeadline: nominationDeadline ?? this.nominationDeadline,
      dailyNominationsRemaining:
          dailyNominationsRemaining ?? this.dailyNominationsRemaining,
      dailyNominationLimit: dailyNominationLimit ?? this.dailyNominationLimit,
      globalCapReached: globalCapReached ?? this.globalCapReached,
      auctionSettings: auctionSettings ?? this.auctionSettings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Key for auction provider - matches draft room key
typedef AuctionKey = ({int leagueId, int draftId});

/// Callbacks interface for auction socket events
abstract class AuctionSocketCallbacks {
  void onLotCreatedReceived(AuctionLot lot);
  void onLotUpdatedReceived(AuctionLot lot);
  void onLotWonReceived(int lotId);
  void onLotPassedReceived(int lotId);
  void onOutbidReceived(OutbidNotification notification);
  void onNominatorChangedReceived(
      int? rosterId, int? nominationNumber, DateTime? nominationDeadline);
  void onAuctionErrorReceived(String message);
}

/// Provider for auction-specific state and methods
class AuctionNotifier extends StateNotifier<AuctionState>
    implements AuctionSocketCallbacks {
  final DraftRepository _draftRepo;
  final int leagueId;
  final int draftId;
  final int? Function() _getMyRosterId;

  Timer? _budgetRefreshTimer;

  AuctionNotifier(
    this._draftRepo,
    this.leagueId,
    this.draftId,
    this._getMyRosterId,
  ) : super(const AuctionState());

  /// Load auction data from the API
  Future<void> loadAuctionData() async {
    if (!mounted) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final auctionState = await _draftRepo.getAuctionState(leagueId, draftId);

      if (!mounted) return;
      state = state.copyWith(
        activeLots: auctionState.activeLots,
        budgets: auctionState.budgets,
        auctionMode: auctionState.auctionMode,
        currentNominatorRosterId: auctionState.currentNominatorRosterId,
        nominationNumber: auctionState.nominationNumber,
        nominationDeadline: auctionState.nominationDeadline,
        dailyNominationsRemaining: auctionState.dailyNominationsRemaining,
        dailyNominationLimit: auctionState.dailyNominationLimit,
        globalCapReached: auctionState.globalCapReached,
        auctionSettings: auctionState.settings,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Failed to load auction data: $e');
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to load auction data',
          isLoading: false,
        );
      }
    }
  }

  /// Nominate a player for auction
  Future<String?> nominate(int playerId) async {
    try {
      final lot = await _draftRepo.nominate(leagueId, draftId, playerId);
      // Immediately add the new lot to state (don't wait for WebSocket)
      if (mounted) {
        _upsertAndSortLot(lot);
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Set max bid for a lot
  Future<String?> setMaxBid(int lotId, int maxBid) async {
    // Save previous myMaxBid for this specific lot (for targeted rollback)
    final previousMaxBid = state.activeLots
        .where((l) => l.id == lotId)
        .firstOrNull
        ?.myMaxBid;

    // Optimistic update: immediately reflect user's max bid in state
    if (mounted) {
      state = state.copyWith(
        activeLots: state.activeLots.map((l) {
          if (l.id == lotId) return l.copyWith(myMaxBid: maxBid);
          return l;
        }).toList(),
      );
    }

    try {
      await _draftRepo.setMaxBid(leagueId, draftId, lotId, maxBid);
      return null;
    } catch (e) {
      // Rollback only the specific myMaxBid change
      if (mounted) {
        state = state.copyWith(
          activeLots: state.activeLots.map((l) {
            if (l.id == lotId) return l.copyWith(myMaxBid: previousMaxBid);
            return l;
          }).toList(),
        );
      }
      return e.toString();
    }
  }

  /// Clear the outbid notification
  void clearOutbidNotification() {
    state = state.copyWith(clearOutbidNotification: true);
  }

  /// Helper to upsert a lot and maintain sorted order by bidDeadline
  void _upsertAndSortLot(AuctionLot lot) {
    final existingIndex = state.activeLots.indexWhere((l) => l.id == lot.id);
    List<AuctionLot> updated;
    if (existingIndex >= 0) {
      final existing = state.activeLots[existingIndex];
      final merged = lot.myMaxBid == null && existing.myMaxBid != null
          ? lot.copyWith(myMaxBid: existing.myMaxBid)
          : lot;
      updated = [...state.activeLots];
      updated[existingIndex] = merged;
    } else {
      updated = [...state.activeLots, lot];
    }
    // Sort by bidDeadline ASC
    updated.sort((a, b) => a.bidDeadline.compareTo(b.bidDeadline));
    state = state.copyWith(activeLots: updated);
  }

  // Socket callback implementations

  @override
  void onLotCreatedReceived(AuctionLot lot) {
    if (!mounted) return;
    _upsertAndSortLot(lot);
  }

  @override
  void onLotUpdatedReceived(AuctionLot lot) {
    if (!mounted) return;
    final myRosterId = _getMyRosterId();

    state = state.copyWith(
      activeLots: state.activeLots.map((l) {
        if (l.id == lot.id) {
          // Preserve user's myMaxBid when merging socket update
          return lot.copyWith(myMaxBid: l.myMaxBid);
        }
        return l;
      }).toList(),
    );

    // Instant refresh for own bid updates
    if (myRosterId != null && lot.currentBidderRosterId == myRosterId) {
      _budgetRefreshTimer?.cancel();
      if (mounted) loadAuctionData();
    } else {
      _budgetRefreshTimer?.cancel();
      _budgetRefreshTimer = Timer(const Duration(milliseconds: 200), () {
        if (mounted) loadAuctionData();
      });
    }
  }

  @override
  void onLotWonReceived(int lotId) {
    if (!mounted) return;
    state = state.copyWith(
      activeLots: state.activeLots.where((l) => l.id != lotId).toList(),
    );
    if (mounted) loadAuctionData();
  }

  @override
  void onLotPassedReceived(int lotId) {
    if (!mounted) return;
    state = state.copyWith(
      activeLots: state.activeLots.where((l) => l.id != lotId).toList(),
    );
  }

  @override
  void onOutbidReceived(OutbidNotification notification) {
    if (!mounted) return;
    state = state.copyWith(outbidNotification: notification);

    // Auto-dismiss outbid notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (state.outbidNotification?.lotId == notification.lotId &&
          state.outbidNotification?.playerId == notification.playerId) {
        clearOutbidNotification();
      }
    });
  }

  @override
  void onNominatorChangedReceived(
      int? rosterId, int? nominationNumber, DateTime? nominationDeadline) {
    if (!mounted) return;
    state = state.copyWith(
      currentNominatorRosterId: rosterId,
      nominationNumber: nominationNumber,
      nominationDeadline: nominationDeadline,
    );
  }

  @override
  void onAuctionErrorReceived(String message) {
    if (!mounted) return;
    state = state.copyWith(error: message);
  }

  @override
  void dispose() {
    _budgetRefreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for auction state - scoped to a specific draft
final auctionProvider = StateNotifierProvider.autoDispose
    .family<AuctionNotifier, AuctionState, AuctionKey>(
  (ref, key) {
    // Note: The myRosterId getter should be provided by the DraftRoomProvider
    // For now, we pass a placeholder - the real implementation will wire this up
    final notifier = AuctionNotifier(
      ref.watch(draftRepositoryProvider),
      key.leagueId,
      key.draftId,
      () => null, // Placeholder - will be connected via DraftRoomProvider
    );
    return notifier;
  },
);
