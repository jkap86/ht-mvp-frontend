import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Types of data that can be invalidated.
enum InvalidationType {
  team,
  freeAgents,
  standings,
  trades,
  waivers,
  leagueDetail,
  matchups,
  picks,
}

/// Events that can trigger invalidation.
enum InvalidationEvent {
  tradeAccepted,
  tradeCompleted,
  playerAdded,
  playerDropped,
  waiverProcessed,
  waiverClaimSuccessful,
  draftCreated,
  draftCompleted,
  memberJoined,
  memberKicked,
  scoresUpdated,
}

/// Callback type for invalidation handlers.
typedef InvalidationCallback = Future<void> Function();

/// Service to manage cross-provider invalidation.
///
/// When a mutation occurs in one provider (e.g., accepting a trade),
/// this service notifies other providers that their data may be stale.
///
/// Example: When a trade is accepted, the team provider, free agents provider,
/// and standings provider all need to refresh their data.
class InvalidationService {
  /// Map of invalidation type -> leagueId -> callbacks
  final Map<InvalidationType, Map<int, List<InvalidationCallback>>> _callbacks = {};

  /// Defines which providers should be invalidated for each event.
  static const Map<InvalidationEvent, List<InvalidationType>> invalidationRules = {
    InvalidationEvent.tradeAccepted: [
      InvalidationType.team,
      InvalidationType.freeAgents,
      InvalidationType.standings,
      InvalidationType.matchups,
      InvalidationType.picks,
    ],
    InvalidationEvent.tradeCompleted: [
      InvalidationType.team,
      InvalidationType.freeAgents,
      InvalidationType.standings,
      InvalidationType.matchups,
      InvalidationType.picks,
    ],
    InvalidationEvent.playerAdded: [
      InvalidationType.team,
      InvalidationType.standings,
    ],
    InvalidationEvent.playerDropped: [
      InvalidationType.freeAgents,
      InvalidationType.standings,
    ],
    InvalidationEvent.waiverProcessed: [
      InvalidationType.team,
      InvalidationType.freeAgents,
      InvalidationType.standings,
      InvalidationType.waivers,
      InvalidationType.matchups,
    ],
    InvalidationEvent.waiverClaimSuccessful: [
      InvalidationType.team,
      InvalidationType.freeAgents,
    ],
    InvalidationEvent.draftCreated: [
      InvalidationType.leagueDetail,
    ],
    InvalidationEvent.draftCompleted: [
      InvalidationType.team,
      InvalidationType.freeAgents,
      InvalidationType.leagueDetail,
    ],
    InvalidationEvent.memberJoined: [
      InvalidationType.leagueDetail,
      InvalidationType.standings,
    ],
    InvalidationEvent.memberKicked: [
      InvalidationType.leagueDetail,
      InvalidationType.standings,
      InvalidationType.trades,
      InvalidationType.waivers,
    ],
    InvalidationEvent.scoresUpdated: [
      InvalidationType.matchups,
      InvalidationType.standings,
    ],
  };

  InvalidationService(Ref _);

  /// Register a callback to be called when a specific data type is invalidated.
  /// Returns a function to unregister the callback.
  VoidCallback register(
    InvalidationType type,
    int leagueId,
    InvalidationCallback callback,
  ) {
    _callbacks.putIfAbsent(type, () => {});
    _callbacks[type]!.putIfAbsent(leagueId, () => []).add(callback);

    return () {
      _callbacks[type]?[leagueId]?.remove(callback);
      if (_callbacks[type]?[leagueId]?.isEmpty ?? false) {
        _callbacks[type]!.remove(leagueId);
      }
    };
  }

  /// Trigger invalidation for a specific event in a league.
  /// This will call all registered callbacks for the affected data types.
  Future<void> invalidate(InvalidationEvent event, int leagueId) async {
    final types = invalidationRules[event];
    if (types == null || types.isEmpty) {
      if (kDebugMode) {
        debugPrint('InvalidationService: No rules for event $event');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('InvalidationService: Invalidating $types for event $event in league $leagueId');
    }

    // Run independent type invalidations in parallel for better performance
    await Future.wait(
      types.map((type) => _invalidateType(type, leagueId)),
    );
  }

  /// Directly invalidate a specific data type in a league.
  Future<void> invalidateType(InvalidationType type, int leagueId) async {
    await _invalidateType(type, leagueId);
  }

  /// Internal method to invalidate a specific type.
  Future<void> _invalidateType(InvalidationType type, int leagueId) async {
    final callbacks = _callbacks[type]?[leagueId];
    if (callbacks == null || callbacks.isEmpty) {
      if (kDebugMode) {
        debugPrint('InvalidationService: No callbacks for $type in league $leagueId');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('InvalidationService: Calling ${callbacks.length} callbacks for $type in league $leagueId');
    }

    // Make a copy to avoid concurrent modification
    final callbacksCopy = List<InvalidationCallback>.from(callbacks);
    for (final callback in callbacksCopy) {
      try {
        await callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('InvalidationService: Error invalidating $type: $e');
        }
      }
    }
  }

  /// Invalidate all data types for a league.
  Future<void> invalidateAll(int leagueId) async {
    if (kDebugMode) {
      debugPrint('InvalidationService: Invalidating all types for league $leagueId');
    }
    for (final type in InvalidationType.values) {
      await _invalidateType(type, leagueId);
    }
  }
}

/// Provider for the invalidation service.
final invalidationServiceProvider = Provider<InvalidationService>((ref) {
  return InvalidationService(ref);
});
