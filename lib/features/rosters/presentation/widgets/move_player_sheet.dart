import 'package:flutter/material.dart';

import '../../domain/roster_legality.dart';
import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';

void showMovePlayerSheet({
  required BuildContext context,
  required RosterPlayer player,
  required LineupSlot? currentSlot,
  MoveValidation? moveValidation,
  required void Function(String slotCode) onMove,
}) {
  // If move validation is provided, use it; otherwise fall back to basic canFill
  final validSlots = moveValidation?.validSlots ??
      LineupSlot.values.where((slot) => slot.canFill(player.position)).toList();
  final ineligibleSlots = moveValidation?.ineligibleSlots ?? [];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _MovePlayerSheetContent(
        player: player,
        currentSlot: currentSlot,
        validSlots: validSlots,
        ineligibleSlots: ineligibleSlots,
        onMove: onMove,
      );
    },
  );
}

class _MovePlayerSheetContent extends StatelessWidget {
  final RosterPlayer player;
  final LineupSlot? currentSlot;
  final List<LineupSlot> validSlots;
  final List<SlotIneligibilityReason> ineligibleSlots;
  final void Function(String slotCode) onMove;

  const _MovePlayerSheetContent({
    required this.player,
    required this.currentSlot,
    required this.validSlots,
    required this.ineligibleSlots,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Move ${player.fullName ?? "Player"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player.position ?? "?"} - ${player.team ?? "FA"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (currentSlot != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Currently: ${currentSlot!.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Valid slots section
            if (validSlots.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Available Slots',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ...validSlots.map((slot) {
                final isCurrentSlot = currentSlot == slot;
                return ListTile(
                  leading: Icon(
                    _getSlotIcon(slot),
                    color: isCurrentSlot ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(slot.displayName),
                  trailing: isCurrentSlot
                      ? Icon(Icons.check, color: colorScheme.primary)
                      : const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: isCurrentSlot
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          onMove(slot.code);
                        },
                );
              }),
            ],

            // Unavailable slots section (greyed out with reasons)
            if (ineligibleSlots.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: ineligibleSlots.map((entry) {
                    return ListTile(
                      leading: Icon(
                        _getSlotIcon(entry.slot),
                        color: colorScheme.onSurfaceVariant.withAlpha(100),
                      ),
                      title: Text(
                        entry.slot.displayName,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withAlpha(150),
                        ),
                      ),
                      subtitle: Text(
                        entry.reason,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                      ),
                      dense: true,
                      enabled: false,
                    );
                  }).toList(),
                ),
              ),
            ],

            if (validSlots.isEmpty && ineligibleSlots.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No available slots for this player',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
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
