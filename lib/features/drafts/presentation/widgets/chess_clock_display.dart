import 'package:flutter/material.dart';

/// Displays a chess clock remaining time badge for a single roster.
/// Color-coded based on remaining budget percentage.
class ChessClockBadge extends StatelessWidget {
  final double remainingSeconds;
  final double totalSeconds;

  const ChessClockBadge({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = totalSeconds > 0 ? remainingSeconds / totalSeconds : 0.0;
    final color = _colorForPercentage(percentage, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80), width: 0.5),
      ),
      child: Text(
        _formatTime(remainingSeconds),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Color _colorForPercentage(double percentage, ThemeData theme) {
    if (percentage <= 0) return Colors.grey;
    if (percentage < 0.25) return theme.colorScheme.error;
    if (percentage < 0.50) return Colors.orange;
    return Colors.green;
  }

  String _formatTime(double seconds) {
    final totalSec = seconds.round();
    if (totalSec <= 0) return '0:00';
    final minutes = totalSec ~/ 60;
    final secs = totalSec % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
