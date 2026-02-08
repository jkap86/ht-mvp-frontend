import 'package:flutter/material.dart';

import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../players/domain/player.dart';

class FreeAgentCard extends StatelessWidget {
  final Player player;
  final bool isAdding;
  final bool isOnWaiverWire;
  final VoidCallback onAdd;

  const FreeAgentCard({
    super.key,
    required this.player,
    required this.isAdding,
    this.isOnWaiverWire = false,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positionColor = getPositionColor(player.position);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            // Position badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: positionColor,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  player.position ?? '?',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.fullName,
                          style: AppTypography.title.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.injuryStatus != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: getInjuryColor(player.injuryStatus),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            player.injuryStatus!,
                            style: AppTypography.labelBold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    player.team ?? 'Free Agent',
                    style: AppTypography.body.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Add/Claim button
            const SizedBox(width: AppSpacing.sm),
            if (isAdding)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (isOnWaiverWire)
              // Show "Claim" chip for waiver wire players
              ActionChip(
                avatar: const Icon(Icons.access_time, size: 18),
                label: const Text('Claim'),
                onPressed: onAdd,
                backgroundColor: SelectionColors.warning.withAlpha(25),
                side: BorderSide(color: SelectionColors.warning.withAlpha(75)),
              )
            else
              IconButton(
                icon: const Icon(Icons.add_circle),
                color: theme.primaryColor,
                onPressed: onAdd,
              ),
          ],
        ),
      ),
    );
  }
}
