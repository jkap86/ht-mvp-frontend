import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_service.dart';
import 'socket_events_typed.dart';
import '../constants/socket_events.dart';

/// Callback type for handling typed socket events.
typedef SocketEventHandler<T extends SocketEvent> = void Function(T event);

/// Central router for socket events.
///
/// Features register handlers through this router instead of subscribing
/// directly to the socket service. This provides:
/// - Type-safe event handling with parsed payloads
/// - Centralized event parsing (no duplicated parsing logic)
/// - Single subscription point for each event type
/// - Automatic cleanup when handlers are unregistered
///
/// Usage:
/// ```dart
/// // In a provider or widget
/// final router = ref.watch(socketEventRouterProvider);
/// final dispose = router.register<DraftPickEvent>((event) {
///   // Handle the typed event
///   print('Pick made: ${event.pick.playerId}');
/// });
///
/// // Call dispose() when done to unregister
/// ```
class SocketEventRouter {
  final SocketService _socketService;

  /// Handlers by event type
  final Map<Type, List<Function>> _handlers = {};

  /// Socket disposers for each event type we're listening to
  final Map<String, VoidCallback> _socketDisposers = {};

  /// Map of event types to their socket event names
  static final Map<Type, String> _eventTypeToSocketEvent = {
    // Draft events
    DraftCreatedEvent: SocketEvents.draftCreated,
    DraftStartedEvent: SocketEvents.draftStarted,
    DraftPickEvent: SocketEvents.draftPickMade,
    NextPickEvent: SocketEvents.draftNextPick,
    DraftPausedEvent: SocketEvents.draftPaused,
    DraftResumedEvent: SocketEvents.draftResumed,
    DraftCompletedEvent: SocketEvents.draftCompleted,
    PickUndoneEvent: SocketEvents.draftPickUndone,
    AutodraftToggledEvent: SocketEvents.draftAutodraftToggled,
    QueueUpdatedEvent: SocketEvents.draftQueueUpdated,
    // Auction events
    AuctionLotCreatedEvent: SocketEvents.auctionLotCreated,
    AuctionLotUpdatedEvent: SocketEvents.auctionLotUpdated,
    AuctionLotWonEvent: SocketEvents.auctionLotWon,
    AuctionLotPassedEvent: SocketEvents.auctionLotPassed,
    AuctionOutbidEvent: SocketEvents.auctionOutbid,
    AuctionNominatorChangedEvent: SocketEvents.auctionNominatorChanged,
    AuctionErrorEvent: SocketEvents.auctionError,
    // Trade events
    TradeProposedEvent: SocketEvents.tradeProposed,
    TradeAcceptedEvent: SocketEvents.tradeAccepted,
    TradeRejectedEvent: SocketEvents.tradeRejected,
    TradeCounteredEvent: SocketEvents.tradeCountered,
    TradeCancelledEvent: SocketEvents.tradeCancelled,
    TradeExpiredEvent: SocketEvents.tradeExpired,
    TradeCompletedEvent: SocketEvents.tradeCompleted,
    TradeVetoedEvent: SocketEvents.tradeVetoed,
    TradeVoteCastEvent: SocketEvents.tradeVoteCast,
    // Waiver events
    WaiverClaimSubmittedEvent: SocketEvents.waiverClaimSubmitted,
    WaiverClaimCancelledEvent: SocketEvents.waiverClaimCancelled,
    WaiverProcessedEvent: SocketEvents.waiverProcessed,
    WaiverClaimSuccessfulEvent: SocketEvents.waiverClaimSuccessful,
    WaiverClaimFailedEvent: SocketEvents.waiverClaimFailed,
    // Chat events
    ChatMessageEvent: SocketEvents.chatMessage,
    DmMessageEvent: SocketEvents.dmMessage,
    // Scoring events
    ScoresUpdatedEvent: SocketEvents.scoringScoresUpdated,
    WeekFinalizedEvent: SocketEvents.scoringWeekFinalized,
    // App events
    AppErrorEvent: SocketEvents.appError,
  };

  /// Factory functions to parse raw data into typed events
  static final Map<Type, SocketEvent Function(Map<String, dynamic>)>
      _eventFactories = {
    // Draft events
    DraftCreatedEvent: DraftCreatedEvent.fromJson,
    DraftStartedEvent: DraftStartedEvent.fromJson,
    DraftPickEvent: DraftPickEvent.fromJson,
    NextPickEvent: NextPickEvent.fromJson,
    DraftPausedEvent: DraftPausedEvent.fromJson,
    DraftResumedEvent: DraftResumedEvent.fromJson,
    DraftCompletedEvent: DraftCompletedEvent.fromJson,
    PickUndoneEvent: PickUndoneEvent.fromJson,
    AutodraftToggledEvent: AutodraftToggledEvent.fromJson,
    QueueUpdatedEvent: QueueUpdatedEvent.fromJson,
    // Auction events
    AuctionLotCreatedEvent: AuctionLotCreatedEvent.fromJson,
    AuctionLotUpdatedEvent: AuctionLotUpdatedEvent.fromJson,
    AuctionLotWonEvent: AuctionLotWonEvent.fromJson,
    AuctionLotPassedEvent: AuctionLotPassedEvent.fromJson,
    AuctionOutbidEvent: AuctionOutbidEvent.fromJson,
    AuctionNominatorChangedEvent: AuctionNominatorChangedEvent.fromJson,
    AuctionErrorEvent: AuctionErrorEvent.fromJson,
    // Trade events
    TradeProposedEvent: TradeProposedEvent.fromJson,
    TradeAcceptedEvent: TradeAcceptedEvent.fromJson,
    TradeRejectedEvent: TradeRejectedEvent.fromJson,
    TradeCounteredEvent: TradeCounteredEvent.fromJson,
    TradeCancelledEvent: TradeCancelledEvent.fromJson,
    TradeExpiredEvent: TradeExpiredEvent.fromJson,
    TradeCompletedEvent: TradeCompletedEvent.fromJson,
    TradeVetoedEvent: TradeVetoedEvent.fromJson,
    TradeVoteCastEvent: TradeVoteCastEvent.fromJson,
    // Waiver events
    WaiverClaimSubmittedEvent: WaiverClaimSubmittedEvent.fromJson,
    WaiverClaimCancelledEvent: WaiverClaimCancelledEvent.fromJson,
    WaiverProcessedEvent: WaiverProcessedEvent.fromJson,
    WaiverClaimSuccessfulEvent: WaiverClaimSuccessfulEvent.fromJson,
    WaiverClaimFailedEvent: WaiverClaimFailedEvent.fromJson,
    // Chat events
    ChatMessageEvent: ChatMessageEvent.fromJson,
    DmMessageEvent: DmMessageEvent.fromJson,
    // Scoring events
    ScoresUpdatedEvent: ScoresUpdatedEvent.fromJson,
    WeekFinalizedEvent: WeekFinalizedEvent.fromJson,
    // App events
    AppErrorEvent: AppErrorEvent.fromJson,
  };

  SocketEventRouter(this._socketService);

  /// Register a handler for a specific event type.
  ///
  /// Returns a disposer function that unregisters this specific handler.
  /// Call the disposer in your dispose() method to clean up.
  ///
  /// Example:
  /// ```dart
  /// final dispose = router.register<DraftPickEvent>((event) {
  ///   setState(() => picks.add(event.pick));
  /// });
  ///
  /// @override
  /// void dispose() {
  ///   dispose();
  ///   super.dispose();
  /// }
  /// ```
  VoidCallback register<T extends SocketEvent>(SocketEventHandler<T> handler) {
    final eventType = T;
    final socketEvent = _eventTypeToSocketEvent[eventType];
    final factory = _eventFactories[eventType];

    if (socketEvent == null || factory == null) {
      throw ArgumentError('Unknown event type: $eventType');
    }

    // Add handler to list
    _handlers.putIfAbsent(eventType, () => []);
    _handlers[eventType]!.add(handler);

    // If this is the first handler for this event type, subscribe to socket
    if (_handlers[eventType]!.length == 1) {
      _socketDisposers[socketEvent] = _socketService.on(socketEvent, (data) {
        _dispatchEvent<T>(eventType, data, factory as T Function(Map<String, dynamic>));
      });
    }

    // Return disposer
    return () {
      _handlers[eventType]?.remove(handler);

      // If no more handlers, unsubscribe from socket
      if (_handlers[eventType]?.isEmpty ?? true) {
        _socketDisposers[socketEvent]?.call();
        _socketDisposers.remove(socketEvent);
        _handlers.remove(eventType);
      }
    };
  }

  /// Register multiple handlers at once, returning a single disposer.
  ///
  /// Useful when a widget needs to listen to multiple event types.
  ///
  /// Example:
  /// ```dart
  /// final dispose = router.registerMany([
  ///   EventRegistration<DraftPickEvent>((e) => handlePick(e)),
  ///   EventRegistration<NextPickEvent>((e) => handleNextPick(e)),
  /// ]);
  /// ```
  VoidCallback registerMany(List<EventRegistration> registrations) {
    final disposers = <VoidCallback>[];

    for (final reg in registrations) {
      disposers.add(reg._register(this));
    }

    return () {
      for (final d in disposers) {
        d();
      }
    };
  }

  /// Dispatch a parsed event to all registered handlers.
  void _dispatchEvent<T extends SocketEvent>(
    Type eventType,
    dynamic data,
    T Function(Map<String, dynamic>) factory,
  ) {
    try {
      final json = _normalizeData(data);
      if (json == null) {
        if (kDebugMode) {
          debugPrint('SocketEventRouter: Invalid data for $eventType: $data');
        }
        return;
      }

      final event = factory(json);
      final handlers = _handlers[eventType];

      if (handlers != null) {
        for (final handler in List<Function>.from(handlers)) {
          try {
            (handler as SocketEventHandler<T>)(event);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('SocketEventRouter: Handler error for $eventType: $e');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SocketEventRouter: Parse error for $eventType: $e');
      }
    }
  }

  /// Normalize incoming data to `Map<String, dynamic>`.
  Map<String, dynamic>? _normalizeData(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Check if any handlers are registered for an event type.
  bool hasHandlers<T extends SocketEvent>() {
    return _handlers[T]?.isNotEmpty ?? false;
  }

  /// Get the number of handlers for an event type.
  int handlerCount<T extends SocketEvent>() {
    return _handlers[T]?.length ?? 0;
  }

  /// Dispose all handlers and socket subscriptions.
  void dispose() {
    for (final disposer in _socketDisposers.values) {
      disposer();
    }
    _socketDisposers.clear();
    _handlers.clear();
  }
}

/// Helper class for registering multiple handlers.
///
/// Use with [SocketEventRouter.registerMany].
class EventRegistration<T extends SocketEvent> {
  final SocketEventHandler<T> handler;

  EventRegistration(this.handler);

  VoidCallback _register(SocketEventRouter router) {
    return router.register<T>(handler);
  }
}

/// Provider for the socket event router.
///
/// This is a singleton that lives for the app lifecycle.
/// Features should use this provider to access the router.
final socketEventRouterProvider = Provider<SocketEventRouter>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final router = SocketEventRouter(socketService);

  ref.onDispose(() {
    router.dispose();
  });

  return router;
});
