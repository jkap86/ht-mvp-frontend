import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../api/api_exceptions.dart';

const _uuid = Uuid();

/// State for the centralized action idempotency tracker.
class ActionIdempotencyState {
  final Map<String, String> keys; // actionId -> UUID idempotency key
  final Set<String> inFlight; // actionIds currently in progress

  const ActionIdempotencyState({
    this.keys = const {},
    this.inFlight = const {},
  });

  ActionIdempotencyState copyWith({
    Map<String, String>? keys,
    Set<String>? inFlight,
  }) {
    return ActionIdempotencyState(
      keys: keys ?? this.keys,
      inFlight: inFlight ?? this.inFlight,
    );
  }
}

/// Centralized idempotency key manager with in-flight deduplication.
///
/// Usage:
/// ```dart
/// await ref.read(actionIdempotencyProvider.notifier).run(
///   actionId: ActionIds.draftPick(draftId, rosterId, pickNumber),
///   op: (key) => repo.makePick(..., idempotencyKey: key),
/// );
/// ```
class ActionIdempotencyNotifier extends StateNotifier<ActionIdempotencyState> {
  ActionIdempotencyNotifier() : super(const ActionIdempotencyState());

  /// Returns the existing UUID key for [actionId], or creates a new one.
  String getOrCreate(String actionId) {
    final existing = state.keys[actionId];
    if (existing != null) return existing;
    final key = _uuid.v4();
    state = state.copyWith(keys: {...state.keys, actionId: key});
    return key;
  }

  /// Whether [actionId] is currently in-flight.
  bool isInFlight(String actionId) => state.inFlight.contains(actionId);

  /// Execute [op] with idempotency key tracking and in-flight deduplication.
  ///
  /// - On success: clears the stored key (action completed).
  /// - On terminal error (4xx except 409): clears key (bad request, won't retry).
  /// - On retryable error (network/5xx): keeps key for safe retry.
  /// - On 409 conflict: treats as success (clears key + returns).
  Future<T?> run<T>({
    required String actionId,
    required Future<T> Function(String key) op,
  }) async {
    // Prevent duplicate in-flight submissions
    if (state.inFlight.contains(actionId)) return null;

    final key = getOrCreate(actionId);
    state = state.copyWith(inFlight: {...state.inFlight, actionId});

    try {
      final result = await op(key);
      // Success: clear key
      _clearKey(actionId);
      return result;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // 409 Conflict: treat as success (duplicate accepted by server)
        _clearKey(actionId);
        return null;
      } else if (e.statusCode != null &&
          e.statusCode! >= 400 &&
          e.statusCode! < 500) {
        // Terminal client error: clear key (bad request won't succeed on retry)
        _clearKey(actionId);
        rethrow;
      } else {
        // Retryable error (5xx / network): keep key for retry
        rethrow;
      }
    } catch (_) {
      // Network or unknown error: keep key for retry
      rethrow;
    } finally {
      // Always remove from in-flight
      final newInFlight = {...state.inFlight}..remove(actionId);
      state = state.copyWith(inFlight: newInFlight);
    }
  }

  /// Clear the stored key for [actionId].
  void clear(String actionId) {
    _clearKey(actionId);
  }

  /// Clear all keys whose actionId starts with [prefix].
  /// Use on dispose/navigation to clean up scoped actions.
  void clearPrefix(String prefix) {
    final newKeys = Map<String, String>.from(state.keys)
      ..removeWhere((key, _) => key.startsWith(prefix));
    final newInFlight = Set<String>.from(state.inFlight)
      ..removeWhere((id) => id.startsWith(prefix));
    state = state.copyWith(keys: newKeys, inFlight: newInFlight);
  }

  void _clearKey(String actionId) {
    final newKeys = Map<String, String>.from(state.keys)..remove(actionId);
    state = state.copyWith(keys: newKeys);
  }
}

final actionIdempotencyProvider =
    StateNotifierProvider<ActionIdempotencyNotifier, ActionIdempotencyState>(
  (ref) => ActionIdempotencyNotifier(),
);
