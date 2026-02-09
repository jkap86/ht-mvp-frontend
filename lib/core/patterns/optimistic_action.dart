/// Optimistic action tracking for UI state management.
///
/// This file provides classes and utilities for tracking optimistic updates
/// and handling rollback when server requests fail.
library;

import 'package:flutter/foundation.dart';

/// Status of an optimistic action.
enum OptimisticActionStatus {
  /// Action is in progress, waiting for server confirmation
  pending,

  /// Server confirmed the action was successful
  confirmed,

  /// Server rejected the action or request failed
  rejected,
}

/// Tracks the state of an optimistic action.
///
/// Use this to track individual optimistic updates and their confirmation status.
///
/// Example:
/// ```dart
/// final action = OptimisticAction<int>(
///   id: 'pick-123',
///   optimisticValue: playerId,
///   rollbackValue: null,
/// );
///
/// // When server confirms
/// action.confirm();
///
/// // When server rejects
/// action.reject('Player already drafted');
/// ```
class OptimisticAction<T> {
  /// Unique identifier for this action
  final String id;

  /// The optimistic value applied immediately
  final T optimisticValue;

  /// The value to restore on rollback
  final T rollbackValue;

  /// When the action was created
  final DateTime createdAt;

  /// Current status
  OptimisticActionStatus _status = OptimisticActionStatus.pending;
  OptimisticActionStatus get status => _status;

  /// Error message if rejected
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Callback when confirmed
  VoidCallback? onConfirmed;

  /// Callback when rejected
  void Function(String? error)? onRejected;

  OptimisticAction({
    required this.id,
    required this.optimisticValue,
    required this.rollbackValue,
    this.onConfirmed,
    this.onRejected,
  }) : createdAt = DateTime.now();

  /// Mark the action as confirmed.
  void confirm() {
    if (_status != OptimisticActionStatus.pending) return;
    _status = OptimisticActionStatus.confirmed;
    onConfirmed?.call();
  }

  /// Mark the action as rejected.
  void reject([String? error]) {
    if (_status != OptimisticActionStatus.pending) return;
    _status = OptimisticActionStatus.rejected;
    _errorMessage = error;
    onRejected?.call(error);
  }

  /// Whether this action is still pending confirmation.
  bool get isPending => _status == OptimisticActionStatus.pending;

  /// Whether this action was confirmed.
  bool get isConfirmed => _status == OptimisticActionStatus.confirmed;

  /// Whether this action was rejected.
  bool get isRejected => _status == OptimisticActionStatus.rejected;

  /// Whether this action should be rolled back.
  bool get shouldRollback => _status == OptimisticActionStatus.rejected;

  /// How long this action has been pending.
  Duration get pendingDuration => DateTime.now().difference(createdAt);

  @override
  String toString() =>
      'OptimisticAction($id, status: $_status, value: $optimisticValue)';
}

/// Manages a collection of optimistic actions.
///
/// Use this in your state notifier to track multiple pending actions.
///
/// Example:
/// ```dart
/// final tracker = OptimisticActionTracker<int>();
///
/// // Start optimistic update
/// tracker.track(OptimisticAction(
///   id: 'bid-456',
///   optimisticValue: newBid,
///   rollbackValue: currentBid,
/// ));
///
/// // When server responds
/// tracker.confirm('bid-456');
/// // or
/// tracker.reject('bid-456', 'Outbid by another user');
/// ```
class OptimisticActionTracker<T> {
  final Map<String, OptimisticAction<T>> _actions = {};

  /// All currently tracked actions.
  Iterable<OptimisticAction<T>> get actions => _actions.values;

  /// All pending actions.
  Iterable<OptimisticAction<T>> get pendingActions =>
      _actions.values.where((a) => a.isPending);

  /// Whether any actions are pending.
  bool get hasPendingActions => pendingActions.isNotEmpty;

  /// Track a new optimistic action.
  void track(OptimisticAction<T> action) {
    _actions[action.id] = action;
  }

  /// Get an action by ID.
  OptimisticAction<T>? get(String id) => _actions[id];

  /// Confirm an action by ID.
  ///
  /// Returns the rollback value if the action existed, null otherwise.
  T? confirm(String id) {
    final action = _actions[id];
    if (action == null) return null;
    action.confirm();
    _actions.remove(id);
    return action.rollbackValue;
  }

  /// Reject an action by ID.
  ///
  /// Returns the rollback value that should be restored.
  T? reject(String id, [String? error]) {
    final action = _actions[id];
    if (action == null) return null;
    action.reject(error);
    final rollback = action.rollbackValue;
    _actions.remove(id);
    return rollback;
  }

  /// Cancel an action without confirming or rejecting.
  void cancel(String id) {
    _actions.remove(id);
  }

  /// Clear all tracked actions.
  void clear() {
    _actions.clear();
  }

  /// Clean up stale pending actions older than the given duration.
  ///
  /// Returns the list of stale actions that were removed.
  List<OptimisticAction<T>> cleanupStale(Duration maxAge) {
    final now = DateTime.now();
    final stale = <OptimisticAction<T>>[];

    _actions.removeWhere((id, action) {
      if (action.isPending && now.difference(action.createdAt) > maxAge) {
        stale.add(action);
        return true;
      }
      return false;
    });

    return stale;
  }
}

/// Result of an optimistic action execution.
class OptimisticResult<T> {
  /// Whether the action succeeded.
  final bool success;

  /// The result value if successful.
  final T? value;

  /// Error message if failed.
  final String? error;

  /// Whether the state was rolled back.
  final bool rolledBack;

  const OptimisticResult._({
    required this.success,
    this.value,
    this.error,
    this.rolledBack = false,
  });

  factory OptimisticResult.success(T value) => OptimisticResult._(
        success: true,
        value: value,
      );

  factory OptimisticResult.failure(String error, {bool rolledBack = true}) =>
      OptimisticResult._(
        success: false,
        error: error,
        rolledBack: rolledBack,
      );

  factory OptimisticResult.cancelled() => const OptimisticResult._(
        success: false,
        error: 'Cancelled',
        rolledBack: true,
      );
}
