import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import 'lineup_player_row.dart';

/// A list displaying all bench players
class BenchList extends StatelessWidget {
  /// List of players on the bench
  final List<RosterPlayer> benchPlayers;

  /// Whether the lineup is locked for editing
  final bool isLocked;

  /// Callback when a bench player is tapped
  final void Function(RosterPlayer player)? onPlayerTap;

  const BenchList({
    super.key,
    required this.benchPlayers,
    this.isLocked = false,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'BENCH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        if (benchPlayers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No bench players',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...benchPlayers.map(
            (player) => LineupPlayerRow(
              slot: LineupSlot.bn,
              slotIndex: 0,
              player: player,
              isLocked: isLocked,
              onTap: isLocked ? null : () => onPlayerTap?.call(player),
            ),
          ),
      ],
    );
  }
}
