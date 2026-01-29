import 'package:flutter/material.dart';

import '../../domain/draft_pick.dart';
import '../utils/position_colors.dart';
import 'roster_slot.dart';

/// A section showing roster slots for a specific position.
class RosterPositionSection extends StatelessWidget {
  final String position;
  final int slots;
  final List<DraftPick> picks;
  final List<String>? flexPositions;

  const RosterPositionSection({
    super.key,
    required this.position,
    required this.slots,
    required this.picks,
    this.flexPositions,
  });

  @override
  Widget build(BuildContext context) {
    final color = getPositionColor(position);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    position,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (flexPositions != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${flexPositions!.join('/')})',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Slots
          ...List.generate(slots, (index) {
            final pick = index < picks.length ? picks[index] : null;
            return RosterSlot(
              pick: pick,
              position: position,
            );
          }),
        ],
      ),
    );
  }
}

/// Bench section showing overflow players beyond starting positions.
class RosterBenchSection extends StatelessWidget {
  final List<DraftPick> benchPicks;
  final int totalPicks;

  const RosterBenchSection({
    super.key,
    required this.benchPicks,
    required this.totalPicks,
  });

  @override
  Widget build(BuildContext context) {
    if (benchPicks.isEmpty && totalPicks <= 8) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'BENCH',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          ...benchPicks.map((pick) => RosterSlot(
                pick: pick,
                position: 'BN',
              )),
          // Show empty bench slots
          ...List.generate(
            (6 - benchPicks.length).clamp(0, 6),
            (_) => const RosterSlot(pick: null, position: 'BN'),
          ),
        ],
      ),
    );
  }
}
