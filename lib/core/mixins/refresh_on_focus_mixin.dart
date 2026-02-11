import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A mixin that provides navigation-aware refresh functionality.
///
/// When a screen using this mixin comes back into focus (e.g., after
/// navigating back from another screen), it will check if the data
/// is stale and trigger a refresh if needed.
///
/// Usage:
/// ```dart
/// class MyScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MyScreen> createState() => _MyScreenState();
/// }
///
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with RefreshOnFocusMixin {
///   @override
///   Duration get staleThreshold => const Duration(seconds: 30);
///
///   @override
///   void refreshIfStale() {
///     ref.read(myProvider.notifier).loadData();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ...;
///   }
/// }
/// ```
mixin RefreshOnFocusMixin<T extends ConsumerStatefulWidget> on ConsumerState<T>
    implements RouteAware {
  DateTime? _lastRefresh;
  RouteObserver<ModalRoute<void>>? _routeObserver;

  /// The threshold after which data is considered stale.
  /// Override this to customize the threshold for your screen.
  Duration get staleThreshold => const Duration(seconds: 30);

  /// Override this method to implement the refresh logic.
  /// This will be called when the screen is navigated back to
  /// and the data is older than [staleThreshold].
  void refreshIfStale();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route != null) {
      // Try to find a RouteObserver in the widget tree
      final navigator = Navigator.maybeOf(context);
      if (navigator != null) {
        try {
          final observer = navigator.widget.observers
              .whereType<RouteObserver<ModalRoute<void>>>()
              .firstOrNull;
          if (observer != null && _routeObserver != observer) {
            _routeObserver?.unsubscribe(this);
            _routeObserver = observer;
            observer.subscribe(this, route);
          }
        } catch (_) {
          // RouteObserver not available, fall back to didChangeDependencies behavior
          _checkAndRefresh();
        }
      }
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  /// Called when this route is pushed onto the navigator.
  @override
  void didPush() {
    _lastRefresh = DateTime.now();
  }

  /// Called when a route has been popped off and this route is now visible.
  @override
  void didPopNext() {
    _checkAndRefresh();
  }

  /// Called when this route has been pushed and is now the topmost route.
  @override
  void didPushNext() {
    // Another route was pushed on top of this one
  }

  /// Called when this route has been popped off the navigator.
  @override
  void didPop() {
    // This route was popped
  }

  /// Check if data is stale and refresh if needed.
  void _checkAndRefresh() {
    final now = DateTime.now();
    if (_lastRefresh == null ||
        now.difference(_lastRefresh!) > staleThreshold) {
      refreshIfStale();
      _lastRefresh = now;
    }
  }

  /// Force a refresh and update the last refresh timestamp.
  void forceRefresh() {
    refreshIfStale();
    _lastRefresh = DateTime.now();
  }

  /// Mark the data as freshly loaded without triggering a refresh.
  void markAsFresh() {
    _lastRefresh = DateTime.now();
  }
}

/// A simple route observer that can be used with [RefreshOnFocusMixin].
///
/// Add this to your MaterialApp.router or GoRouter to enable
/// navigation-aware refresh.
class RefreshRouteObserver extends RouteObserver<ModalRoute<void>> {
  // The base RouteObserver class handles all the subscription management
}

/// Provider for the refresh route observer.
/// Use this with your app's router configuration.
final refreshRouteObserverProvider = Provider<RefreshRouteObserver>((ref) {
  return RefreshRouteObserver();
});
