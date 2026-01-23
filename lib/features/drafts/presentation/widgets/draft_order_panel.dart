import 'package:flutter/material.dart';

import '../../domain/draft_order_entry.dart';
import '../../domain/draft_type.dart';

class DraftOrderPanel extends StatelessWidget {
  final List<DraftOrderEntry> draftOrder;
  final int? currentRosterId;
  final int currentRound;
  final DraftType draftType;
  final int? myRosterId;

  const DraftOrderPanel({
    super.key,
    required this.draftOrder,
    required this.currentRosterId,
    required this.currentRound,
    required this.draftType,
    this.myRosterId,
  });

  List<DraftOrderEntry> get _orderedList {
    if (draftOrder.isEmpty) return [];
    final isSnake = draftType == DraftType.snake;
    final isReversed = isSnake && currentRound % 2 == 0;
    return isReversed ? draftOrder.reversed.toList() : draftOrder;
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
              Icon(Icons.format_list_numbered, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Draft Order',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (draftType == DraftType.snake)
                _buildSnakeIndicator(context),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _orderedList.length,
            itemBuilder: (context, index) {
              final entry = _orderedList[index];
              final isCurrentPicker = entry.rosterId == currentRosterId;
              final isMyTeam = entry.rosterId == myRosterId;

              return _DraftOrderTile(
                entry: entry,
                position: index + 1,
                isCurrentPicker: isCurrentPicker,
                isMyTeam: isMyTeam,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSnakeIndicator(BuildContext context) {
    final isReversed = currentRound % 2 == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isReversed ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'R$currentRound',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftOrderTile extends StatelessWidget {
  final DraftOrderEntry entry;
  final int position;
  final bool isCurrentPicker;
  final bool isMyTeam;

  const _DraftOrderTile({
    required this.entry,
    required this.position,
    required this.isCurrentPicker,
    required this.isMyTeam,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isCurrentPicker
            ? Colors.green.shade100
            : isMyTeam
                ? Colors.blue.shade50
                : null,
        border: isCurrentPicker
            ? Border(
                left: BorderSide(color: Colors.green, width: 4),
              )
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: isCurrentPicker
              ? Colors.green
              : isMyTeam
                  ? theme.colorScheme.primary
                  : Colors.grey.shade300,
          child: Text(
            '$position',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCurrentPicker || isMyTeam ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.username,
                style: TextStyle(
                  fontWeight: isCurrentPicker || isMyTeam ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMyTeam && !isCurrentPicker)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: isCurrentPicker
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ON THE CLOCK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
