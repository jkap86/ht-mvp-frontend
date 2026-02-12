import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../leagues/domain/league.dart';
import '../mixins/countdown_mixin.dart';

/// Widget that displays a countdown to the next overnight pause window transition.
/// Shows either "Pause starts in X" or "Resumes in X" depending on current state.
class OvernightPauseCountdown extends StatefulWidget {
  final Draft draft;
  final bool isInOvernightPause;
  final int? serverClockOffsetMs;

  const OvernightPauseCountdown({
    super.key,
    required this.draft,
    required this.isInOvernightPause,
    this.serverClockOffsetMs,
  });

  @override
  State<OvernightPauseCountdown> createState() => _OvernightPauseCountdownState();
}

class _OvernightPauseCountdownState extends State<OvernightPauseCountdown>
    with CountdownMixin {
  DateTime? _nextTransitionTime;

  @override
  void initState() {
    super.initState();
    _calculateNextTransition();
    if (_nextTransitionTime != null) {
      startCountdown(
        _nextTransitionTime!,
        serverClockOffsetMs: widget.serverClockOffsetMs,
      );
    }
  }

  @override
  void didUpdateWidget(OvernightPauseCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if pause state changed or server offset updated
    if (oldWidget.isInOvernightPause != widget.isInOvernightPause ||
        oldWidget.serverClockOffsetMs != widget.serverClockOffsetMs ||
        oldWidget.draft.overnightPauseStart != widget.draft.overnightPauseStart ||
        oldWidget.draft.overnightPauseEnd != widget.draft.overnightPauseEnd) {
      stopCountdown();
      _calculateNextTransition();
      if (_nextTransitionTime != null) {
        startCountdown(
          _nextTransitionTime!,
          serverClockOffsetMs: widget.serverClockOffsetMs,
        );
      }
    }
  }

  /// Calculate the next transition time (start or end of pause window)
  void _calculateNextTransition() {
    if (!widget.draft.overnightPauseEnabled ||
        widget.draft.overnightPauseStart == null ||
        widget.draft.overnightPauseEnd == null) {
      _nextTransitionTime = null;
      return;
    }

    final now = getServerNow(serverClockOffsetMs: widget.serverClockOffsetMs).toUtc();
    final startParts = widget.draft.overnightPauseStart!.split(':');
    final endParts = widget.draft.overnightPauseEnd!.split(':');

    if (startParts.length != 2 || endParts.length != 2) {
      _nextTransitionTime = null;
      return;
    }

    final startHour = int.tryParse(startParts[0]);
    final startMinute = int.tryParse(startParts[1]);
    final endHour = int.tryParse(endParts[0]);
    final endMinute = int.tryParse(endParts[1]);

    if (startHour == null || startMinute == null || endHour == null || endMinute == null) {
      _nextTransitionTime = null;
      return;
    }

    // Calculate next transition based on current pause state
    if (widget.isInOvernightPause) {
      // Currently paused, next transition is pause end
      _nextTransitionTime = _getNextOccurrence(now, endHour, endMinute);
    } else {
      // Not paused, next transition is pause start
      _nextTransitionTime = _getNextOccurrence(now, startHour, startMinute);
    }
  }

  /// Get the next occurrence of a specific time (HH:MM)
  /// If the time has already passed today, returns tomorrow's occurrence
  DateTime _getNextOccurrence(DateTime now, int hour, int minute) {
    var next = DateTime.utc(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  String _formatCountdown() {
    if (timeRemaining.inDays > 0) {
      final hours = timeRemaining.inHours.remainder(24);
      return '${timeRemaining.inDays}d ${hours}h';
    }
    if (timeRemaining.inHours > 0) {
      final minutes = timeRemaining.inMinutes.remainder(60);
      return '${timeRemaining.inHours}h ${minutes}m';
    }
    if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}m';
    }
    return 'soon';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_nextTransitionTime == null || timeRemaining == Duration.zero) {
      return const SizedBox.shrink();
    }

    final isPaused = widget.isInOvernightPause;
    final label = isPaused ? 'Resumes in' : 'Pause in';
    final icon = isPaused ? Icons.play_circle_outline : Icons.pause_circle_outline;
    final color = isPaused ? AppTheme.draftWarning : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPaused
            ? AppTheme.draftWarning.withAlpha(26)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: AppSpacing.badgeRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _formatCountdown(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
