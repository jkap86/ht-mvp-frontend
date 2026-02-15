import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../players/domain/player.dart';
import '../../domain/auction_lot.dart';
import '../providers/draft_room_provider.dart';

class AuctionLotsPanel extends StatefulWidget {
  final DraftRoomState state;
  final void Function(AuctionLot lot) onBidTap;
  final VoidCallback onNominateTap;
  /// Server clock offset in milliseconds for accurate countdown
  final int? serverClockOffsetMs;

  const AuctionLotsPanel({
    super.key,
    required this.state,
    required this.onBidTap,
    required this.onNominateTap,
    this.serverClockOffsetMs,
  });

  @override
  State<AuctionLotsPanel> createState() => _AuctionLotsPanelState();
}

class _AuctionLotsPanelState extends State<AuctionLotsPanel> {
  // Cache for players map
  Map<int, Player>? _cachedPlayersMap;
  List<Player>? _lastPlayers;

  // Cache for budgets map
  Map<int, dynamic>? _cachedBudgetsMap;
  List<dynamic>? _lastBudgets;

  /// Get or create players map - reuses cache if players list unchanged
  Map<int, Player> _getPlayersMap(List<Player> players) {
    if (identical(_lastPlayers, players) && _cachedPlayersMap != null) {
      return _cachedPlayersMap!;
    }
    _lastPlayers = players;
    _cachedPlayersMap = {for (var p in players) p.id: p};
    return _cachedPlayersMap!;
  }

  /// Get or create budgets map - reuses cache if budgets list unchanged
  Map<int, dynamic> _getBudgetsMap(List<dynamic> budgets) {
    if (identical(_lastBudgets, budgets) && _cachedBudgetsMap != null) {
      return _cachedBudgetsMap!;
    }
    _lastBudgets = budgets;
    _cachedBudgetsMap = {for (var b in budgets) b.rosterId: b};
    return _cachedBudgetsMap!;
  }

  @override
  Widget build(BuildContext context) {
    final activeLots = widget.state.activeLots;

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
              onPressed: widget.onNominateTap,
              icon: const Icon(Icons.add),
              label: const Text('Nominate'),
            ),
          ],
        ),
      );
    }

    // Build maps with caching - reuses if players/budgets lists unchanged
    final playersMap = _getPlayersMap(widget.state.players);
    final budgetsMap = _getBudgetsMap(widget.state.budgets);

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
                  onPressed: widget.onNominateTap,
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
                  key: ValueKey(lot.id),
                  lot: lot,
                  player: player,
                  leadingBidderName: leadingBidder,
                  onBidTap: () => widget.onBidTap(lot),
                  serverClockOffsetMs: widget.serverClockOffsetMs,
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
  final int? serverClockOffsetMs;

  const _AuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.onBidTap,
    this.serverClockOffsetMs,
  });

  @override
  State<_AuctionLotCard> createState() => _AuctionLotCardState();
}

class _AuctionLotCardState extends State<_AuctionLotCard> {
  Timer? _timer;
  final ValueNotifier<Duration> _remaining = ValueNotifier(Duration.zero);

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
    // Apply server clock offset for accurate countdown on devices with clock drift
    final offset = widget.serverClockOffsetMs;
    final now = offset != null
        ? DateTime.now().add(Duration(milliseconds: offset)).toUtc()
        : DateTime.now().toUtc();
    final deadline = widget.lot.bidDeadline.toUtc();
    final diff = deadline.difference(now);
    _remaining.value = diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remaining.dispose();
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
            // Countdown timer - only this subtree rebuilds on timer tick
            ValueListenableBuilder<Duration>(
              valueListenable: _remaining,
              builder: (context, remaining, _) {
                final isExpired = remaining == Duration.zero;
                final isUrgent = remaining.inMinutes < 5 && !isExpired;
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
                        isExpired ? 'Expired' : _formatDuration(remaining),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            // Bid button - also depends on timer for expired state
            ValueListenableBuilder<Duration>(
              valueListenable: _remaining,
              builder: (context, remaining, _) {
                final isExpired = remaining == Duration.zero;
                return SizedBox(
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
