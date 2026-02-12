import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error_view.dart';
import 'app_loading_view.dart';

/// A widget that renders loading, error, or data states from a Riverpod
/// [AsyncValue].
///
/// Eliminates the repetitive `when(loading: ..., error: ..., data: ...)`
/// pattern and guarantees every async load ends in data **or** an actionable
/// error UI -- never "spinner forever".
///
/// Basic usage:
/// ```dart
/// final asyncTrades = ref.watch(tradesProvider);
/// AsyncValueWidget<List<Trade>>(
///   value: asyncTrades,
///   onRetry: () => ref.invalidate(tradesProvider),
///   data: (trades) => TradeList(trades: trades),
/// );
/// ```
///
/// With skeleton loading:
/// ```dart
/// AsyncValueWidget<List<Trade>>(
///   value: asyncTrades,
///   onRetry: () => ref.invalidate(tradesProvider),
///   loading: () => const SkeletonTradeList(),
///   data: (trades) => TradeList(trades: trades),
/// );
/// ```
class AsyncValueWidget<T> extends StatelessWidget {
  /// The [AsyncValue] to render.
  final AsyncValue<T> value;

  /// Builder for the data state.
  final Widget Function(T data) data;

  /// Retry callback wired to the error view's "Retry" button.
  final VoidCallback? onRetry;

  /// Optional custom loading widget builder. Defaults to [AppLoadingView].
  final Widget Function()? loading;

  /// Optional custom error widget builder. When provided, overrides the
  /// default [AppErrorView.fromError] rendering.
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  /// Optional loading message shown below the spinner.
  final String? loadingMessage;

  /// When true, if there is previous data available during a refresh/error
  /// the data builder is shown instead of the loading/error state.
  /// This prevents the UI from flashing to a loading spinner on pull-to-refresh.
  final bool skipLoadingOnRefresh;

  /// When true, if there is previous data available during an error state,
  /// the data builder is shown (the error can be surfaced via a snackbar
  /// elsewhere).
  final bool skipErrorWhenDataAvailable;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.error,
    this.loadingMessage,
    this.skipLoadingOnRefresh = true,
    this.skipErrorWhenDataAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      loading: () => loading?.call() ?? AppLoadingView(message: loadingMessage),
      error: (err, stack) {
        // If we have previous data and the flag is set, show it instead
        if (skipErrorWhenDataAvailable && value.hasValue && value.value != null) {
          return data(value.value as T);
        }
        return error?.call(err, stack) ??
            AppErrorView.fromError(
              error: err,
              onRetry: onRetry,
            );
      },
      data: data,
    );
  }
}

/// A sliver-compatible version of [AsyncValueWidget] for use inside
/// [CustomScrollView] or [NestedScrollView].
///
/// Example:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAsyncValueWidget<List<Trade>>(
///       value: asyncTrades,
///       onRetry: () => ref.invalidate(tradesProvider),
///       data: (trades) => SliverList(...),
///     ),
///   ],
/// );
/// ```
class SliverAsyncValueWidget<T> extends StatelessWidget {
  /// The [AsyncValue] to render.
  final AsyncValue<T> value;

  /// Builder for the data state. Must return a sliver widget.
  final Widget Function(T data) data;

  /// Retry callback wired to the error view's "Retry" button.
  final VoidCallback? onRetry;

  /// Optional custom loading sliver builder.
  final Widget Function()? loading;

  /// Optional custom error sliver builder.
  final Widget Function(Object error, StackTrace? stackTrace)? error;

  /// Optional loading message.
  final String? loadingMessage;

  /// See [AsyncValueWidget.skipLoadingOnRefresh].
  final bool skipLoadingOnRefresh;

  /// See [AsyncValueWidget.skipErrorWhenDataAvailable].
  final bool skipErrorWhenDataAvailable;

  const SliverAsyncValueWidget({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.error,
    this.loadingMessage,
    this.skipLoadingOnRefresh = true,
    this.skipErrorWhenDataAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: skipLoadingOnRefresh,
      loading: () =>
          loading?.call() ??
          SliverFillRemaining(
            hasScrollBody: false,
            child: AppLoadingView(message: loadingMessage),
          ),
      error: (err, stack) {
        if (skipErrorWhenDataAvailable && value.hasValue && value.value != null) {
          return data(value.value as T);
        }
        return error?.call(err, stack) ??
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppErrorView.fromError(
                error: err,
                onRetry: onRetry,
              ),
            );
      },
      data: data,
    );
  }
}
