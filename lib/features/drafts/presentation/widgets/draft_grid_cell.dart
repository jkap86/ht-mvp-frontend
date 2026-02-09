import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';
import '../../../../core/theme/semantic_colors.dart';

class DraftGridCell extends StatelessWidget {
  final DraftPick? pick;
  final bool isCurrentPick;
  final int pickNumber;
  final DraftPickAsset? pickAsset;

  const DraftGridCell({
    super.key,
    this.pick,
    this.isCurrentPick = false,
    required this.pickNumber,
    this.pickAsset,
  });

  /// Whether this pick slot has been traded
  bool get isTraded => pickAsset?.isTraded ?? false;

  /// Get the tooltip text for traded picks
  String? get tradedPickTooltip => pickAsset?.originDescription;

  @override
  Widget build(BuildContext context) {
    if (pick == null) {
      return _buildEmptyCell(context);
    }

    return _buildFilledCell(context);
  }

  Widget _buildEmptyCell(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Theme-aware colors
    final Color borderColor;
    final Color backgroundColor;
    final Color textColor;

    if (isCurrentPick) {
      borderColor = AppTheme.draftActionPrimary;
      backgroundColor = AppTheme.draftActionPrimary.withAlpha(isDark ? 30 : 20);
      textColor = AppTheme.draftActionPrimary;
    } else if (isTraded) {
      borderColor = AppTheme.draftWarning.withAlpha(180);
      backgroundColor = AppTheme.draftWarning.withAlpha(isDark ? 25 : 15);
      textColor = AppTheme.draftWarning;
    } else {
      borderColor = theme.colorScheme.outlineVariant;
      backgroundColor = theme.colorScheme.surfaceContainerLowest;
      textColor = theme.colorScheme.onSurfaceVariant.withAlpha(150);
    }

    final cell = Container(
      width: 90,
      height: 56,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: isCurrentPick ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(6),
        color: backgroundColor,
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$pickNumber',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (isTraded && pickAsset?.originalUsername != null) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      pickAsset!.originalUsername!,
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.draftWarning,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Traded indicator icon
          if (isTraded)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.swap_horiz,
                size: 12,
                color: AppTheme.draftWarning,
              ),
            ),
        ],
      ),
    );

    // Wrap with tooltip for traded picks
    if (isTraded && tradedPickTooltip != null) {
      return Tooltip(
        message: tradedPickTooltip!,
        child: cell,
      );
    }

    return cell;
  }

  Widget _buildFilledCell(BuildContext context) {
    // Check if this is a pick asset selection (vet draft selecting a rookie pick)
    if (pick!.isPickAsset) {
      return _buildPickAssetFilledCell(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positionColor = getPositionColor(pick!.playerPosition ?? '');

    final cell = Container(
      width: 90,
      height: 56,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isTraded
              ? AppTheme.draftWarning.withAlpha(180)
              : positionColor.withAlpha(isDark ? 150 : 120),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
        color: positionColor.withAlpha(isDark ? 40 : 30),
        boxShadow: [
          BoxShadow(
            color: positionColor.withAlpha(isDark ? 20 : 15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pick!.playerName ?? 'Unknown',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: positionColor.withAlpha(isDark ? 80 : 60),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      pick!.playerPosition ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : positionColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      pick!.playerTeam ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Traded indicator icon for filled cells
          if (isTraded)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.swap_horiz,
                size: 11,
                color: AppTheme.draftWarning,
              ),
            ),
        ],
      ),
    );

    // Wrap with tooltip for traded picks
    if (isTraded && tradedPickTooltip != null) {
      return Tooltip(
        message: tradedPickTooltip!,
        child: cell,
      );
    }

    return cell;
  }

  /// Builds a filled cell for pick asset selections (vet drafts selecting rookie draft picks)
  Widget _buildPickAssetFilledCell(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use a distinct teal/cyan color for pick assets
    const pickAssetColor = Color(0xFF00ACC1); // Cyan 600

    // Format the pick asset display
    final season = pick!.pickAssetSeason ?? 0;
    final round = pick!.pickAssetRound ?? 1;
    final originalTeam = pick!.pickAssetOriginalTeam;

    // Display format: "2026 Rd 1" and original team
    final roundLabel = '$season Rd $round';

    final cell = Container(
      width: 90,
      height: 56,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isTraded
              ? AppTheme.draftWarning.withAlpha(180)
              : pickAssetColor.withAlpha(isDark ? 150 : 120),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
        color: pickAssetColor.withAlpha(isDark ? 40 : 30),
        boxShadow: [
          BoxShadow(
            color: pickAssetColor.withAlpha(isDark ? 20 : 15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_football,
                    size: 12,
                    color: pickAssetColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      roundLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: pickAssetColor.withAlpha(isDark ? 80 : 60),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PICK',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : pickAssetColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (originalTeam != null)
                    Expanded(
                      child: Text(
                        originalTeam,
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Traded indicator icon for filled cells
          if (isTraded)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.swap_horiz,
                size: 11,
                color: AppTheme.draftWarning,
              ),
            ),
        ],
      ),
    );

    // Wrap with tooltip for traded picks
    if (isTraded && tradedPickTooltip != null) {
      return Tooltip(
        message: tradedPickTooltip!,
        child: cell,
      );
    }

    return cell;
  }
}
