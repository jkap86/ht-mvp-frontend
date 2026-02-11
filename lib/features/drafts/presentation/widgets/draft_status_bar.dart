import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/socket/connection_state_provider.dart';
import '../../../leagues/domain/league.dart';
import 'autodraft_toggle_widget.dart';
import 'draft_timer_widget.dart';

class DraftStatusBar extends ConsumerWidget {
  final Draft? draft;
  final String? currentPickerName;
  final bool isMyTurn;
  final bool? isAutodraftEnabled;
  final bool isAutodraftLoading;
  final VoidCallback? onToggleAutodraft;
  final String? topQueuedPlayerName;
  final VoidCallback? onDraftFromQueue;
  final VoidCallback? onPickPlayer;

  const DraftStatusBar({
    super.key,
    required this.draft,
    this.currentPickerName,
    this.isMyTurn = false,
    this.isAutodraftEnabled,
    this.isAutodraftLoading = false,
    this.onToggleAutodraft,
    this.topQueuedPlayerName,
    this.onDraftFromQueue,
    this.onPickPlayer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isInProgress = draft?.status.isActive ?? false;
    final isCompleted = draft?.status.isFinished ?? false;

    // Theme-aware background colors
    final Color backgroundColor;
    final Color iconColor;
    final Color textColor;

    if (isMyTurn) {
      backgroundColor = context.htColors.draftActionBg;
      iconColor = AppTheme.draftActionPrimary;
      textColor = context.htColors.draftAction;
    } else if (isInProgress) {
      backgroundColor = AppTheme.draftNormal.withAlpha(25);
      iconColor = AppTheme.draftNormal;
      textColor = context.htColors.draftNormal;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withAlpha(70);
      iconColor = theme.colorScheme.onSurfaceVariant;
      textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isMyTurn
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.draftActionPrimary,
                  width: 2,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          // Status icon and text
          Icon(
            isCompleted
                ? Icons.check_circle
                : isInProgress
                    ? (isMyTurn ? Icons.notifications_active : Icons.play_circle)
                    : Icons.hourglass_empty,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCompleted
                      ? 'Draft Complete'
                      : isInProgress
                          ? (isMyTurn ? 'Your Turn!' : 'Draft In Progress')
                          : 'Waiting to Start',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                if (isInProgress && currentPickerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      isMyTurn ? 'Make your pick' : 'Waiting for $currentPickerName',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // CTA button when it's user's turn
          if (isMyTurn && (onDraftFromQueue != null || onPickPlayer != null))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.draftActionPrimary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  topQueuedPlayerName != null
                      ? 'Draft: $topQueuedPlayerName'
                      : 'Pick Player',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: topQueuedPlayerName != null
                    ? onDraftFromQueue
                    : onPickPlayer,
              ),
            ),
          // Connection status indicator (LIVE/RECONNECTING)
          if (isInProgress) _buildConnectionIndicator(ref),
          // Timer first (more important, shows countdown)
          if (isInProgress && draft?.pickDeadline != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DraftTimerWidget(
                pickDeadline: draft!.pickDeadline,
              ),
            ),
          // Autodraft toggle
          if (isInProgress && isAutodraftEnabled != null)
            AutodraftToggleWidget(
              isEnabled: isAutodraftEnabled!,
              isLoading: isAutodraftLoading,
              onToggle: onToggleAutodraft,
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator(WidgetRef ref) {
    final connectionState = ref.watch(socketConnectionProvider);

    return connectionState.when(
      data: (state) {
        final isConnected = state == SocketConnectionState.connected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.draftActionPrimary.withAlpha(51)
                  : AppTheme.draftWarning.withAlpha(51),
              borderRadius: AppSpacing.badgeRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 12,
                  color: isConnected ? AppTheme.draftActionPrimary : AppTheme.draftWarning,
                ),
                const SizedBox(width: 4),
                Text(
                  isConnected ? 'LIVE' : 'RECONNECTING...',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConnected ? AppTheme.draftActionPrimary : AppTheme.draftWarning,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
