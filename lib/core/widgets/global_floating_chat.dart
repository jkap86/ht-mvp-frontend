import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/chat/presentation/floating_chat_widget.dart';

/// Global wrapper that renders the FloatingChatWidget on all screens.
/// Uses currentLeagueIdProvider to determine if in a league context.
class GlobalFloatingChat extends ConsumerWidget {
  const GlobalFloatingChat({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Don't show on auth screens (not authenticated)
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    // Watch the current league ID from route
    final leagueId = ref.watch(currentLeagueIdProvider);

    return FloatingChatWidget(leagueId: leagueId);
  }
}
