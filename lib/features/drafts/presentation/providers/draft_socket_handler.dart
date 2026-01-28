import 'dart:ui';

import '../../../../core/socket/socket_service.dart';
import '../../domain/auction_lot.dart';
import '../../domain/draft_pick.dart';

/// Notification when user is outbid on a lot
class OutbidNotification {
  final int lotId;
  final int playerId;
  final int newBid;
  final DateTime timestamp;

  OutbidNotification({
    required this.lotId,
    required this.playerId,
    required this.newBid,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Callbacks for draft socket events
abstract class DraftSocketCallbacks {
  void onPickReceived(DraftPick pick);
  void onNextPickReceived(Map<String, dynamic> data);
  void onDraftCompletedReceived(Map<String, dynamic> data);
  void onPickUndoneReceived(Map<String, dynamic> data);
  void onDraftPausedReceived();
  void onDraftResumedReceived();
  // Auction callbacks
  void onLotCreatedReceived(AuctionLot lot);
  void onLotUpdatedReceived(AuctionLot lot);
  void onLotWonReceived(int lotId);
  void onLotPassedReceived(int lotId);
  void onOutbidReceived(OutbidNotification notification);
  void onNominatorChangedReceived(int? rosterId, int? nominationNumber);
  void onAuctionErrorReceived(String message);
  // Autodraft callback
  void onAutodraftToggledReceived(int rosterId, bool enabled, bool forced);
}

/// Handles all socket event subscriptions for the draft room
class DraftSocketHandler {
  final SocketService _socketService;
  final int draftId;
  final DraftSocketCallbacks _callbacks;

  // Store disposers for proper cleanup
  final List<VoidCallback> _disposers = [];

  DraftSocketHandler({
    required SocketService socketService,
    required this.draftId,
    required DraftSocketCallbacks callbacks,
  })  : _socketService = socketService,
        _callbacks = callbacks;

  /// Set up all socket listeners
  void setupListeners() {
    _socketService.joinDraft(draftId);

    // Standard draft listeners
    _addDisposer(_socketService.onDraftPick((data) {
      final pick = DraftPick.fromJson(Map<String, dynamic>.from(data));
      _callbacks.onPickReceived(pick);
    }));

    _addDisposer(_socketService.onNextPick((data) {
      _callbacks.onNextPickReceived(data);
    }));

    _addDisposer(_socketService.onDraftCompleted((data) {
      _callbacks.onDraftCompletedReceived(data);
    }));

    _addDisposer(_socketService.onPickUndone((data) {
      _callbacks.onPickUndoneReceived(data);
    }));

    _addDisposer(_socketService.onDraftPaused((data) {
      _callbacks.onDraftPausedReceived();
    }));

    _addDisposer(_socketService.onDraftResumed((data) {
      _callbacks.onDraftResumedReceived();
    }));

    // Auction listeners
    _addDisposer(_socketService.onAuctionLotCreated((data) {
      final lot = AuctionLot.fromJson(Map<String, dynamic>.from(data['lot'] ?? data));
      _callbacks.onLotCreatedReceived(lot);
    }));

    _addDisposer(_socketService.onAuctionLotUpdated((data) {
      final lot = AuctionLot.fromJson(Map<String, dynamic>.from(data['lot'] ?? data));
      _callbacks.onLotUpdatedReceived(lot);
    }));

    _addDisposer(_socketService.onAuctionLotWon((data) {
      final lotId = data['lot_id'] as int? ?? data['lotId'] as int?;
      if (lotId != null) {
        _callbacks.onLotWonReceived(lotId);
      }
    }));

    _addDisposer(_socketService.onAuctionLotPassed((data) {
      final lotId = data['lot_id'] as int? ?? data['lotId'] as int?;
      if (lotId != null) {
        _callbacks.onLotPassedReceived(lotId);
      }
    }));

    _addDisposer(_socketService.onAuctionOutbid((data) {
      final notification = OutbidNotification(
        lotId: data['lotId'] as int? ?? data['lot_id'] as int? ?? 0,
        playerId: data['playerId'] as int? ?? data['player_id'] as int? ?? 0,
        newBid: data['newBid'] as int? ?? data['new_bid'] as int? ?? 0,
      );
      _callbacks.onOutbidReceived(notification);
    }));

    _addDisposer(_socketService.onAuctionNominatorChanged((data) {
      _callbacks.onNominatorChangedReceived(
        data['nominatorRosterId'] as int?,
        data['nominationNumber'] as int?,
      );
    }));

    _addDisposer(_socketService.onAuctionError((data) {
      final message = data['message'] as String? ?? 'Auction action failed';
      _callbacks.onAuctionErrorReceived(message);
    }));

    // Autodraft listener
    _addDisposer(_socketService.onAutodraftToggled((data) {
      final rosterId = data['rosterId'] as int? ?? data['roster_id'] as int? ?? 0;
      final enabled = data['enabled'] as bool? ?? false;
      final forced = data['forced'] as bool? ?? false;
      _callbacks.onAutodraftToggledReceived(rosterId, enabled, forced);
    }));
  }

  void _addDisposer(VoidCallback disposer) {
    _disposers.add(disposer);
  }

  /// Clean up all socket listeners
  void dispose() {
    _socketService.leaveDraft(draftId);
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }
}
