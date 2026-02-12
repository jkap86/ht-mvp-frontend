import 'package:flutter/material.dart';
import '../../domain/trade.dart';
import '../../domain/trade_item.dart';
import '../../../../core/widgets/position_badge.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/theme/semantic_colors.dart';

/// Widget showing all trade assets (players + picks) split by team
class TradeAssetsSection extends StatelessWidget {
  final Trade trade;

  const TradeAssetsSection({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Proposer's side (assets they're giving away)
        Expanded(
          child: _buildTeamColumn(
            context,
            teamName: trade.proposerTeamName,
            label: 'Gives',
            items: trade.proposerGiving,
            isLeft: true,
          ),
        ),
        const SizedBox(width: 16),
        // Recipient's side (assets they're giving away)
        Expanded(
          child: _buildTeamColumn(
            context,
            teamName: trade.recipientTeamName,
            label: 'Gives',
            items: trade.recipientGiving,
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamColumn(
    BuildContext context, {
    required String teamName,
    required String label,
    required List<TradeItem> items,
    required bool isLeft,
  }) {
    // Separate items by type
    final players = items.where((item) => item.isPlayer).toList();
    final picks = items.where((item) => item.isDraftPick).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              teamName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const Divider(),
            if (items.isEmpty)
              Text(
                'No assets',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              )
            else ...[
              // Players section
              if (players.isNotEmpty) ...[
                ...players.map((item) => _buildPlayerRow(context, item, isLeft)),
              ],
              // Picks section
              if (picks.isNotEmpty) ...[
                if (players.isNotEmpty) const SizedBox(height: 8),
                ...picks.map((item) => _buildPickRow(context, item, isLeft)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(BuildContext context, TradeItem item, bool isLeft) {
    final position = item.displayPosition;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isLeft
            ? [
                PositionBadge(position: position, size: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (item.displayTeam.isNotEmpty)
                            Text(
                              item.displayTeam,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          if (item.status != null && item.status!.isNotEmpty) ...[
                            if (item.displayTeam.isNotEmpty) const SizedBox(width: 6),
                            StatusBadge(
                              label: item.status!,
                              backgroundColor: getInjuryColor(item.status),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ]
            : [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.fullName,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (item.status != null && item.status!.isNotEmpty) ...[
                            StatusBadge(
                              label: item.status!,
                              backgroundColor: getInjuryColor(item.status),
                            ),
                            if (item.displayTeam.isNotEmpty) const SizedBox(width: 6),
                          ],
                          if (item.displayTeam.isNotEmpty)
                            Text(
                              item.displayTeam,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PositionBadge(position: position, size: 32),
              ],
      ),
    );
  }

  Widget _buildPickRow(BuildContext context, TradeItem item, bool isLeft) {
    final pickBadge = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'R${item.pickRound ?? '?'}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );

    final pickDetails = Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          item.pickDisplayName,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Draft Pick',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isLeft
            ? [
                pickBadge,
                const SizedBox(width: 8),
                Flexible(child: pickDetails),
              ]
            : [
                Flexible(child: pickDetails),
                const SizedBox(width: 8),
                pickBadge,
              ],
      ),
    );
  }
}

/// Helper to build compact asset count labels (for TradeCard)
String buildAssetCountLabel(List<TradeItem> items) {
  final playerCount = items.where((i) => i.isPlayer).length;
  final pickCount = items.where((i) => i.isDraftPick).length;

  final parts = <String>[];
  if (playerCount > 0) {
    parts.add('$playerCount player${playerCount != 1 ? 's' : ''}');
  }
  if (pickCount > 0) {
    parts.add('$pickCount pick${pickCount != 1 ? 's' : ''}');
  }
  return parts.isEmpty ? 'No assets' : parts.join(' + ');
}
