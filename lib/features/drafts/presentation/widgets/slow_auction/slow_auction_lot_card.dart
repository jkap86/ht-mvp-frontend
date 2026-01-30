import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../players/domain/player.dart';
import '../../../domain/auction_lot.dart';

/// Individual auction card for the slow auction list view.
class SlowAuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player player;
  final String highBidderName;
  final bool isWinning;
  final VoidCallback onTap;

  const SlowAuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.highBidderName,
    required this.isWinning,
    required this.onTap,
  });

  @override
  State<SlowAuctionLotCard> createState() => _SlowAuctionLotCardState();
}

class _SlowAuctionLotCardState extends State<SlowAuctionLotCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final remaining = widget.lot.bidDeadline.difference(now);
    if (mounted) {
      setState(() {
        _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  @override
  void didUpdateWidget(SlowAuctionLotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lot.bidDeadline != widget.lot.bidDeadline) {
      _updateTimeRemaining();
    }
  }

  String _formatTimeRemaining() {
    if (_timeRemaining == Duration.zero) return 'Ended';
    if (_timeRemaining.inDays > 0) {
      return '${_timeRemaining.inDays}d ${_timeRemaining.inHours.remainder(24)}h';
    }
    if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h ${_timeRemaining.inMinutes.remainder(60)}m';
    }
    return '${_timeRemaining.inMinutes}m';
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEndingSoon = _timeRemaining.inHours < 2;
    final isExpired = _timeRemaining == Duration.zero;

    return Card(
      margin: EdgeInsets.zero,
      color: widget.isWinning
          ? theme.colorScheme.primaryContainer.withAlpha(50)
          : isEndingSoon
              ? theme.colorScheme.errorContainer.withAlpha(30)
              : null,
      child: InkWell(
        onTap: isExpired ? null : widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPositionColor(widget.player.primaryPosition),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.player.primaryPosition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.fullName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.player.team ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'High: ${widget.highBidderName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: widget.isWinning
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight:
                                widget.isWinning ? FontWeight.bold : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bid and time info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Current bid
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isWinning
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\$${widget.lot.currentBid}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.isWinning
                            ? theme.colorScheme.onPrimary
                            : null,
                      ),
                    ),
                  ),
                  // User's max bid (if they've bid)
                  if (widget.lot.myMaxBid != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Your max: \$${widget.lot.myMaxBid}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.isWinning
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Time remaining
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isEndingSoon
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRemaining(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEndingSoon
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isEndingSoon ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Action indicator
              if (!isExpired)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
