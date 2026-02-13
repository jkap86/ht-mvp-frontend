import 'package:flutter/foundation.dart' show VoidCallback, kDebugMode, debugPrint;

import '../../../../core/socket/socket_service.dart';

/// Callbacks for trade socket events
abstract class TradesSocketCallbacks {
  void onTradeProposedReceived(dynamic data);
  void onTradeAcceptedReceived(dynamic data);
  void onTradeRejectedReceived(dynamic data);
  void onTradeCounteredReceived(dynamic data);
  void onTradeCancelledReceived(dynamic data);
  void onTradeExpiredReceived(dynamic data);
  void onTradeCompletedReceived(dynamic data);
  void onTradeVetoedReceived(dynamic data);
  void onTradeVoteCastReceived(dynamic data);
  void onTradeInvalidatedReceived(dynamic data);
  void onMemberKickedReceived(dynamic data);
  void onReconnectedReceived(bool needsFullRefresh);
}

/// Handles all socket event subscriptions for trades
class TradesSocketHandler {
  final SocketService _socketService;
  final int leagueId;
  final TradesSocketCallbacks _callbacks;

  // Store disposers for proper cleanup
  final List<VoidCallback> _disposers = [];

  TradesSocketHandler({
    required SocketService socketService,
    required this.leagueId,
    required TradesSocketCallbacks callbacks,
  })  : _socketService = socketService,
        _callbacks = callbacks;

  /// Set up all socket listeners
  void setupListeners() {
    _socketService.joinLeague(leagueId);

    _addDisposer(_socketService.onTradeProposed((data) {
      _callbacks.onTradeProposedReceived(data);
    }));

    _addDisposer(_socketService.onTradeAccepted((data) {
      _callbacks.onTradeAcceptedReceived(data);
    }));

    _addDisposer(_socketService.onTradeRejected((data) {
      _callbacks.onTradeRejectedReceived(data);
    }));

    _addDisposer(_socketService.onTradeCountered((data) {
      _callbacks.onTradeCounteredReceived(data);
    }));

    _addDisposer(_socketService.onTradeCancelled((data) {
      _callbacks.onTradeCancelledReceived(data);
    }));

    _addDisposer(_socketService.onTradeExpired((data) {
      _callbacks.onTradeExpiredReceived(data);
    }));

    _addDisposer(_socketService.onTradeCompleted((data) {
      _callbacks.onTradeCompletedReceived(data);
    }));

    _addDisposer(_socketService.onTradeVetoed((data) {
      _callbacks.onTradeVetoedReceived(data);
    }));

    _addDisposer(_socketService.onTradeVoteCast((data) {
      _callbacks.onTradeVoteCastReceived(data);
    }));

    _addDisposer(_socketService.onTradeInvalidated((data) {
      _callbacks.onTradeInvalidatedReceived(data);
    }));

    // Listen for member kicked events - trades involving kicked member become invalid
    _addDisposer(_socketService.onMemberKicked((data) {
      _callbacks.onMemberKickedReceived(data);
    }));

    // Resync trades on socket reconnection (both short and long disconnects)
    _addDisposer(_socketService.onReconnected((needsFullRefresh) {
      if (kDebugMode) {
        debugPrint('Trades: Socket reconnected, needsFullRefresh=$needsFullRefresh');
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
