import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../players/domain/player.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../mixins/countdown_mixin.dart';
import 'shared/bid_amount_display.dart';
import '../../../../core/widgets/position_badge.dart';

/// Card widget showing the active lot in fast auction mode.
/// Displays countdown timer, player info, current bid, and bid button.
class FastAuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player? player;
  final String? leadingBidderName;
  final AuctionBudget? myBudget;
  final VoidCallback onBidTap;
  /// Server clock offset in milliseconds for accurate countdown
  final int? serverClockOffsetMs;

  const FastAuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.myBudget,
    required this.onBidTap,
    this.serverClockOffsetMs,
  });

  @override
  State<FastAuctionLotCard> createState() => _FastAuctionLotCardState();
}

class _FastAuctionLotCardState extends State<FastAuctionLotCard>
    with SingleTickerProviderStateMixin, CountdownMixin {
  bool get _isWinning =>
      widget.myBudget?.rosterId != null &&
      widget.lot.currentBidderRosterId == widget.myBudget!.rosterId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    startCountdown(widget.lot.bidDeadline, serverClockOffsetMs: widget.serverClockOffsetMs);
  }

  @override
  void didUpdateWidget(FastAuctionLotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update server clock offset if changed
    if (oldWidget.serverClockOffsetMs != widget.serverClockOffsetMs) {
      updateServerClockOffset(widget.serverClockOffsetMs);
    }
    if (oldWidget.lot.bidDeadline != widget.lot.bidDeadline) {
      updateTimeRemaining(widget.lot.bidDeadline, serverClockOffsetMs: widget.serverClockOffsetMs);
    }
    _updatePulseAnimation();
  }

  void _updatePulseAnimation() {
    // Start pulse animation when under 5 seconds
    final isCritical = timeRemaining.inSeconds > 0 && timeRemaining.inSeconds <= 5;
    if (isCritical && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isCritical && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final player = widget.player;
    final playerName = player?.fullName ?? 'Unknown Player';
    final position = player?.primaryPosition ?? '';
    final team = player?.team ?? '';

    final isExpired = timeRemaining == Duration.zero;
    final isUrgent = timeRemaining.inSeconds < 10 && !isExpired;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _isWinning
              ? const BorderSide(color: AppTheme.draftSuccess, width: 2)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Timer - prominent at top
              _buildTimerDisplay(theme, isExpired, isUrgent),
              const SizedBox(height: 16),

              // Player info row
              _buildPlayerInfoRow(theme, playerName, position, team),
              const SizedBox(height: 16),

              // Bid button
              _buildBidButton(theme, isExpired),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(ThemeData theme, bool isExpired, bool isUrgent) {
    final isCritical = timeRemaining.inSeconds > 0 && timeRemaining.inSeconds <= 5;

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
      timerColor = AppTheme.draftNormal;
      backgroundColor = AppTheme.draftNormal.withAlpha(30);
    }

    final timerWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: timerColor.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.hourglass_empty : Icons.timer,
            size: 28,
            color: timerColor,
          ),
          const SizedBox(width: 12),
          Text(
            isExpired ? 'SETTLING...' : formatFastCountdown(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1,
              color: timerColor,
            ),
          ),
        ],
      ),
    );

    // Apply pulse animation when under 5 seconds
    if (isCritical) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: timerWidget,
      );
    }

    return timerWidget;
  }

  Widget _buildPlayerInfoRow(ThemeData theme, String playerName, String position, String team) {
    return Row(
      children: [
        // Position badge
        PositionBadge(position: position, size: 48),
        const SizedBox(width: 12),

        // Player details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playerName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                team,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Current bid
        LargeBidAmountDisplay(
          amount: widget.lot.currentBid,
          leadingBidderName: widget.leadingBidderName,
          isWinning: _isWinning,
        ),
      ],
    );
  }

  Widget _buildBidButton(ThemeData theme, bool isExpired) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isExpired ? null : widget.onBidTap,
        icon: const Icon(Icons.gavel),
        label: const Text(
          'Place Bid',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
