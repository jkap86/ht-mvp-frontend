import 'dart:async';
import 'package:flutter/material.dart';

import 'app_error_view.dart';
import 'app_loading_view.dart';

/// A widget that wraps a loading state and transitions to an error UI
/// after a configurable timeout.
///
/// This is the "no spinner forever" safety net. Wrap any loading widget
/// (or use it with [AsyncStateWidget]) to guarantee the user always sees
/// an actionable outcome.
///
/// Usage:
/// ```dart
/// if (state.isLoading) {
///   return LoadingTimeoutWrapper(
///     timeout: const Duration(seconds: 30),
///     onTimeout: () => ref.read(provider.notifier).loadData(),
///     child: const SkeletonTradeList(),
///   );
/// }
/// ```
///
/// Or as a standalone guard around your loading widget:
/// ```dart
/// LoadingTimeoutWrapper(
///   isLoading: state.isLoading,
///   timeout: const Duration(seconds: 30),
///   onTimeout: () => ref.read(provider.notifier).loadData(),
///   loadingChild: const AppLoadingView(message: 'Loading trades...'),
///   child: TradeList(trades: state.trades),
/// );
/// ```
class LoadingTimeoutWrapper extends StatefulWidget {
  /// Whether the loading state is active. When true, shows [loadingChild]
  /// (or [child] if [loadingChild] is null). When false, shows [child].
  ///
  /// If not provided, the widget always shows either the loading or
  /// timed-out state (useful when this widget IS the loading branch of
  /// your conditional).
  final bool? isLoading;

  /// The widget to show in the loaded/data state.
  final Widget child;

  /// Optional custom loading widget. Defaults to [AppLoadingView].
  final Widget? loadingChild;

  /// How long to wait before showing the timeout error. Defaults to 30s.
  final Duration timeout;

  /// Called when the user presses "Retry" after a timeout.
  final VoidCallback? onTimeout;

  /// Custom message to show on timeout.
  final String timeoutMessage;

  const LoadingTimeoutWrapper({
    super.key,
    this.isLoading,
    required this.child,
    this.loadingChild,
    this.timeout = const Duration(seconds: 30),
    this.onTimeout,
    this.timeoutMessage = 'This is taking longer than expected. Please try again.',
  });

  @override
  State<LoadingTimeoutWrapper> createState() => _LoadingTimeoutWrapperState();
}

class _LoadingTimeoutWrapperState extends State<LoadingTimeoutWrapper> {
  Timer? _timer;
  bool _timedOut = false;

  bool get _isActivelyLoading => widget.isLoading ?? true;

  @override
  void initState() {
    super.initState();
    if (_isActivelyLoading) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(LoadingTimeoutWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasLoading = oldWidget.isLoading ?? true;
    final nowLoading = _isActivelyLoading;

    if (nowLoading && !wasLoading) {
      // Started loading again
      _timedOut = false;
      _startTimer();
    } else if (!nowLoading && wasLoading) {
      // Stopped loading
      _cancelTimer();
      if (_timedOut) {
        setState(() => _timedOut = false);
      }
    }
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer(widget.timeout, () {
      if (mounted && _isActivelyLoading) {
        setState(() => _timedOut = true);
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Not loading -- show the data widget
    if (!_isActivelyLoading) {
      return widget.child;
    }

    // Loading has timed out -- show actionable error
    if (_timedOut) {
      return AppErrorView(
        message: widget.timeoutMessage,
        icon: Icons.timer_off_rounded,
        onRetry: widget.onTimeout != null
            ? () {
                setState(() => _timedOut = false);
                _startTimer();
                widget.onTimeout!();
              }
            : null,
      );
    }

    // Still loading within the timeout window
    return widget.loadingChild ?? const AppLoadingView();
  }
}
