import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/connection_state_provider.dart';

/// A banner that shows "Connection lost - reconnecting..." when the socket
/// is disconnected. Automatically hides when connected.
///
/// Designed to sit at the top of chat/DM message views.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isSocketConnectedProvider);

    if (isConnected) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colorScheme.errorContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Connection lost \u2013 reconnecting...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
          ),
        ],
      ),
    );
  }
}
