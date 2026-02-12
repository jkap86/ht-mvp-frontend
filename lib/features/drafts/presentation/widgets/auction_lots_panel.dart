import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../players/domain/player.dart';
import '../../domain/auction_lot.dart';
import '../providers/draft_room_provider.dart';

class AuctionLotsPanel extends StatelessWidget {
  final DraftRoomState state;
  final void Function(AuctionLot lot) onBidTap;
  final VoidCallback onNominateTap;

  const AuctionLotsPanel({
    super.key,
    required this.state,
    required this.onBidTap,
    required this.onNominateTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeLots = state.activeLots;

    if (activeLots.isEmpty) {
      final emptyTheme = Theme.of(context);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: emptyTheme.colorScheme.surfaceContainerHighest,
          border: Border(top: BorderSide(color: emptyTheme.colorScheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gavel, color: emptyTheme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              'No active lots',
              style: TextStyle(color: emptyTheme.colorScheme.onSurfaceVariant),
            ),
            Text(
              'Nominate a player to start an auction',
              style: TextStyle(color: emptyTheme.colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onNominateTap,
              icon: const Icon(Icons.add),
              label: const Text('Nominate'),
            ),
          ],
        ),
      );
    }

    // Build a map of players by ID for quick lookup
    final playersMap = {for (var p in state.players) p.id: p};

    // Build a map of budgets by rosterId for quick lookup of bidder names
    final budgetsMap = {for (var b in state.budgets) b.rosterId: b};

    return Container(
      decoration: BoxDecoration(
        color: context.htColors.auctionBg,
        border: Border(top: BorderSide(
          color: context.htColors.auctionBorder,
        )),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.gavel, size: 18, color: context.htColors.auctionAccent),
                const SizedBox(width: 8),
                Text(
                  'Active Lots (${activeLots.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.htColors.auctionAccent,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onNominateTap,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Nominate'),
                  style: TextButton.styleFrom(
                    foregroundColor: context.htColors.auctionAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: activeLots.length,
              itemBuilder: (context, index) {
                final lot = activeLots[index];
                final player = playersMap[lot.playerId];
                final leadingBidder = lot.currentBidderRosterId != null
                    ? budgetsMap[lot.currentBidderRosterId]?.username
                    : null;

                return _AuctionLotCard(
                  lot: lot,
                  player: player,
                  leadingBidderName: leadingBidder,
                  onBidTap: () => onBidTap(lot),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player? player;
  final String? leadingBidderName;
  final VoidCallback onBidTap;

  const _AuctionLotCard({
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.onBidTap,
  });

  @override
  State<_AuctionLotCard> createState() => _AuctionLotCardState();
}

class _AuctionLotCardState extends State<_AuctionLotCard> {
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
  void didUpdateWidget(_AuctionLotCard oldWidget) {
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    } else if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final playerName = player?.fullName ?? 'Unknown Player';
    final position = player?.primaryPosition ?? '';
    final team = player?.team ?? '';

    final isExpired = _remaining == Duration.zero;
    final isUrgent = _remaining.inMinutes < 5 && !isExpired;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player name
            Text(
              playerName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Position and team
            Text(
              '$position - $team',
              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Current bid
            Row(
              children: [
                Text(
                  '\$${widget.lot.currentBid}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.htColors.draftAction,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.leadingBidderName ?? 'No bids',
                    style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Countdown timer
            Builder(builder: (context) {
              final timerColor = isExpired
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : isUrgent
                      ? AppTheme.draftUrgent
                      : context.htColors.draftNormal;
              final timerBgColor = isExpired
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : isUrgent
                      ? AppTheme.draftUrgent.withAlpha(25)
                      : context.htColors.draftNormal.withAlpha(25);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: timerBgColor,
                  borderRadius: AppSpacing.badgeRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: timerColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpired ? 'Expired' : _formatDuration(_remaining),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: timerColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Spacer(),
            // Bid button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isExpired ? null : widget.onBidTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.htColors.auctionAccent,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
                child: const Text('Bid', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
