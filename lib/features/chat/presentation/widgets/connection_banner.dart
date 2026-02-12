import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/connection_state_provider.dart';
import '../../../../core/socket/socket_service.dart';

/// A banner that shows connection status when the socket is disconnected.
/// Shows "Tap to retry" when disconnected, a spinner when reconnecting,
/// and automatically hides when connected.
///
/// Designed to sit at the top of chat/DM message views.
class ConnectionBanner extends ConsumerStatefulWidget {
  const ConnectionBanner({super.key});

  @override
  ConsumerState<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends ConsumerState<ConnectionBanner> {
  bool _isRetrying = false;

  Future<void> _onTapRetry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    final socketService = ref.read(socketServiceProvider);
    await socketService.reconnect();

    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isSocketConnectedProvider);

    if (isConnected) {
      // Reset retry state when connection is restored
      if (_isRetrying) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isRetrying = false);
        });
      }
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _isRetrying ? null : _onTapRetry,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: colorScheme.errorContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRetrying) ...[
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
                'Reconnecting...',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ] else ...[
              Icon(
                Icons.wifi_off,
                size: 14,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Connection lost',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                '\u2013 Tap to retry',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: colorScheme.onErrorContainer,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
