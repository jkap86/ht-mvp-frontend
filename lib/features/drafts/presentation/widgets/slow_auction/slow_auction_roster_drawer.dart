import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../players/domain/player.dart';
import '../../../domain/auction_lot.dart';
import '../../../domain/draft_order_entry.dart';
import '../../../domain/draft_pick.dart';
import '../../providers/draft_room_provider.dart';
import '../../utils/position_colors.dart';

/// Slide-out drawer showing all teams and their rosters in slow auction.
class SlowAuctionRosterDrawer extends ConsumerStatefulWidget {
  final DraftRoomKey providerKey;

  const SlowAuctionRosterDrawer({
    super.key,
    required this.providerKey,
  });

  @override
  ConsumerState<SlowAuctionRosterDrawer> createState() =>
      _SlowAuctionRosterDrawerState();
}

class _SlowAuctionRosterDrawerState
    extends ConsumerState<SlowAuctionRosterDrawer> {
  bool _includePendingWins = true;

  @override
  Widget build(BuildContext context) {
    final picks = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.picks),
    );
    final draftOrder = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftOrder),
    );
    final activeLots = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.activeLots),
    );
    final players = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.players),
    );
    final myRosterId = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.myRosterId),
    );

    // Build rosters map
    final rosters = _buildRosters(
      picks: picks,
      activeLots: activeLots,
      players: players,
      includePendingWins: _includePendingWins,
    );

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.groups),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Team Rosters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Toggle
            SwitchListTile(
              title: const Text('Include Pending Wins'),
              subtitle: const Text('Show players with high bids'),
              value: _includePendingWins,
              onChanged: (v) => setState(() => _includePendingWins = v),
            ),
            const Divider(),
            // Roster grid
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: draftOrder
                        .map((team) => _buildTeamColumn(
                              team,
                              rosters[team.rosterId] ?? [],
                              myRosterId,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, List<_RosterPlayer>> _buildRosters({
    required List<DraftPick> picks,
    required List<AuctionLot> activeLots,
    required List<Player> players,
    required bool includePendingWins,
  }) {
    final rosters = <int, List<_RosterPlayer>>{};

    // Add confirmed picks
    for (final pick in picks) {
      rosters.putIfAbsent(pick.rosterId, () => []);
      rosters[pick.rosterId]!.add(_RosterPlayer(
        name: pick.playerName ?? 'Unknown',
        position: pick.playerPosition ?? '?',
        isPending: false,
      ));
    }

    // Add pending wins if toggle is on
    if (includePendingWins) {
      for (final lot in activeLots) {
        if (lot.currentBidderRosterId != null) {
          final player =
              players.where((p) => p.id == lot.playerId).firstOrNull;
          if (player != null) {
            rosters.putIfAbsent(lot.currentBidderRosterId!, () => []);
            rosters[lot.currentBidderRosterId!]!.add(_RosterPlayer(
              name: player.fullName,
              position: player.primaryPosition,
              isPending: true,
              bid: lot.currentBid,
            ));
          }
        }
      }
    }

    return rosters;
  }

  Widget _buildTeamColumn(
    DraftOrderEntry team,
    List<_RosterPlayer> roster,
    int? myRosterId,
  ) {
    final theme = Theme.of(context);
    final isMyTeam = team.rosterId == myRosterId;

    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Team header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMyTeam
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  team.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isMyTeam
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${roster.length} players',
                  style: TextStyle(
                    fontSize: 10,
                    color: isMyTeam
                        ? theme.colorScheme.onPrimaryContainer.withAlpha(180)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Player list
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: roster.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'No players',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    children: roster
                        .map((p) => _buildPlayerTile(p, isMyTeam))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(_RosterPlayer player, bool isMyTeam) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: player.isPending ? Colors.amber.shade50 : null,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: getPositionColor(player.position),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                player.position,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Player name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
                if (player.isPending && player.bid != null)
                  Text(
                    '\$${player.bid}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          // Pending indicator
          if (player.isPending)
            Icon(
              Icons.hourglass_empty,
              size: 12,
              color: Colors.amber.shade700,
            ),
        ],
      ),
    );
  }
}

/// Internal model for roster players
class _RosterPlayer {
  final String name;
  final String position;
  final bool isPending;
  final int? bid;

  _RosterPlayer({
    required this.name,
    required this.position,
    required this.isPending,
    this.bid,
  });
}
