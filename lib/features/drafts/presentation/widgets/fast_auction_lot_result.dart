import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../domain/lot_result.dart';

/// Banner widget showing the result of a completed auction lot.
/// Displays "You won [Player] for $X!" (green) or "[Team] won..." or "Passed".
class FastAuctionLotResult extends StatelessWidget {
  final LotResult result;
  final String? playerName;
  final String? winnerName;
  final bool isMyWin;
  final VoidCallback? onDismiss;

  const FastAuctionLotResult({
    super.key,
    required this.result,
    this.playerName,
    this.winnerName,
    this.isMyWin = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color backgroundColor;
    final Color textColor;
    final IconData icon;
    final String message;

    if (result.isPassed) {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurfaceVariant;
      icon = Icons.close;
      message = '${playerName ?? 'Player'} passed';
    } else if (isMyWin) {
      backgroundColor = AppTheme.draftSuccess.withAlpha(30);
      textColor = AppTheme.draftSuccess;
      icon = Icons.emoji_events;
      message = 'You won ${playerName ?? 'Player'} for \$${result.price ?? 0}!';
    } else {
      backgroundColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
      icon = Icons.emoji_events;
      message = '${winnerName ?? 'Team'} won ${playerName ?? 'Player'} for \$${result.price ?? 0}';
    }

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isMyWin
              ? Border.all(color: AppTheme.draftSuccess, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.close,
              size: 16,
              color: textColor.withAlpha(128),
            ),
          ],
        ),
      ),
    );
  }
}
