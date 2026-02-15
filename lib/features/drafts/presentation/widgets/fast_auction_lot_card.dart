import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../players/domain/player.dart';
import '../../domain/auction_bid_calculator.dart';
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
  final int? myRosterId;
  final AuctionBidCalculator calculator;
  /// Callback for quick-bid buttons. Returns error string or null on success.
  final Future<String?> Function(int maxBid)? onQuickBid;

  const FastAuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.myBudget,
    required this.onBidTap,
    required this.calculator,
    this.serverClockOffsetMs,
    this.myRosterId,
    this.onQuickBid,
  });

  @override
  State<FastAuctionLotCard> createState() => _FastAuctionLotCardState();
}

class _FastAuctionLotCardState extends State<FastAuctionLotCard>
    with SingleTickerProviderStateMixin, CountdownMixin {
  AuctionBidCalculator get _calc => widget.calculator;

  bool get _isWinning => _calc.isLeading(widget.lot, widget.myRosterId);

  int get _minBid => _calc.minBid(widget.lot, widget.myRosterId);

  int? _loadingQuickBidAmount;
  bool _hasTriggeredUrgentHaptic = false;
  bool _hasTriggeredCriticalHaptic = false;

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
      _hasTriggeredUrgentHaptic = false;
      _hasTriggeredCriticalHaptic = false;
    }
    _updatePulseAnimation();
  }

  void _updatePulseAnimation() {
    final seconds = timeRemaining.inSeconds;
    // Start pulse animation when under 5 seconds
    final isCritical = seconds > 0 && seconds <= 5;
    if (isCritical && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isCritical && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Haptic feedback at thresholds (fire once per deadline)
    if (seconds > 0 && seconds <= 10 && !_hasTriggeredUrgentHaptic) {
      _hasTriggeredUrgentHaptic = true;
      HapticFeedback.mediumImpact();
    }
    if (seconds > 0 && seconds <= 5 && !_hasTriggeredCriticalHaptic) {
      _hasTriggeredCriticalHaptic = true;
      HapticFeedback.heavyImpact();
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
              const SizedBox(height: 12),

              // Bid info: budget, min bid, leading indicator
              _buildBidInfoRow(theme),
              const SizedBox(height: 12),

              // Bid controls
              _buildBidControls(theme, isExpired),
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
      timerColor = context.htColors.draftNormal;
      backgroundColor = context.htColors.draftNormal.withAlpha(30);
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

        // Bid count + Current bid
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LargeBidAmountDisplay(
              amount: widget.lot.currentBid,
              leadingBidderName: widget.leadingBidderName,
              isWinning: _isWinning,
            ),
            if (widget.lot.bidCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer, size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.lot.bidCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  int? get _maxPossibleBid =>
      _calc.maxPossibleBid(widget.lot, widget.myBudget, widget.myRosterId);

  Widget _buildBidInfoRow(ThemeData theme) {
    final budget = widget.myBudget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Budget, min bid, and max bid chips
        Row(
          children: [
            if (budget != null)
              Expanded(
                child: _buildInfoChip(
                  theme,
                  icon: Icons.account_balance_wallet,
                  label: 'Budget: \$${budget.available}',
                ),
              ),
            if (budget != null) const SizedBox(width: 8),
            Expanded(
              child: _buildInfoChip(
                theme,
                icon: Icons.gavel,
                label: 'Min Bid: \$$_minBid',
              ),
            ),
          ],
        ),
        if (_maxPossibleBid != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _buildInfoChip(
              theme,
              icon: Icons.trending_up,
              label: 'Max possible bid: \$$_maxPossibleBid',
            ),
          ),
        // "You are leading" banner
        if (_isWinning)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.draftSuccess.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.draftSuccess.withAlpha(100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 16, color: AppTheme.draftSuccess),
                  const SizedBox(width: 6),
                  Text(
                    'You are leading',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.draftSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Your max bid
        if (widget.lot.myMaxBid != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Your Max: \$${widget.lot.myMaxBid}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip(ThemeData theme, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuickBid(int amount) async {
    if (widget.onQuickBid == null) return;
    setState(() => _loadingQuickBidAmount = amount);
    try {
      final error = await widget.onQuickBid!(amount);
      if (!mounted) return;
      if (error != null) {
        HapticFeedback.vibrate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _loadingQuickBidAmount = null);
    }
  }

  Widget _buildBidControls(ThemeData theme, bool isExpired) {
    if (isExpired || widget.onQuickBid == null) {
      // Fallback to simple bid button when expired or no quick-bid callback
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

    final min = _minBid;
    final max = _maxPossibleBid;
    final isLoading = _loadingQuickBidAmount != null;

    // Build quick-bid amounts: Min, +$5, +$10, Max
    final amounts = <({String label, int value})>[];
    amounts.add((label: 'Min \$$min', value: min));

    if (max != null && max > min) {
      final plus5 = widget.lot.currentBid + 5;
      final plus10 = widget.lot.currentBid + 10;
      // Only add +$5/+$10 if they're distinct from min and max
      if (plus5 > min && plus5 < max) {
        amounts.add((label: '+\$5', value: plus5));
      }
      if (plus10 > min && plus10 < max && plus10 != plus5) {
        amounts.add((label: '+\$10', value: plus10));
      }
      amounts.add((label: 'Max \$$max', value: max));
    }

    return Column(
      children: [
        // Quick-bid action chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: amounts.map((a) {
            final isThisLoading = _loadingQuickBidAmount == a.value;
            return ActionChip(
              label: isThisLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(a.label, style: const TextStyle(fontSize: 12)),
              onPressed: isLoading ? null : () => _handleQuickBid(a.value),
              backgroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide(color: theme.colorScheme.primary.withAlpha(80)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Custom Bid button (opens dialog)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : widget.onBidTap,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text(
              'Custom Bid',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
