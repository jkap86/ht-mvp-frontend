import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../config/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../players/domain/player.dart';
import '../../../data/draft_repository.dart';
import '../../../domain/auction_lot.dart';
import '../../../domain/bid_history_entry.dart';
import '../../../domain/draft_order_entry.dart';
import '../../utils/position_colors.dart';

/// Individual auction card for the slow auction list view.
/// Expandable to show bid history inline.
class SlowAuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player player;
  final String highBidderName;
  final bool isWinning;
  final int leagueId;
  final int draftId;
  final List<DraftOrderEntry> draftOrder;
  final VoidCallback onBidTap;

  const SlowAuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.highBidderName,
    required this.isWinning,
    required this.leagueId,
    required this.draftId,
    required this.draftOrder,
    required this.onBidTap,
  });

  @override
  State<SlowAuctionLotCard> createState() => _SlowAuctionLotCardState();
}

class _SlowAuctionLotCardState extends State<SlowAuctionLotCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isExpanded = false;
  List<BidHistoryEntry>? _bidHistory;
  bool _isLoadingHistory = false;
  bool _historyLoadError = false;

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
    // Refresh bid history if lot changed and we're expanded
    if (oldWidget.lot.id != widget.lot.id && _isExpanded) {
      _loadBidHistory();
    }
  }

  Future<void> _loadBidHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoadingHistory = true;
      _historyLoadError = false;
    });

    try {
      final repo = DraftRepository(ApiClient());
      final history = await repo.getBidHistory(
        widget.leagueId,
        widget.draftId,
        widget.lot.id,
      );
      if (mounted) {
        setState(() {
          _bidHistory = history;
          _isLoadingHistory = false;
          _historyLoadError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _historyLoadError = true;
        });
      }
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    // Load bid history when expanding
    if (_isExpanded && _bidHistory == null && !_isLoadingHistory) {
      _loadBidHistory();
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  String _getUsernameForRoster(int rosterId) {
    final entry = widget.draftOrder
        .where((e) => e.rosterId == rosterId)
        .firstOrNull;
    return entry?.username ?? 'Team $rosterId';
  }

  /// Get urgency level for time remaining
  /// 0 = expired, 1 = critical (<30m), 2 = soon (<2h), 3 = normal
  int _getUrgencyLevel() {
    if (_timeRemaining == Duration.zero) return 0;
    if (_timeRemaining.inMinutes < 30) return 1;
    if (_timeRemaining.inHours < 2) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positionColor = getPositionColor(widget.player.primaryPosition);
    final urgency = _getUrgencyLevel();
    final isExpired = urgency == 0;
    final isEndingSoon = urgency <= 2;

    // Determine card background based on state
    Color? cardColor;
    if (widget.isWinning) {
      cardColor = AppTheme.draftActionPrimary.withAlpha(isDark ? 30 : 20);
    } else if (urgency == 1) {
      cardColor = AppTheme.draftUrgent.withAlpha(isDark ? 25 : 15);
    } else if (urgency == 2) {
      cardColor = AppTheme.draftWarning.withAlpha(isDark ? 20 : 12);
    }

    return Card(
      margin: EdgeInsets.zero,
      color: cardColor,
      child: Column(
        children: [
          // Main card content (tappable to expand)
          InkWell(
            onTap: isExpired ? null : _toggleExpanded,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Position badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: positionColor.withAlpha(isDark ? 50 : 35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: positionColor.withAlpha(isDark ? 100 : 70),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.player.primaryPosition,
                        style: TextStyle(
                          color: positionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.player.team ?? 'FA',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Leader: ${widget.highBidderName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: widget.isWinning
                                      ? AppTheme.draftActionPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight:
                                      widget.isWinning ? FontWeight.w600 : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Bid and time info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Current bid
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isWinning
                              ? AppTheme.draftActionPrimary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$${widget.lot.currentBid}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: widget.isWinning
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // User's max bid (if they've bid)
                      if (widget.lot.myMaxBid != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Max: \$${widget.lot.myMaxBid}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: widget.isWinning
                                ? AppTheme.draftActionPrimary
                                : theme.colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Time remaining with urgency coloring
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            urgency <= 1 ? Icons.timer : Icons.timer_outlined,
                            size: 14,
                            color: urgency == 1
                                ? AppTheme.draftUrgent
                                : urgency == 2
                                    ? AppTheme.draftWarning
                                    : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeRemaining(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: urgency == 1
                                  ? AppTheme.draftUrgent
                                  : urgency == 2
                                      ? AppTheme.draftWarning
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isEndingSoon ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(width: 8),

                  // Expansion indicator
                  if (!isExpired)
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),

          // Expanded section with bid history
          if (_isExpanded) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant.withAlpha(100),
            ),
            _buildExpandedSection(theme, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bid Activity Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Bid Activity (${widget.lot.bidCount})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (!_isLoadingHistory && !_historyLoadError)
                InkWell(
                  onTap: _loadBidHistory,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Bid history content
        if (_isLoadingHistory)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_historyLoadError)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Failed to load bid history',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _loadBidHistory,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (_bidHistory == null || _bidHistory!.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No bid activity yet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          // Show bid history (most recent first)
          ..._bidHistory!.reversed.take(5).map((entry) => _buildBidHistoryTile(entry, theme, isDark)),

        // Show "more" indicator if there are more than 5 bids
        if (_bidHistory != null && _bidHistory!.length > 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '+${_bidHistory!.length - 5} more bids',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 8),

        // Place Bid button
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ElevatedButton.icon(
            onPressed: widget.onBidTap,
            icon: const Icon(Icons.gavel, size: 18),
            label: const Text('Place Bid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBidHistoryTile(BidHistoryEntry entry, ThemeData theme, bool isDark) {
    final username = entry.username ?? _getUsernameForRoster(entry.rosterId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(50),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            entry.isProxy ? Icons.autorenew : Icons.person,
            size: 16,
            color: entry.isProxy
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimeAgo(entry.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${entry.bidAmount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
