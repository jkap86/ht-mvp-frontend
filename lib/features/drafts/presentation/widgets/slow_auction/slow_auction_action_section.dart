import 'package:flutter/material.dart';

import '../../../../players/domain/player.dart';
import '../../../domain/auction_lot.dart';
import '../../../domain/draft_order_entry.dart';

/// Action needed section for slow auction.
/// Shows alerts for nominations and outbid situations.
class SlowAuctionActionSection extends StatelessWidget {
  final List<AuctionLot> activeLots;
  final List<AuctionLot> outbidLots;
  final int? myRosterId;
  final List<Player> players;
  final List<DraftOrderEntry> draftOrder;
  final VoidCallback onNominate;
  final void Function(AuctionLot) onViewLot;
  final VoidCallback? onViewAllOutbid;
  final VoidCallback? onViewAllEndingSoon;

  // Nomination limit tracking
  final int? dailyNominationsRemaining;
  final int? dailyNominationLimit;
  final bool globalCapReached;

  const SlowAuctionActionSection({
    super.key,
    required this.activeLots,
    required this.outbidLots,
    required this.myRosterId,
    required this.players,
    required this.draftOrder,
    required this.onNominate,
    required this.onViewLot,
    this.onViewAllOutbid,
    this.onViewAllEndingSoon,
    this.dailyNominationsRemaining,
    this.dailyNominationLimit,
    this.globalCapReached = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find lots ending soon (within 2 hours)
    final now = DateTime.now();
    final endingSoon = activeLots.where((lot) {
      final timeLeft = lot.bidDeadline.difference(now);
      return timeLeft.inHours < 2 && timeLeft.isNegative == false;
    }).toList();

    // Count action items
    final actionCount = 1 + outbidLots.length + endingSoon.length; // 1 for nominate

    if (actionCount == 1 && outbidLots.isEmpty && endingSoon.isEmpty) {
      // Just show nominate button when no urgent actions
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _buildNominateCard(context),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notification_important,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Action Needed ($actionCount)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nominate card
          _buildNominateCard(context),

          // Outbid alerts
          ...outbidLots.take(3).map((lot) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildOutbidCard(context, lot),
              )),

          // View all outbid link (if more than 3)
          if (outbidLots.length > 3 && onViewAllOutbid != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: onViewAllOutbid,
                icon: const Icon(Icons.visibility, size: 16),
                label: Text('View all ${outbidLots.length} outbid auctions'),
              ),
            ),

          // Ending soon alerts
          ...endingSoon.take(2).map((lot) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildEndingSoonCard(context, lot),
              )),

          // View all ending soon link (if more than 2)
          if (endingSoon.length > 2 && onViewAllEndingSoon != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: onViewAllEndingSoon,
                icon: const Icon(Icons.timer, size: 16),
                label: Text('View all ${endingSoon.length} ending soon'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNominateCard(BuildContext context) {
    final theme = Theme.of(context);

    // Check if nominations are blocked
    final isBlocked = globalCapReached ||
        (dailyNominationsRemaining != null && dailyNominationsRemaining! <= 0);

    // Build subtitle text
    String subtitle;
    Color? subtitleColor;
    if (globalCapReached) {
      subtitle = 'Maximum active auctions reached league-wide';
      subtitleColor = theme.colorScheme.error;
    } else if (dailyNominationsRemaining != null &&
        dailyNominationsRemaining! <= 0) {
      subtitle = 'Daily nomination limit reached. Try again tomorrow.';
      subtitleColor = theme.colorScheme.error;
    } else if (dailyNominationsRemaining != null &&
        dailyNominationLimit != null) {
      subtitle =
          '$dailyNominationsRemaining of $dailyNominationLimit nominations remaining today';
      subtitleColor = dailyNominationsRemaining == 1
          ? theme.colorScheme.tertiary
          : theme.colorScheme.onSurfaceVariant;
    } else {
      subtitle = 'Add a player to the auction block';
      subtitleColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: isBlocked ? null : onNominate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isBlocked
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isBlocked ? Icons.block : Icons.person_add,
                  color: isBlocked
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nominate Player',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isBlocked
                            ? theme.colorScheme.onSurfaceVariant
                            : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildOutbidCard(BuildContext context, AuctionLot lot) {
    final theme = Theme.of(context);
    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    final playerName = player?.fullName ?? 'Unknown Player';
    final highBidder = draftOrder
        .where((e) => e.rosterId == lot.currentBidderRosterId)
        .firstOrNull;
    final timeLeft = _formatTimeRemaining(lot.bidDeadline);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.errorContainer.withAlpha(50),
      child: InkWell(
        onTap: () => onViewLot(lot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_down,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'OUTBID',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            playerName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${lot.currentBid} by ${highBidder?.username ?? 'Unknown'} · $timeLeft left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => onViewLot(lot),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Raise'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndingSoonCard(BuildContext context, AuctionLot lot) {
    final theme = Theme.of(context);
    final player = players.where((p) => p.id == lot.playerId).firstOrNull;
    final playerName = player?.fullName ?? 'Unknown Player';
    final timeLeft = _formatTimeRemaining(lot.bidDeadline);
    final isWinning = lot.currentBidderRosterId == myRosterId;

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.tertiaryContainer.withAlpha(50),
      child: InkWell(
        onTap: () => onViewLot(lot),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timer,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ENDING SOON',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            playerName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${lot.currentBid} · $timeLeft left${isWinning ? ' · You\'re winning!' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isWinning
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isWinning ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ),
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

  String _formatTimeRemaining(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);

    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return '${diff.inSeconds}s';
  }
}
