import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/app_theme.dart';
import '../../../../players/domain/player.dart';
import '../../../domain/auction_lot.dart';
import '../../../domain/draft_order_entry.dart';
import '../../../domain/draft_pick.dart';
import '../../providers/draft_room_provider.dart';
import '../../utils/position_colors.dart';

/// Slide-out drawer showing all teams and their rosters in slow auction.
/// Teams are displayed vertically and expand on tap to show players.
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
            // Vertical expandable team list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: draftOrder.length,
                itemBuilder: (context, index) {
                  final team = draftOrder[index];
                  return _buildTeamExpansionTile(
                    team,
                    rosters[team.rosterId] ?? [],
                    myRosterId,
                  );
                },
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

  Widget _buildTeamExpansionTile(
    DraftOrderEntry team,
    List<_RosterPlayer> roster,
    int? myRosterId,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMyTeam = team.rosterId == myRosterId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isMyTeam
          ? AppTheme.draftActionPrimary.withAlpha(isDark ? 25 : 15)
          : null,
      child: Theme(
        // Override ExpansionTile divider color
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isMyTeam
                ? AppTheme.draftActionPrimary
                : theme.colorScheme.surfaceContainerHighest,
            child: Text(
              team.username.isNotEmpty
                  ? team.username.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                color: isMyTeam
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  team.username,
                  style: TextStyle(
                    fontWeight: isMyTeam ? FontWeight.bold : FontWeight.w500,
                    color: isMyTeam ? AppTheme.draftActionPrimary : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isMyTeam)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.draftActionPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'YOU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${roster.length} player${roster.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: roster.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No players yet',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ]
              : roster.map((p) => _buildPlayerListTile(p)).toList(),
        ),
      ),
    );
  }

  Widget _buildPlayerListTile(_RosterPlayer player) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positionColor = getPositionColor(player.position);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: positionColor.withAlpha(isDark ? 50 : 35),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: positionColor.withAlpha(isDark ? 100 : 70),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            player.position,
            style: TextStyle(
              color: positionColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Text(
        player.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: player.isPending ? FontWeight.w500 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: player.isPending
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${player.bid}',
                  style: TextStyle(
                    color: AppTheme.draftWarning,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.hourglass_top,
                  size: 16,
                  color: AppTheme.draftWarning,
                ),
              ],
            )
          : null,
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
