import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../socket/connection_state_provider.dart';
import '../socket/socket_service.dart';

/// A banner that displays socket connection status to the user.
/// Shows "Connection lost" when disconnected with a "Tap to retry" action,
/// and auto-dismisses on reconnect.
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

class _ConnectionBannerContent extends ConsumerStatefulWidget {
  final SocketConnectionState state;

  const _ConnectionBannerContent({required this.state});

  @override
  ConsumerState<_ConnectionBannerContent> createState() =>
      _ConnectionBannerContentState();
}

class _ConnectionBannerContentState
    extends ConsumerState<_ConnectionBannerContent> {
  bool _isRetrying = false;

  Future<void> _onTapRetry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);

    final socketService = ref.read(socketServiceProvider);
    await socketService.reconnect();

    // Reset retrying state after a short delay to allow the connection
    // state stream to update. If still mounted, the provider state will
    // determine what is shown next.
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReconnecting =
        widget.state == SocketConnectionState.reconnecting || _isRetrying;
    final bannerBg = AppTheme.draftWarning.withAlpha(35);
    final bannerFg = AppTheme.draftWarning;

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: isReconnecting ? null : _onTapRetry,
        child: Material(
          elevation: 2,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(bannerFg),
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
                  isReconnecting
                      ? 'Reconnecting...'
                      : 'Connection lost',
                  style: TextStyle(
                    color: bannerFg,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (!isReconnecting) ...[
                  const SizedBox(width: 8),
                  Text(
                    '\u2013 Tap to retry',
                    style: TextStyle(
                      color: bannerFg,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: bannerFg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
