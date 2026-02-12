import 'package:flutter/material.dart';

import 'app_error_view.dart';
import 'app_loading_view.dart';

/// A builder widget for StateNotifier-style states that have discrete
/// `isLoading`, `error`, and data fields.
///
/// This addresses the pattern used throughout the codebase where providers
/// expose a state object with `isLoading` (bool), `error` (String?), and
/// the actual data. It ensures every async load ends in data **or** an
/// actionable error UI.
///
/// Basic usage:
/// ```dart
/// final state = ref.watch(tradesProvider(leagueId));
/// AsyncStateWidget<TradesState>(
///   state: state,
///   isLoading: state.isLoading,
///   errorMessage: state.error,
///   onRetry: () => ref.read(tradesProvider(leagueId).notifier).loadTrades(),
///   data: (state) => TradeList(trades: state.filteredTrades),
/// );
/// ```
///
/// With skeleton loading:
/// ```dart
/// AsyncStateWidget<TradesState>(
///   state: state,
///   isLoading: state.isLoading,
///   errorMessage: state.error,
///   onRetry: () => ref.read(tradesProvider(leagueId).notifier).loadTrades(),
///   loading: () => const SkeletonTradeList(),
///   data: (state) => TradeList(trades: state.filteredTrades),
/// );
/// ```
class AsyncStateWidget<T> extends StatelessWidget {
  /// The state object.
  final T state;

  /// Whether the state is currently loading.
  final bool isLoading;

  /// A user-facing error message, or null if there is no error.
  final String? errorMessage;

  /// The raw error object (for [AppErrorView.fromError] icon/action mapping).
  /// When provided, takes precedence over [errorMessage] for UI rendering.
  final Object? errorObject;

  /// Builder for the data/loaded state.
  final Widget Function(T state) data;

  /// Retry callback wired to the error view's "Retry" button.
  final VoidCallback? onRetry;

  /// Optional secondary action for the error view.
  final VoidCallback? onSecondaryAction;

  /// Optional label for the secondary action button.
  final String? secondaryActionText;

  /// Optional custom loading widget builder.
  final Widget Function()? loading;

  /// Optional custom error widget builder.
  final Widget Function(String errorMessage)? error;

  /// Optional loading message.
  final String? loadingMessage;

  /// When true, shows the data builder even during a refresh (isLoading is
  /// true but we have existing data). This avoids the jarring flash to a
  /// loading spinner on pull-to-refresh.
  final bool showDataWhileRefreshing;

  /// Predicate to determine whether the state has data.
  /// Defaults to always true (assumes data is present on the state object).
  /// Override to check e.g. `(s) => s.trades.isNotEmpty`.
  final bool Function(T state)? hasData;

  const AsyncStateWidget({
    super.key,
    required this.state,
    required this.isLoading,
    required this.data,
    this.errorMessage,
    this.errorObject,
    this.onRetry,
    this.onSecondaryAction,
    this.secondaryActionText,
    this.loading,
    this.error,
    this.loadingMessage,
    this.showDataWhileRefreshing = true,
    this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final dataAvailable = hasData?.call(state) ?? true;

    // If loading but we already have data and flag is set, show data
    if (isLoading && showDataWhileRefreshing && dataAvailable && errorMessage == null) {
      // Check if this is a refresh vs. initial load.
      // Initial load: hasData returns false or data is "empty".
      // We only skip loading for refreshes when there's real data.
      return data(state);
    }

    // Loading state
    if (isLoading) {
      return loading?.call() ?? AppLoadingView(message: loadingMessage);
    }

    // Error state
    if (errorMessage != null || errorObject != null) {
      if (error != null && errorMessage != null) {
        return error!(errorMessage!);
      }
      if (errorObject != null) {
        return AppErrorView.fromError(
          error: errorObject!,
          onRetry: onRetry,
          onSecondaryAction: onSecondaryAction,
          secondaryActionText: secondaryActionText,
        );
      }
      return AppErrorView(
        message: errorMessage!,
        onRetry: onRetry,
        onSecondaryAction: onSecondaryAction,
        secondaryActionText: secondaryActionText,
      );
    }

    // Data state
    return data(state);
  }
}
