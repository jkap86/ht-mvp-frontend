import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../socket/connection_state_provider.dart';

/// A banner that displays socket connection status to the user.
/// Shows "Connection lost" when disconnected and auto-dismisses on reconnect.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(socketConnectionProvider);

    return connectionState.when(
      data: (state) {
        if (state == SocketConnectionState.connected) {
          return const SizedBox.shrink();
        }

        return _ConnectionBannerContent(
          state: state,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _ConnectionBannerContent(
        state: SocketConnectionState.disconnected,
      ),
    );
  }
}

class _ConnectionBannerContent extends StatelessWidget {
  final SocketConnectionState state;

  const _ConnectionBannerContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReconnecting = state == SocketConnectionState.reconnecting;
    final bannerBg = isDark
        ? AppTheme.draftWarning.withAlpha(40)
        : AppTheme.draftWarning.withAlpha(30);
    final bannerFg = isDark
        ? AppTheme.draftWarning
        : AppTheme.draftWarning;

    return SafeArea(
      bottom: false,
      child: Material(
        elevation: 2,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bannerBg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isReconnecting)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(bannerFg),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.wifi_off,
                    size: 18,
                    color: bannerFg,
                  ),
                ),
              Text(
                isReconnecting ? 'Reconnecting...' : 'Connection lost',
                style: TextStyle(
                  color: bannerFg,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
