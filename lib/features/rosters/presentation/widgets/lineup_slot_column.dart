import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import 'lineup_player_row.dart';

/// Configuration for a lineup slot with its required count
typedef SlotConfig = (LineupSlot slot, int count);

/// A column displaying all starter lineup slots (QB, RB, WR, TE, FLEX, K, DEF)
class LineupSlotColumn extends StatelessWidget {
  /// Players organized by lineup slot
  final Map<LineupSlot, List<RosterPlayer>> playersBySlot;

  /// Whether the lineup is locked for editing
  final bool isLocked;

  /// Callback when a slot is tapped
  final void Function(LineupSlot slot, RosterPlayer? player)? onSlotTap;

  /// Slot configuration defining order and count for each position
  static const List<SlotConfig> defaultSlotConfig = [
    (LineupSlot.qb, 1),
    (LineupSlot.rb, 2),
    (LineupSlot.wr, 2),
    (LineupSlot.te, 1),
    (LineupSlot.flex, 1),
    (LineupSlot.k, 1),
    (LineupSlot.def, 1),
  ];

  const LineupSlotColumn({
    super.key,
    required this.playersBySlot,
    this.isLocked = false,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            'STARTERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...defaultSlotConfig.expand((config) {
          final slot = config.$1;
          final count = config.$2;
          final playersInSlot = playersBySlot[slot] ?? [];

          return List.generate(count, (index) {
            final player =
                index < playersInSlot.length ? playersInSlot[index] : null;
            return LineupPlayerRow(
              slot: slot,
              slotIndex: index,
              player: player,
              isLocked: isLocked,
              onTap: isLocked ? null : () => onSlotTap?.call(slot, player),
            );
          });
        }),
      ],
    );
  }
}
