import 'package:flutter/foundation.dart' show VoidCallback, kDebugMode, debugPrint;

import '../../../../core/socket/socket_service.dart';

/// Callbacks for waiver socket events
abstract class WaiversSocketCallbacks {
  void onClaimSubmittedReceived(dynamic data);
  void onClaimCancelledReceived(dynamic data);
  void onClaimUpdatedReceived(dynamic data);
  void onClaimsReorderedReceived(dynamic data);
  void onWaiverProcessedReceived(dynamic data);
  void onClaimSuccessfulReceived(dynamic data);
  void onClaimFailedReceived(dynamic data);
  void onPriorityUpdatedReceived(dynamic data);
  void onBudgetUpdatedReceived(dynamic data);
  void onMemberKickedReceived(dynamic data);
  void onReconnectedReceived(bool needsFullRefresh);
}

/// Handles all socket event subscriptions for waivers
class WaiversSocketHandler {
  final SocketService _socketService;
  final int leagueId;
  final WaiversSocketCallbacks _callbacks;

  // Store disposers for proper cleanup
  final List<VoidCallback> _disposers = [];

  WaiversSocketHandler({
    required SocketService socketService,
    required this.leagueId,
    required WaiversSocketCallbacks callbacks,
  })  : _socketService = socketService,
        _callbacks = callbacks;

  /// Set up all socket listeners
  void setupListeners() {
    _socketService.joinLeague(leagueId);

    _addDisposer(_socketService.onWaiverClaimSubmitted((data) {
      _callbacks.onClaimSubmittedReceived(data);
    }));

    _addDisposer(_socketService.onWaiverClaimCancelled((data) {
      _callbacks.onClaimCancelledReceived(data);
    }));

    _addDisposer(_socketService.onWaiverClaimUpdated((data) {
      _callbacks.onClaimUpdatedReceived(data);
    }));

    _addDisposer(_socketService.onWaiverClaimsReordered((data) {
      _callbacks.onClaimsReorderedReceived(data);
    }));

    _addDisposer(_socketService.onWaiverProcessed((data) {
      _callbacks.onWaiverProcessedReceived(data);
    }));

    _addDisposer(_socketService.onWaiverClaimSuccessful((data) {
      _callbacks.onClaimSuccessfulReceived(data);
    }));

    _addDisposer(_socketService.onWaiverClaimFailed((data) {
      _callbacks.onClaimFailedReceived(data);
    }));

    _addDisposer(_socketService.onWaiverPriorityUpdated((data) {
      _callbacks.onPriorityUpdatedReceived(data);
    }));

    _addDisposer(_socketService.onWaiverBudgetUpdated((data) {
      _callbacks.onBudgetUpdatedReceived(data);
    }));

    // Listen for member kicked events - refresh if kicked user had waiver claims
    _addDisposer(_socketService.onMemberKicked((data) {
      _callbacks.onMemberKickedReceived(data);
    }));

    // Resync waivers on socket reconnection (both short and long disconnects)
    _addDisposer(_socketService.onReconnected((needsFullRefresh) {
      if (kDebugMode) {
        debugPrint('Waivers: Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      _callbacks.onReconnectedReceived(needsFullRefresh);
    }));
  }

  void _addDisposer(VoidCallback disposer) {
    _disposers.add(disposer);
  }

  /// Clean up all socket listeners
  void dispose() {
    _socketService.leaveLeague(leagueId);
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }
}
