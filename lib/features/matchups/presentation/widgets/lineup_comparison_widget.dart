import 'package:flutter/material.dart';

import '../../domain/matchup.dart';

class LineupComparisonWidget extends StatelessWidget {
  final MatchupTeam team1;
  final MatchupTeam team2;
  final bool isTeam1Winner;
  final bool isTeam2Winner;

  const LineupComparisonWidget({
    super.key,
    required this.team1,
    required this.team2,
    required this.isTeam1Winner,
    required this.isTeam2Winner,
  });

  @override
  Widget build(BuildContext context) {
    // Group players by slot
    final team1Starters = team1.players.where((p) => p.isStarter).toList();
    final team1Bench = team1.players.where((p) => !p.isStarter).toList();
    final team2Starters = team2.players.where((p) => p.isStarter).toList();
    final team2Bench = team2.players.where((p) => !p.isStarter).toList();

    // Sort starters by slot order
    team1Starters.sort((a, b) => _slotIndex(a.slot) - _slotIndex(b.slot));
    team2Starters.sort((a, b) => _slotIndex(a.slot) - _slotIndex(b.slot));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Header row
          _buildHeaderRow(context),
          const Divider(height: 1),

          // Starters section
          _buildSectionHeader(context, 'STARTERS'),
          ...List.generate(
            _maxLength(team1Starters.length, team2Starters.length),
            (index) => _buildPlayerRow(
              context,
              index < team1Starters.length ? team1Starters[index] : null,
              index < team2Starters.length ? team2Starters[index] : null,
            ),
          ),

          const SizedBox(height: 8),

          // Bench section
          _buildSectionHeader(context, 'BENCH'),
          ...List.generate(
            _maxLength(team1Bench.length, team2Bench.length),
            (index) => _buildPlayerRow(
              context,
              index < team1Bench.length ? team1Bench[index] : null,
              index < team2Bench.length ? team2Bench[index] : null,
            ),
          ),

          if (team1Bench.isEmpty && team2Bench.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No bench players',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  int _slotIndex(String slot) {
    const order = ['QB', 'RB', 'WR', 'TE', 'FLEX', 'K', 'DEF', 'BN'];
    final index = order.indexOf(slot);
    return index == -1 ? 999 : index;
  }

  int _maxLength(int a, int b) => a > b ? a : b;

  Widget _buildHeaderRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              team1.teamName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTeam1Winner ? Colors.green.shade700 : null,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: const Text(
              'POS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              team2.teamName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTeam2Winner ? Colors.green.shade700 : null,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPlayerRow(
    BuildContext context,
    MatchupPlayer? player1,
    MatchupPlayer? player2,
  ) {
    final slot = player1?.slot ?? player2?.slot ?? '';
    final points1Won = player1 != null && player2 != null && player1.points > player2.points;
    final points2Won = player1 != null && player2 != null && player2.points > player1.points;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Team 1 player
          Expanded(
            child: _PlayerCell(
              player: player1,
              isWinning: points1Won,
              alignment: CrossAxisAlignment.end,
            ),
          ),

          // Position badge
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _PositionBadge(slot: slot),
            ),
          ),

          // Team 2 player
          Expanded(
            child: _PlayerCell(
              player: player2,
              isWinning: points2Won,
              alignment: CrossAxisAlignment.start,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCell extends StatelessWidget {
  final MatchupPlayer? player;
  final bool isWinning;
  final CrossAxisAlignment alignment;

  const _PlayerCell({
    this.player,
    required this.isWinning,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: const Text(
          'Empty',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
            fontSize: 12,
          ),
        ),
      );
    }

    final isLeftAligned = alignment == CrossAxisAlignment.start;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isWinning ? Colors.green.withValues(alpha: 0.1) : null,
      ),
      child: Row(
        mainAxisAlignment:
            isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeftAligned) ...[
            // Points (right side - show first)
            _PointsDisplay(points: player!.points, isWinning: isWinning),
            const SizedBox(width: 8),
          ],

          // Player info
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Text(
                  player!.fullName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: isLeftAligned ? TextAlign.left : TextAlign.right,
                ),
                Text(
                  '${player!.position ?? ''} - ${player!.team ?? 'FA'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: isLeftAligned ? TextAlign.left : TextAlign.right,
                ),
              ],
            ),
          ),

          if (isLeftAligned) ...[
            const SizedBox(width: 8),
            // Points (left side - show last)
            _PointsDisplay(points: player!.points, isWinning: isWinning),
          ],
        ],
      ),
    );
  }
}

class _PointsDisplay extends StatelessWidget {
  final double points;
  final bool isWinning;

  const _PointsDisplay({
    required this.points,
    required this.isWinning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isWinning
            ? Colors.green.shade100
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        points.toStringAsFixed(2),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isWinning ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final String slot;

  const _PositionBadge({required this.slot});

  @override
  Widget build(BuildContext context) {
    final color = _getPositionColor(slot);

    return Container(
      width: 36,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          slot,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String slot) {
    switch (slot.toUpperCase()) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
        return Colors.brown;
      case 'FLEX':
        return Colors.teal;
      case 'BN':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
