import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';

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

class _FastAuctionWaitingStateState extends State<FastAuctionWaitingState> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(FastAuctionWaitingState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nominationDeadline != widget.nominationDeadline) {
      _updateRemaining();
    }
  }

  /// Get the current time adjusted for server clock offset.
  DateTime _getServerNow() {
    if (widget.serverClockOffsetMs == null) return DateTime.now();
    return DateTime.now().add(Duration(milliseconds: widget.serverClockOffsetMs!));
  }

  void _updateRemaining() {
    if (widget.nominationDeadline == null) {
      setState(() {
        _remaining = Duration.zero;
      });
      return;
    }
    // Use UTC for both to ensure correct countdown regardless of user's timezone
    // Apply server clock offset for accurate countdown on devices with clock drift
    final now = _getServerNow().toUtc();
    final deadline = widget.nominationDeadline!.toUtc();
    setState(() {
      _remaining = deadline.difference(now);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}:${(d.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
    } else {
      return '0:${d.inSeconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDeadline = widget.nominationDeadline != null;
    final isExpired = _remaining == Duration.zero && hasDeadline;
    final isUrgent = _remaining.inSeconds < 10 && !isExpired && hasDeadline;

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
            color: Colors.deepPurple[300],
          ),
          const SizedBox(height: 8),
          Text(
            widget.isMyNomination
                ? 'Select a player to nominate'
                : 'Waiting for nomination...',
            style: TextStyle(
              color: Colors.deepPurple[400],
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
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
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
    final isDark = theme.brightness == Brightness.dark;

    final Color timerColor;
    final Color backgroundColor;

    if (isExpired) {
      timerColor = const Color(0xFF6E7681);
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
    } else if (isUrgent) {
      timerColor = AppTheme.draftUrgent;
      backgroundColor = AppTheme.draftUrgent.withAlpha(isDark ? 40 : 25);
    } else if (_remaining.inSeconds <= 30) {
      timerColor = AppTheme.draftWarning;
      backgroundColor = AppTheme.draftWarning.withAlpha(isDark ? 40 : 25);
    } else {
      timerColor = AppTheme.draftNormal;
      backgroundColor = AppTheme.draftNormal.withAlpha(isDark ? 40 : 25);
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
            isExpired ? 'AUTO-NOMINATING...' : _formatDuration(_remaining),
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
