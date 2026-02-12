import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/socket/connection_state_provider.dart';
import '../../../leagues/domain/league.dart';
import 'autodraft_toggle_widget.dart';
import 'draft_timer_widget.dart';
import 'overnight_pause_countdown.dart';

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
  /// Server clock offset for accurate timer sync
  final int? serverClockOffsetMs;
  /// Message explaining the last autopick (shown after reconnect)
  final String? autopickExplanation;
  /// Callback to dismiss the autopick explanation
  final VoidCallback? onDismissAutopickExplanation;
  /// Number of picks the user has made so far
  final int myPickCount;
  /// Total roster slots (draft rounds)
  final int totalRosterSlots;
  /// Positions still needed (e.g., ['RB', 'TE', 'K'])
  final List<String> neededPositions;
  /// Whether draft is currently in overnight pause window
  final bool isInOvernightPause;

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
    this.serverClockOffsetMs,
    this.autopickExplanation,
    this.onDismissAutopickExplanation,
    this.myPickCount = 0,
    this.totalRosterSlots = 0,
    this.neededPositions = const [],
    this.isInOvernightPause = false,
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
      iconColor = context.htColors.draftAction;
      textColor = context.htColors.draftAction;
    } else if (isInProgress) {
      backgroundColor = context.htColors.draftNormal.withAlpha(25);
      iconColor = context.htColors.draftNormal;
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
                  color: context.htColors.draftAction,
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
                Semantics(
                  liveRegion: true,
                  label: isCompleted
                      ? 'Draft status: complete'
                      : isInProgress
                          ? (isMyTurn
                              ? 'Draft status: your turn to pick'
                              : 'Draft status: in progress, waiting for $currentPickerName')
                          : 'Draft status: waiting to start',
                  child: Text(
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
                ),
                if (isInProgress && currentPickerName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      isInOvernightPause
                          ? 'Draft paused: overnight pause window'
                          : (isMyTurn ? 'Make your pick' : 'Waiting for $currentPickerName'),
                      style: TextStyle(
                        fontSize: 13,
                        color: isInOvernightPause
                            ? AppTheme.draftWarning
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                // Autopick explanation after reconnect
                if (autopickExplanation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy, size: 14, color: AppTheme.draftWarning),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            autopickExplanation!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.draftWarning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (onDismissAutopickExplanation != null)
                          Semantics(
                            button: true,
                            label: 'Dismiss autopick explanation',
                            child: GestureDetector(
                              onTap: onDismissAutopickExplanation,
                              child: Icon(Icons.close, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                // Roster completion indicator
                if (isInProgress && totalRosterSlots > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _buildRosterCompletionText(),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          // CTA button when it's user's turn
          if (isMyTurn && (onDraftFromQueue != null || onPickPlayer != null))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Semantics(
                  button: true,
                  label: topQueuedPlayerName != null
                      ? 'Draft player $topQueuedPlayerName from queue'
                      : 'Pick a player from the player list',
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.htColors.draftAction,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Flexible(
                      child: Text(
                        topQueuedPlayerName != null
                            ? 'Draft: ${_truncateName(topQueuedPlayerName!)}'
                            : 'Pick Player',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    onPressed: topQueuedPlayerName != null
                        ? onDraftFromQueue
                        : onPickPlayer,
                  ),
                ),
              ),
            ),
          // Connection status indicator (LIVE/RECONNECTING)
          if (isInProgress) _buildConnectionIndicator(context, ref),
          // Overnight pause countdown (if enabled and active)
          if (isInProgress && draft != null && draft!.overnightPauseEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OvernightPauseCountdown(
                draft: draft!,
                isInOvernightPause: isInOvernightPause,
                serverClockOffsetMs: serverClockOffsetMs,
              ),
            ),
          // Timer (shows countdown to next pick, synced to server)
          if (isInProgress && draft?.pickDeadline != null && !isInOvernightPause)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                label: 'Pick timer countdown',
                child: DraftTimerWidget(
                  pickDeadline: draft!.pickDeadline,
                  serverClockOffsetMs: serverClockOffsetMs,
                ),
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

  /// Truncates a player name to fit the CTA button on narrow screens.
  /// Shows last name only if full name exceeds 15 characters.
  static String _truncateName(String name) {
    if (name.length <= 15) return name;
    final parts = name.trim().split(' ');
    if (parts.length > 1) return parts.last;
    return '${name.substring(0, 13)}...';
  }

  /// Builds the roster completion text like "8/15 picked  |  Need: RB, TE, K"
  String _buildRosterCompletionText() {
    final fillText = '$myPickCount/$totalRosterSlots picked';
    if (neededPositions.isEmpty) {
      return fillText;
    }
    final needText = 'Need: ${neededPositions.join(', ')}';
    return '$fillText  \u2022  $needText';
  }

  Widget _buildConnectionIndicator(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(socketConnectionProvider);
    final htColors = context.htColors;

    return connectionState.when(
      data: (state) {
        final isConnected = state == SocketConnectionState.connected;
        return Semantics(
          label: isConnected
              ? 'Connection status: live'
              : 'Connection status: reconnecting',
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected
                    ? htColors.draftAction.withAlpha(51)
                    : AppTheme.draftWarning.withAlpha(51),
                borderRadius: AppSpacing.badgeRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    size: 12,
                    color: isConnected ? htColors.draftAction : AppTheme.draftWarning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isConnected ? 'LIVE' : 'RECONNECTING...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? htColors.draftAction : AppTheme.draftWarning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
