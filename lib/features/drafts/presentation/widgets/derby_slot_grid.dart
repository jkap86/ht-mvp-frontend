import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft_order_entry.dart';
import '../providers/draft_room_provider.dart';

/// Grid widget for displaying and selecting draft slots during derby phase
class DerbySlotGrid extends ConsumerWidget {
  final DraftRoomKey draftKey;

  const DerbySlotGrid({
    super.key,
    required this.draftKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftRoomProvider(draftKey));
    final derbyState = state.derbyState;
    final draftOrder = state.draftOrder;
    final myRosterId = state.myRosterId;
    final isMyTurn = state.isMyDerbyTurn;
    final isSubmitting = state.isDerbySubmitting;

    if (derbyState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final teamCount = derbyState.turnOrder.length;
    final availableSlots = derbyState.availableSlots;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context, teamCount),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: teamCount,
      itemBuilder: (context, index) {
        final slotNumber = index + 1;
        final claimedByRosterId = derbyState.claimedSlots[slotNumber];
        final isAvailable = availableSlots.contains(slotNumber);
        final isClaimed = claimedByRosterId != null;
        final isMySlot = claimedByRosterId == myRosterId;

        // Find team name for claimed slot
        String? claimedByTeamName;
        if (isClaimed) {
          claimedByTeamName = _getTeamName(draftOrder, claimedByRosterId);
        }

        return DerbySlotCard(
          slotNumber: slotNumber,
          isAvailable: isAvailable,
          isClaimed: isClaimed,
          isMySlot: isMySlot,
          claimedByTeamName: claimedByTeamName,
          canSelect: isMyTurn && isAvailable && !isSubmitting,
          isSubmitting: isSubmitting,
          onSelect: () {
            ref.read(draftRoomProvider(draftKey).notifier).pickDerbySlot(slotNumber);
          },
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context, int teamCount) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  String? _getTeamName(List<DraftOrderEntry> draftOrder, int rosterId) {
    final entry = draftOrder.where((e) => e.rosterId == rosterId).firstOrNull;
    return entry?.username;
  }
}

/// Individual slot card in the derby grid
class DerbySlotCard extends StatelessWidget {
  final int slotNumber;
  final bool isAvailable;
  final bool isClaimed;
  final bool isMySlot;
  final String? claimedByTeamName;
  final bool canSelect;
  final bool isSubmitting;
  final VoidCallback onSelect;

  const DerbySlotCard({
    super.key,
    required this.slotNumber,
    required this.isAvailable,
    required this.isClaimed,
    required this.isMySlot,
    this.claimedByTeamName,
    required this.canSelect,
    required this.isSubmitting,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isMySlot) {
      // User's claimed slot - highlight in primary color
      backgroundColor = colorScheme.primaryContainer;
      borderColor = colorScheme.primary;
      textColor = colorScheme.onPrimaryContainer;
    } else if (isClaimed) {
      // Other team's claimed slot - muted
      backgroundColor = colorScheme.surfaceContainerHighest;
      borderColor = colorScheme.outline.withValues(alpha: 0.3);
      textColor = colorScheme.onSurfaceVariant;
    } else if (canSelect) {
      // Available and can select - interactive
      backgroundColor = colorScheme.surface;
      borderColor = colorScheme.primary;
      textColor = colorScheme.onSurface;
    } else {
      // Available but not user's turn
      backgroundColor = colorScheme.surface;
      borderColor = colorScheme.outlineVariant;
      textColor = colorScheme.onSurface;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: canSelect ? onSelect : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#$slotNumber',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isClaimed && claimedByTeamName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        claimedByTeamName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              if (isMySlot)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
              if (isSubmitting && canSelect)
                const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
