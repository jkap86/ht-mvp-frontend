import 'package:flutter/material.dart';

import '../../domain/draft_pick.dart';
import 'roster_position_section.dart';

/// Widget displaying the user's drafted roster organized by position.
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

  List<DraftPick> get _benchPicks {
    // Get all picks that haven't been assigned to starting positions
    final startingPositions = ['QB', 'RB', 'WR', 'TE', 'FLEX', 'K', 'DEF'];
    final assignedCount = startingPositions.fold<int>(
      0,
      (sum, pos) => sum + (_picksByPosition[pos]?.length ?? 0),
    );
    return myPicks.length > assignedCount
        ? myPicks.sublist(assignedCount)
        : <DraftPick>[];
  }

  /// Get position sections data for lazy building
  List<({String position, int slots, List<DraftPick> picks, List<String>? flexPositions})> get _positionSections => [
    (position: 'QB', slots: 1, picks: _picksByPosition['QB'] ?? [], flexPositions: null),
    (position: 'RB', slots: 2, picks: _picksByPosition['RB'] ?? [], flexPositions: null),
    (position: 'WR', slots: 2, picks: _picksByPosition['WR'] ?? [], flexPositions: null),
    (position: 'TE', slots: 1, picks: _picksByPosition['TE'] ?? [], flexPositions: null),
    (position: 'FLEX', slots: 1, picks: _picksByPosition['FLEX'] ?? [], flexPositions: const ['RB', 'WR', 'TE']),
    (position: 'K', slots: 1, picks: _picksByPosition['K'] ?? [], flexPositions: null),
    (position: 'DEF', slots: 1, picks: _picksByPosition['DEF'] ?? [], flexPositions: null),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = _positionSections;
    // +1 for bench section at the end
    final itemCount = sections.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(theme),
        const Divider(height: 1),
        // Roster list - use ListView.builder for lazy rendering
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < sections.length) {
                final section = sections[index];
                return RosterPositionSection(
                  position: section.position,
                  slots: section.slots,
                  picks: section.picks,
                  flexPositions: section.flexPositions,
                );
              }
              // Last item is the bench section
              return RosterBenchSection(
                benchPicks: _benchPicks,
                totalPicks: myPicks.length,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
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
    );
  }
}
