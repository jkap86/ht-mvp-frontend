import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/chat/presentation/floating_chat_widget.dart';

/// Global wrapper that renders the FloatingChatWidget on all screens.
/// Extracts leagueId from the current route when in a league context.
class GlobalFloatingChat extends ConsumerWidget {
  const GlobalFloatingChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Don't show on auth screens (not authenticated)
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    // Extract leagueId from current route
    final leagueId = _extractLeagueIdFromRoute(context);

    return FloatingChatWidget(leagueId: leagueId);
  }

  /// Extract leagueId from the current route path.
  /// Returns null if not in a league context.
  int? _extractLeagueIdFromRoute(BuildContext context) {
    try {
      final router = GoRouter.of(context);
      final location = router.routerDelegate.currentConfiguration.uri.path;

      // Match /leagues/:leagueId pattern
      final match = RegExp(r'/leagues/(\d+)').firstMatch(location);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '');
      }
    } catch (e) {
      // GoRouter not available or other error
    }
    return null;
  }
}
