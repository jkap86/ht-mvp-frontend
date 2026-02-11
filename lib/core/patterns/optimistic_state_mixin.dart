import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mixin that provides optimistic update capabilities to a StateNotifier.
///
/// Use this mixin to implement optimistic updates with automatic rollback
/// on failure. The mixin provides two main patterns:
///
/// 1. **Full state optimistic updates** - for replacing entire state
/// 2. **Field-level optimistic updates** - for updating specific fields
///
/// Example usage:
/// ```dart
/// class DraftRoomNotifier extends StateNotifier<DraftRoomState>
///     with OptimisticStateMixin<DraftRoomState> {
///
///   Future<void> makePick(int playerId) async {
///     await executeOptimistic(
///       updateState: (state) => state.copyWith(
///         lastPickPlayerId: playerId,
///         isPickPending: true,
///       ),
///       rollbackState: (state) => state.copyWith(
///         lastPickPlayerId: null,
///         isPickPending: false,
///       ),
///       action: () => _api.makePick(playerId),
///     );
///   }
/// }
/// ```
mixin OptimisticStateMixin<S> on StateNotifier<S> {
  /// Execute an optimistic update with automatic rollback on failure.
  ///
  /// [updateState] - Function that applies the optimistic update
  /// [rollbackState] - Optional function that reverts the update on failure.
  ///                   If not provided, the original state is restored.
  /// [action] - The async action to execute (API call, etc.)
  /// [onSuccess] - Optional callback when action succeeds
  /// [onError] - Optional callback when action fails
  ///
  /// Returns the result of the action, or null if it failed.
  Future<T?> executeOptimistic<T>({
    required S Function(S) updateState,
    S Function(S)? rollbackState,
    required Future<T> Function() action,
    void Function(T)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    // Capture original state for rollback
    final originalState = state;

    // Apply optimistic update
    state = updateState(state);

    try {
      // Execute the actual action
      final result = await action();

      // Success - optionally call success handler
      onSuccess?.call(result);

      return result;
    } catch (e) {
      // Failure - rollback state
      if (rollbackState != null) {
        state = rollbackState(state);
      } else {
        state = originalState;
      }

      // Call error handler
      onError?.call(e);

      if (kDebugMode) {
        debugPrint('OptimisticStateMixin: Action failed, rolled back: $e');
      }

      return null;
    }
  }

  /// Execute an optimistic update for a specific field.
  ///
  /// This is a convenience method for simple field updates.
  ///
  /// [getField] - Extracts the field from state
  /// [setField] - Updates the field in state
  /// [optimisticValue] - The value to set optimistically
  /// [action] - The async action to execute
  ///
  /// Example:
  /// ```dart
  /// await executeFieldOptimistic<DraftPick?, int>(
  ///   getField: (s) => s.lastPick,
  ///   setField: (s, v) => s.copyWith(lastPick: v),
  ///   optimisticValue: optimisticPick,
  ///   action: () => _api.makePick(playerId),
  /// );
  /// ```
  Future<T?> executeFieldOptimistic<T, F>({
    required F Function(S) getField,
    required S Function(S, F) setField,
    required F optimisticValue,
    required Future<T> Function() action,
    void Function(T)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    final originalValue = getField(state);

    return executeOptimistic(
      updateState: (s) => setField(s, optimisticValue),
      rollbackState: (s) => setField(s, originalValue),
      action: action,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  /// Execute multiple optimistic updates atomically.
  ///
  /// All updates succeed or all are rolled back together.
  ///
  /// [updates] - List of state update functions to apply
  /// [action] - The async action to execute
  ///
  /// Example:
  /// ```dart
  /// await executeMultipleOptimistic(
  ///   updates: [
  ///     (s) => s.copyWith(budget: s.budget - bidAmount),
  ///     (s) => s.copyWith(pendingBid: bidAmount),
  ///   ],
  ///   action: () => _api.placeBid(bidAmount),
  /// );
  /// ```
  Future<T?> executeMultipleOptimistic<T>({
    required List<S Function(S)> updates,
    required Future<T> Function() action,
    void Function(T)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    final originalState = state;

    // Apply all updates in order
    S updatedState = state;
    for (final update in updates) {
      updatedState = update(updatedState);
    }
    state = updatedState;

    try {
      final result = await action();
      onSuccess?.call(result);
      return result;
    } catch (e) {
      // Rollback to original state
      state = originalState;
      onError?.call(e);

      if (kDebugMode) {
        debugPrint('OptimisticStateMixin: Multi-update failed, rolled back: $e');
      }

      return null;
    }
  }

  /// Execute an optimistic action that may be superseded by server state.
  ///
  /// Use this when the server might send a different value than what was
  /// requested (e.g., auction bids where someone else might win).
  ///
  /// [updateState] - The optimistic update
  /// [action] - The async action
  /// [reconcile] - Function to reconcile server response with current state
  ///
  /// Example:
  /// ```dart
  /// await executeWithReconciliation(
  ///   updateState: (s) => s.copyWith(myBid: bidAmount),
  ///   action: () => _api.placeBid(bidAmount),
  ///   reconcile: (s, serverBid) => s.copyWith(
  ///     currentBid: serverBid.amount,
  ///     highBidder: serverBid.rosterId,
  ///   ),
  /// );
  /// ```
  Future<T?> executeWithReconciliation<T>({
    required S Function(S) updateState,
    required Future<T> Function() action,
    required S Function(S, T) reconcile,
    void Function(Object error)? onError,
  }) async {
    final originalState = state;

    // Apply optimistic update
    state = updateState(state);

    try {
      final result = await action();

      // Reconcile with server response
      state = reconcile(state, result);

      return result;
    } catch (e) {
      // Rollback on error
      state = originalState;
      onError?.call(e);

      if (kDebugMode) {
        debugPrint('OptimisticStateMixin: Reconciliation failed, rolled back: $e');
      }

      return null;
    }
  }
}

/// Extension to provide optimistic update tracking for AsyncNotifier.
///
/// Use this when working with AsyncValue state.
mixin OptimisticAsyncMixin<S> on AutoDisposeAsyncNotifier<S> {
  /// Execute an optimistic update on async state.
  ///
  /// Maintains the AsyncData wrapper while updating the inner value.
  Future<T?> executeOptimisticAsync<T>({
    required S Function(S) updateState,
    S Function(S)? rollbackState,
    required Future<T> Function() action,
    void Function(T)? onSuccess,
    void Function(Object error)? onError,
  }) async {
    final currentState = state;

    // Only proceed if we have data
    if (currentState is! AsyncData<S>) {
      return null;
    }

    final originalData = currentState.value;

    // Apply optimistic update
    state = AsyncData(updateState(originalData));

    try {
      final result = await action();
      onSuccess?.call(result);
      return result;
    } catch (e) {
      // Rollback
      if (rollbackState != null) {
        final current = state;
        if (current is AsyncData<S>) {
          state = AsyncData(rollbackState(current.value));
        }
      } else {
        state = AsyncData(originalData);
      }

      onError?.call(e);

      if (kDebugMode) {
        debugPrint('OptimisticAsyncMixin: Action failed, rolled back: $e');
      }

      return null;
    }
  }
}
