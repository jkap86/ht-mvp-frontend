import 'package:flutter/material.dart';

import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
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

          const SizedBox(height: AppSpacing.sm),

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
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No bench players',
                style: AppTypography.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              team1.teamName,
              style: AppTypography.bodyBold.copyWith(
                color: isTeam1Winner ? context.htColors.success : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 50,
            alignment: Alignment.center,
            child: Text(
              'POS',
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              team2.teamName,
              style: AppTypography.bodyBold.copyWith(
                color: isTeam2Winner ? context.htColors.success : theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      width: double.infinity,
      color: context.htColors.surfaceContainer,
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
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
          bottom: BorderSide(
            color: context.htColors.surfaceContainer,
            width: 1,
          ),
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
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
    final theme = Theme.of(context);

    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          'Empty',
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final isLeftAligned = alignment == CrossAxisAlignment.start;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isWinning ? context.htColors.selectionSuccess : null,
      ),
      child: Row(
        mainAxisAlignment:
            isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeftAligned) ...[
            // Points (right side - show first)
            _PointsDisplay(points: player!.points, isWinning: isWinning),
            const SizedBox(width: AppSpacing.sm),
          ],

          // Player info
          Flexible(
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                Text(
                  player!.fullName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: isLeftAligned ? TextAlign.left : TextAlign.right,
                ),
                Text(
                  '${player!.position ?? ''} - ${player!.team ?? 'FA'}',
                  style: AppTypography.label.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: isLeftAligned ? TextAlign.left : TextAlign.right,
                ),
              ],
            ),
          ),

          if (isLeftAligned) ...[
            const SizedBox(width: AppSpacing.sm),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isWinning
            ? context.htColors.selectionSuccess
            : context.htColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        points.toStringAsFixed(2),
        style: TextStyle(
          fontSize: AppTypography.fontXs + 1,
          fontWeight: FontWeight.bold,
          color: isWinning
              ? context.htColors.success
              : theme.colorScheme.onSurfaceVariant,
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
    final color = getPositionColor(slot);

    return Container(
      width: 36,
      height: 24,
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Center(
        child: Text(
          slot,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: AppTypography.fontXs,
          ),
        ),
      ),
    );
  }
}
