import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../players/domain/player.dart';
import '../../domain/auction_lot.dart';
import '../utils/position_colors.dart';

/// Card widget showing the active lot in fast auction mode.
/// Displays countdown timer, player info, current bid, and bid button.
class FastAuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player? player;
  final String? leadingBidderName;
  final dynamic myBudget;
  final VoidCallback onBidTap;

  const FastAuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.myBudget,
    required this.onBidTap,
  });

  @override
  State<FastAuctionLotCard> createState() => _FastAuctionLotCardState();
}

class _FastAuctionLotCardState extends State<FastAuctionLotCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _remaining = Duration.zero;
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
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(FastAuctionLotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lot.bidDeadline != widget.lot.bidDeadline) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    // Use UTC for both to ensure correct countdown regardless of user's timezone
    final now = DateTime.now().toUtc();
    final deadline = widget.lot.bidDeadline.toUtc();
    setState(() {
      _remaining = deadline.difference(now);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });

    // Start pulse animation when under 5 seconds
    final isCritical = _remaining.inSeconds > 0 && _remaining.inSeconds <= 5;
    if (isCritical && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isCritical && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
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
    final player = widget.player;
    final playerName = player?.fullName ?? 'Unknown Player';
    final position = player?.primaryPosition ?? '';
    final team = player?.team ?? '';

    final isExpired = _remaining == Duration.zero;
    final isUrgent = _remaining.inSeconds < 10 && !isExpired;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
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
    final isDark = theme.brightness == Brightness.dark;
    final isCritical = _remaining.inSeconds > 0 && _remaining.inSeconds <= 5;

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

    final timerWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
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
            isExpired ? 'SETTLING...' : _formatDuration(_remaining),
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
    final positionColor = getPositionColor(position);

    return Row(
      children: [
        // Position badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: positionColor.withAlpha(40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: positionColor.withAlpha(100), width: 1.5),
          ),
          child: Center(
            child: Text(
              position,
              style: TextStyle(
                color: positionColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${widget.lot.currentBid}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppTheme.draftActionPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.leadingBidderName ?? 'No bids',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
