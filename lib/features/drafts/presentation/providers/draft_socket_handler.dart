import 'package:flutter/foundation.dart';

import '../../../../core/socket/socket_service.dart';
import '../../domain/auction_lot.dart';
import '../../domain/derby_state.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';

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
  void onNominatorChangedReceived(int? rosterId, int? nominationNumber, DateTime? nominationDeadline);
  void onAuctionErrorReceived(String message);
  // Autodraft callback
  void onAutodraftToggledReceived(int rosterId, bool enabled, bool forced);
  // Pick trading callback
  void onPickTradedReceived(DraftPickAsset pickAsset);
  // Settings updated callback (commissioner changed settings)
  void onDraftSettingsUpdatedReceived(Map<String, dynamic> data);
  // Derby callbacks (draft order selection phase)
  void onDerbyStateReceived(DerbyState state);
  void onDerbySlotPickedReceived(Map<String, dynamic> data);
  void onDerbyTurnChangedReceived(Map<String, dynamic> data);
  void onDerbyPhaseTransitionReceived(Map<String, dynamic> data);
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
      // Defensive parsing: ensure data is a valid Map before processing
      if (data is! Map) return;
      try {
        final pick = DraftPick.fromJson(Map<String, dynamic>.from(data));
        _callbacks.onPickReceived(pick);
      } catch (e) {
        // Log parsing error but don't crash - malformed socket data shouldn't break UI
        debugPrint('Failed to parse draft pick: $e');
      }
    }));

    _addDisposer(_socketService.onNextPick((data) {
      // Defensive parsing: ensure data is a valid Map before processing
      if (data is! Map) return;
      try {
        _callbacks.onNextPickReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        // Log parsing error but don't crash - malformed socket data shouldn't break UI
        debugPrint('Failed to parse next pick: $e');
      }
    }));

    _addDisposer(_socketService.onDraftCompleted((data) {
      // Defensive parsing: ensure data is a valid Map before processing
      if (data is! Map) return;
      try {
        _callbacks.onDraftCompletedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Failed to parse draft completed: $e');
      }
    }));

    _addDisposer(_socketService.onPickUndone((data) {
      // Defensive parsing: ensure data is a valid Map before processing
      if (data is! Map) return;
      try {
        _callbacks.onPickUndoneReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Failed to parse pick undone: $e');
      }
    }));

    _addDisposer(_socketService.onDraftPaused((data) {
      _callbacks.onDraftPausedReceived();
    }));

    _addDisposer(_socketService.onDraftResumed((data) {
      _callbacks.onDraftResumedReceived();
    }));

    // Auction listeners
    _addDisposer(_socketService.onAuctionLotCreated((data) {
      // Defensive parsing: ensure data contains valid lot information
      try {
        final lotData = data['lot'] ?? data;
        if (lotData is! Map) return;
        final lot = AuctionLot.fromJson(Map<String, dynamic>.from(lotData));
        _callbacks.onLotCreatedReceived(lot);
      } catch (e) {
        debugPrint('Failed to parse auction lot created: $e');
      }
    }));

    _addDisposer(_socketService.onAuctionLotUpdated((data) {
      // Defensive parsing: ensure data contains valid lot information
      try {
        final lotData = data['lot'] ?? data;
        if (lotData is! Map) return;
        final lot = AuctionLot.fromJson(Map<String, dynamic>.from(lotData));
        _callbacks.onLotUpdatedReceived(lot);
      } catch (e) {
        debugPrint('Failed to parse auction lot updated: $e');
      }
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
      // Parse nomination deadline from socket event
      final deadlineStr = data['nominationDeadline'] as String?;
      final nominationDeadline = deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;
      _callbacks.onNominatorChangedReceived(
        data['nominatorRosterId'] as int?,
        data['nominationNumber'] as int?,
        nominationDeadline,
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

    // Pick traded listener
    _addDisposer(_socketService.onDraftPickTraded((data) {
      // Defensive parsing: ensure data contains valid pick asset
      try {
        final pickAssetData = data['pick_asset'] ?? data['pickAsset'] ?? data;
        if (pickAssetData is! Map) return;
        final pickAsset = DraftPickAsset.fromJson(
          Map<String, dynamic>.from(pickAssetData),
        );
        _callbacks.onPickTradedReceived(pickAsset);
      } catch (e) {
        debugPrint('Failed to parse pick traded: $e');
      }
    }));

    // Settings updated listener
    _addDisposer(_socketService.onDraftSettingsUpdated((data) {
      // Defensive parsing: ensure data is a valid Map
      if (data is! Map) return;
      try {
        _callbacks.onDraftSettingsUpdatedReceived(
          Map<String, dynamic>.from(data),
        );
      } catch (e) {
        debugPrint('Failed to parse draft settings: $e');
      }
    }));

    // Derby listeners (draft order selection phase)
    _addDisposer(_socketService.onDerbyState((data) {
      if (data is! Map) return;
      try {
        final state = DerbyState.fromJson(Map<String, dynamic>.from(data));
        _callbacks.onDerbyStateReceived(state);
      } catch (e) {
        debugPrint('Failed to parse derby state: $e');
      }
    }));

    _addDisposer(_socketService.onDerbySlotPicked((data) {
      if (data is! Map) return;
      try {
        _callbacks.onDerbySlotPickedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Failed to parse derby slot picked: $e');
      }
    }));

    _addDisposer(_socketService.onDerbyTurnChanged((data) {
      if (data is! Map) return;
      try {
        _callbacks.onDerbyTurnChangedReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Failed to parse derby turn changed: $e');
      }
    }));

    _addDisposer(_socketService.onDerbyPhaseTransition((data) {
      if (data is! Map) return;
      try {
        _callbacks.onDerbyPhaseTransitionReceived(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Failed to parse derby phase transition: $e');
      }
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
