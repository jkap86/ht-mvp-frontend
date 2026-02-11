import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../players/domain/player.dart';
import '../../domain/auction_budget.dart';
import '../../domain/lot_result.dart';

/// Modal bottom sheet showing completed auction lots during a fast auction.
class FastAuctionHistorySheet extends StatelessWidget {
  final List<LotResult> completedResults;
  final Map<int, Player> playersMap;
  final Map<int, AuctionBudget> budgetsMap;
  final int? myRosterId;

  const FastAuctionHistorySheet({
    super.key,
    required this.completedResults,
    required this.playersMap,
    required this.budgetsMap,
    this.myRosterId,
  });

  static void show(
    BuildContext context, {
    required List<LotResult> completedResults,
    required Map<int, Player> playersMap,
    required Map<int, AuctionBudget> budgetsMap,
    int? myRosterId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return FastAuctionHistorySheet(
            completedResults: completedResults,
            playersMap: playersMap,
            budgetsMap: budgetsMap,
            myRosterId: myRosterId,
          )._buildContent(context, scrollController);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);
    // Show most recent first
    final sortedResults = completedResults.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: theme.colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  'Auction History (${completedResults.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: sortedResults.isEmpty
                ? Center(
                    child: Text(
                      'No completed lots yet',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    itemCount: sortedResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = sortedResults[index];
                      return _buildResultRow(context, result, index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, LotResult result, int displayIndex) {
    final theme = Theme.of(context);
    final player = playersMap[result.playerId];
    final playerName = player?.fullName ?? 'Unknown';
    final position = player?.primaryPosition ?? '';
    final isMyWin = !result.isPassed && result.winnerRosterId == myRosterId;
    final winnerName = result.winnerRosterId != null
        ? budgetsMap[result.winnerRosterId]?.username
        : null;

    return Container(
      color: isMyWin ? AppTheme.draftSuccess.withAlpha(15) : null,
      child: ListTile(
        dense: true,
        leading: isMyWin
            ? const Icon(Icons.emoji_events, color: AppTheme.draftSuccess, size: 20)
            : result.isPassed
                ? Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 20)
                : Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
        title: Row(
          children: [
            if (position.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  position,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                playerName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isMyWin ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: result.isPassed
            ? Text(
                'PASS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${result.price ?? 0}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isMyWin ? AppTheme.draftSuccess : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    winnerName ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is not used directly - use FastAuctionHistorySheet.show()
    return const SizedBox.shrink();
  }
}
