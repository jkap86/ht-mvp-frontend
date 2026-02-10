import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/draft_pick_asset.dart';

/// Widget to display a draftable pick asset in the draft room.
/// Has distinct styling from player tiles to clearly indicate it's a draft pick.
class PickAssetTile extends StatelessWidget {
  final DraftPickAsset pickAsset;
  final bool isMyTurn;
  final bool isDraftInProgress;
  final VoidCallback? onDraft;

  const PickAssetTile({
    super.key,
    required this.pickAsset,
    required this.isMyTurn,
    required this.isDraftInProgress,
    this.onDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: colorScheme.secondaryContainer.withAlpha(180),
      child: ListTile(
        leading: _buildLeadingIcon(colorScheme),
        title: Text(
          pickAsset.displayName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: _buildSubtitle(theme),
        trailing: _buildTrailing(colorScheme),
      ),
    );
  }

  Widget _buildLeadingIcon(ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.how_to_vote_outlined,
            color: colorScheme.onSecondary,
            size: 20,
          ),
          Text(
            '${pickAsset.round}',
            style: TextStyle(
              color: colorScheme.onSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    if (pickAsset.isTraded) {
      return Text(
        pickAsset.originDescription ?? 'Traded pick',
        style: theme.textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Text(
      'Rookie Draft Pick',
      style: theme.textTheme.bodySmall,
    );
  }

  Widget? _buildTrailing(ColorScheme colorScheme) {
    if (!isDraftInProgress) {
      // Before draft starts - show info icon
      return Icon(
        Icons.info_outline,
        color: colorScheme.onSurfaceVariant,
      );
    }

    // During draft - show draft button
    return ElevatedButton(
      onPressed: isMyTurn ? onDraft : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      child: const Text('Draft'),
    );
  }
}

/// Header for the pick assets section in the drawer
class PickAssetsSectionHeader extends StatelessWidget {
  final int count;

  const PickAssetsSectionHeader({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.secondaryContainer.withAlpha(100),
      child: Row(
        children: [
          Icon(
            Icons.how_to_vote,
            size: 18,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Rookie Draft Picks',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withAlpha(50),
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Text(
              '$count available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
