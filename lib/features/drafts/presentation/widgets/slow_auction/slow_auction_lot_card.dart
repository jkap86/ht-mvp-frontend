import 'package:flutter/material.dart';

import '../../../../../config/app_theme.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../players/domain/player.dart';
import '../../../data/draft_repository.dart';
import '../../../domain/auction_lot.dart';
import '../../../domain/bid_history_entry.dart';
import '../../../domain/draft_order_entry.dart';
import '../../mixins/countdown_mixin.dart';
import '../shared/bid_amount_display.dart';
import '../../../../../core/widgets/position_badge.dart';

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

class _SlowAuctionLotCardState extends State<SlowAuctionLotCard>
    with CountdownMixin {
  bool _isExpanded = false;
  List<BidHistoryEntry>? _bidHistory;
  bool _isLoadingHistory = false;
  bool _historyLoadError = false;

  @override
  void initState() {
    super.initState();
    startCountdown(widget.lot.bidDeadline, interval: const Duration(minutes: 1));
  }

  @override
  void didUpdateWidget(SlowAuctionLotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lot.bidDeadline != widget.lot.bidDeadline) {
      updateTimeRemaining(widget.lot.bidDeadline);
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

  String _getUsernameForRoster(int rosterId) {
    final entry = widget.draftOrder
        .where((e) => e.rosterId == rosterId)
        .firstOrNull;
    return entry?.username ?? 'Team $rosterId';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final urgency = getSlowAuctionUrgencyLevel();
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
                  PositionBadge(position: widget.player.primaryPosition),

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
                      BidAmountDisplay(
                        amount: widget.lot.currentBid,
                        isWinning: widget.isWinning,
                      ),
                      // User's max bid (if they've bid)
                      if (widget.lot.myMaxBid != null) ...[
                        const SizedBox(height: 4),
                        MaxBidIndicator(
                          maxBid: widget.lot.myMaxBid!,
                          isWinning: widget.isWinning,
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
                            formatSlowCountdown(),
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
          // Show bid history (most recent first) in scrollable container
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: _bidHistory!.reversed.map((entry) => _buildBidHistoryTile(entry, theme, isDark)).toList(),
              ),
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
                  formatTimeAgo(entry.createdAt),
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
