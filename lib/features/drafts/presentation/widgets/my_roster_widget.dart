import 'package:flutter/material.dart';

import '../../domain/draft_pick.dart';
import '../utils/position_colors.dart';

class MyRosterWidget extends StatelessWidget {
  final List<DraftPick> myPicks;
  final String username;

  const MyRosterWidget({
    super.key,
    required this.myPicks,
    this.username = 'My Team',
  });

  // Standard roster slots - can be made configurable later
  static const Map<String, int> defaultRosterSlots = {
    'QB': 1,
    'RB': 2,
    'WR': 2,
    'TE': 1,
    'FLEX': 1,
    'K': 1,
    'DEF': 1,
    'BN': 6,
  };

  Map<String, List<DraftPick>> get _picksByPosition {
    final Map<String, List<DraftPick>> result = {};
    for (final pick in myPicks) {
      final pos = pick.playerPosition ?? 'BN';
      result.putIfAbsent(pos, () => []).add(pick);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.people, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                username,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${myPicks.length} picks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildPositionGroup('QB', 1),
              _buildPositionGroup('RB', 2),
              _buildPositionGroup('WR', 2),
              _buildPositionGroup('TE', 1),
              _buildPositionGroup('FLEX', 1, flexPositions: ['RB', 'WR', 'TE']),
              _buildPositionGroup('K', 1),
              _buildPositionGroup('DEF', 1),
              _buildBenchSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionGroup(String position, int slots, {List<String>? flexPositions}) {
    final picks = _picksByPosition[position] ?? [];
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
                    '(${flexPositions.join('/')})',
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
            return _RosterSlot(
              pick: pick,
              position: position,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBenchSection() {
    // Get all picks that haven't been assigned to starting positions
    final startingPositions = ['QB', 'RB', 'WR', 'TE', 'FLEX', 'K', 'DEF'];
    final assignedCount = startingPositions.fold<int>(
      0,
      (sum, pos) => sum + (_picksByPosition[pos]?.length ?? 0),
    );
    final benchPicks = myPicks.length > assignedCount
        ? myPicks.sublist(assignedCount)
        : <DraftPick>[];

    if (benchPicks.isEmpty && myPicks.length <= 8) {
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
          ...benchPicks.map((pick) => _RosterSlot(
                pick: pick,
                position: 'BN',
              )),
          // Show empty bench slots
          ...List.generate(
            (6 - benchPicks.length).clamp(0, 6),
            (_) => const _RosterSlot(pick: null, position: 'BN'),
          ),
        ],
      ),
    );
  }
}

class _RosterSlot extends StatelessWidget {
  final DraftPick? pick;
  final String position;

  const _RosterSlot({
    required this.pick,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final color = pick != null
        ? getPositionColor(pick!.playerPosition ?? position)
        : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pick != null ? color.withValues(alpha: 0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pick != null ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (pick != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  pick!.playerPosition ?? '?',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pick!.playerName ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${pick!.playerTeam ?? 'FA'} • Pick #${pick!.pickNumber}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Text(
                  'Empty',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
