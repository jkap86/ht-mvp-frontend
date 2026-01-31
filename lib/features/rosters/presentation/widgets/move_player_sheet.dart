import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

void showMovePlayerSheet({
  required BuildContext context,
  required RosterPlayer player,
  required LineupSlot? currentSlot,
  required void Function(String slotCode) onMove,
}) {
  // Determine which slots this player can fill based on position
  final position = player.position;
  final validSlots =
      LineupSlot.values.where((slot) => slot.canFill(position)).toList();

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return _MovePlayerSheetContent(
        player: player,
        currentSlot: currentSlot,
        validSlots: validSlots,
        onMove: onMove,
      );
    },
  );
}

class _MovePlayerSheetContent extends StatelessWidget {
  final RosterPlayer player;
  final LineupSlot? currentSlot;
  final List<LineupSlot> validSlots;
  final void Function(String slotCode) onMove;

  const _MovePlayerSheetContent({
    required this.player,
    required this.currentSlot,
    required this.validSlots,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Move ${player.fullName ?? "Player"}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...validSlots.map((slot) {
            final isCurrentSlot = currentSlot == slot;
            return ListTile(
              leading: Icon(
                _getSlotIcon(slot),
                color: isCurrentSlot ? Theme.of(context).primaryColor : null,
              ),
              title: Text(slot.displayName),
              trailing: isCurrentSlot
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: isCurrentSlot
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onMove(slot.code);
                    },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  IconData _getSlotIcon(LineupSlot slot) {
    switch (slot) {
      case LineupSlot.qb:
        return Icons.sports_football;
      case LineupSlot.rb:
        return Icons.directions_run;
      case LineupSlot.wr:
        return Icons.catching_pokemon;
      case LineupSlot.te:
        return Icons.person;
      case LineupSlot.flex:
        return Icons.swap_horiz;
      case LineupSlot.superFlex:
        return Icons.swap_vert;
      case LineupSlot.recFlex:
        return Icons.swap_horizontal_circle;
      case LineupSlot.k:
        return Icons.sports_soccer;
      case LineupSlot.def:
        return Icons.shield;
      case LineupSlot.dl:
        return Icons.security;
      case LineupSlot.lb:
        return Icons.sports_martial_arts;
      case LineupSlot.db:
        return Icons.gpp_good;
      case LineupSlot.idpFlex:
        return Icons.local_police;
      case LineupSlot.bn:
        return Icons.chair;
      case LineupSlot.ir:
        return Icons.healing;
      case LineupSlot.taxi:
        return Icons.local_taxi;
    }
  }
}
