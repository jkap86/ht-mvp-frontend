import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../mixins/countdown_mixin.dart';

/// Widget shown when waiting for nomination in fast auction mode.
/// Displays countdown timer until auto-nomination and nominate button.
class FastAuctionWaitingState extends StatefulWidget {
  final bool isMyNomination;
  final VoidCallback onNominateTap;
  final DateTime? nominationDeadline;
  /// Server clock offset in milliseconds for accurate countdown
  final int? serverClockOffsetMs;

  const FastAuctionWaitingState({
    super.key,
    required this.isMyNomination,
    required this.onNominateTap,
    this.nominationDeadline,
    this.serverClockOffsetMs,
  });

  @override
  State<FastAuctionWaitingState> createState() => _FastAuctionWaitingStateState();
}

class _FastAuctionWaitingStateState extends State<FastAuctionWaitingState>
    with CountdownMixin {
  bool _hasTriggeredNominationHaptic = false;

  @override
  void initState() {
    super.initState();
    if (widget.nominationDeadline != null) {
      startCountdown(
        widget.nominationDeadline!,
        serverClockOffsetMs: widget.serverClockOffsetMs,
      );
    }
  }

  @override
  void didUpdateWidget(FastAuctionWaitingState oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update server clock offset if changed
    if (oldWidget.serverClockOffsetMs != widget.serverClockOffsetMs) {
      updateServerClockOffset(widget.serverClockOffsetMs);
    }

    // Handle deadline changes
    if (oldWidget.nominationDeadline != widget.nominationDeadline) {
      if (widget.nominationDeadline != null) {
        // Start or update countdown
        stopCountdown();
        startCountdown(
          widget.nominationDeadline!,
          serverClockOffsetMs: widget.serverClockOffsetMs,
        );
      } else {
        // No deadline - stop countdown
        stopCountdown();
        setState(() {
          timeRemaining = Duration.zero;
        });
      }
    }

    // Haptic when it becomes my nomination turn
    if (!oldWidget.isMyNomination && widget.isMyNomination && !_hasTriggeredNominationHaptic) {
      _hasTriggeredNominationHaptic = true;
      HapticFeedback.lightImpact();
    }
    if (oldWidget.isMyNomination && !widget.isMyNomination) {
      _hasTriggeredNominationHaptic = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDeadline = widget.nominationDeadline != null;
    final isExpired = timeRemaining == Duration.zero && hasDeadline;
    final isUrgent = timeRemaining.inSeconds < 10 && !isExpired && hasDeadline;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Timer display (only if we have a deadline)
          if (hasDeadline) ...[
            _buildTimerDisplay(theme, isExpired, isUrgent),
            const SizedBox(height: 12),
          ],

          // Icon and message
          Icon(
            widget.isMyNomination ? Icons.person_add : Icons.hourglass_empty,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isMyNomination
                ? 'Select a player to nominate'
                : 'Waiting for nomination...',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 14,
            ),
          ),

          // Nominate button (only shown for current nominator)
          if (widget.isMyNomination) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isExpired ? null : widget.onNominateTap,
              icon: const Icon(Icons.add),
              label: const Text('Nominate Player'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(ThemeData theme, bool isExpired, bool isUrgent) {
    final Color timerColor;
    final Color backgroundColor;

    if (isExpired) {
      timerColor = context.htColors.textMuted;
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
    } else if (isUrgent) {
      timerColor = AppTheme.draftUrgent;
      backgroundColor = AppTheme.draftUrgent.withAlpha(30);
    } else if (timeRemaining.inSeconds <= 30) {
      timerColor = AppTheme.draftWarning;
      backgroundColor = AppTheme.draftWarning.withAlpha(30);
    } else {
      timerColor = context.htColors.draftNormal;
      backgroundColor = context.htColors.draftNormal.withAlpha(30);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: timerColor.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.hourglass_empty : Icons.timer,
            size: 20,
            color: timerColor,
          ),
          const SizedBox(width: 8),
          Text(
            isExpired ? 'AUTO-NOMINATING...' : formatFastCountdown(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
              color: timerColor,
            ),
          ),
        ],
      ),
    );
  }
}
