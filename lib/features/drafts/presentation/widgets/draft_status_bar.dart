import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../leagues/domain/league.dart';
import 'autodraft_toggle_widget.dart';
import 'draft_timer_widget.dart';

class DraftStatusBar extends StatelessWidget {
  final Draft? draft;
  final String? currentPickerName;
  final bool isMyTurn;
  final bool? isAutodraftEnabled;
  final bool isAutodraftLoading;
  final VoidCallback? onToggleAutodraft;

  const DraftStatusBar({
    super.key,
    required this.draft,
    this.currentPickerName,
    this.isMyTurn = false,
    this.isAutodraftEnabled,
    this.isAutodraftLoading = false,
    this.onToggleAutodraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isInProgress = draft?.status.isActive ?? false;
    final isCompleted = draft?.status.isFinished ?? false;

    // Theme-aware background colors
    final Color backgroundColor;
    final Color iconColor;
    final Color textColor;

    if (isMyTurn) {
      backgroundColor = AppTheme.draftActionPrimary.withAlpha(isDark ? 40 : 30);
      iconColor = AppTheme.draftActionPrimary;
      textColor = isDark ? AppTheme.draftActionPrimary : const Color(0xFF1A7F37);
    } else if (isInProgress) {
      backgroundColor = AppTheme.draftNormal.withAlpha(isDark ? 30 : 20);
      iconColor = AppTheme.draftNormal;
      textColor = isDark ? AppTheme.draftNormal : const Color(0xFF0969DA);
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withAlpha(isDark ? 60 : 80);
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
}
