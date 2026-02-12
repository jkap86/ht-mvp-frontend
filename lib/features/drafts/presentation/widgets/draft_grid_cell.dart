import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';
import '../../../../core/theme/semantic_colors.dart';

class DraftGridCell extends StatefulWidget {
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

  @override
  State<DraftGridCell> createState() => _DraftGridCellState();
}

class _DraftGridCellState extends State<DraftGridCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.06), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _highlightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant DraftGridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect when a pick appears (null -> non-null)
    final pickJustAppeared = oldWidget.pick == null && widget.pick != null;
    // Also detect if a different pick replaced (e.g., after undo + re-pick)
    final pickChanged = oldWidget.pick != null &&
        widget.pick != null &&
        oldWidget.pick!.id != widget.pick!.id;

    if (pickJustAppeared || pickChanged) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Whether this pick slot has been traded
  bool get isTraded => widget.pickAsset?.isTraded ?? false;

  /// Get the tooltip text for traded picks
  String? get tradedPickTooltip => widget.pickAsset?.originDescription;

  @override
  Widget build(BuildContext context) {
    if (widget.pick == null) {
      return _buildEmptyCell(context);
    }

    // Wrap filled cell with animated scale + highlight overlay
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animController.isAnimating ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: _buildFilledCell(context),
    );
  }

  Widget _buildEmptyCell(BuildContext context) {
    final theme = Theme.of(context);

    // Theme-aware colors
    final Color borderColor;
    final Color backgroundColor;
    final Color textColor;

    if (widget.isCurrentPick) {
      borderColor = context.htColors.draftAction;
      backgroundColor = context.htColors.draftAction.withAlpha(25);
      textColor = context.htColors.draftAction;
    } else if (isTraded) {
      borderColor = AppTheme.draftWarning.withAlpha(180);
      backgroundColor = AppTheme.draftWarning.withAlpha(20);
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
          width: widget.isCurrentPick ? 2 : 1,
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
                  '#${widget.pickNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (isTraded && widget.pickAsset?.originalUsername != null) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.pickAsset!.originalUsername!,
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
    if (widget.pick!.isPickAsset) {
      return _buildPickAssetFilledCell(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positionColor = getPositionColor(widget.pick!.playerPosition ?? '');

    final cell = AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        // Brief highlight glow that fades out after pick appears
        final highlightAlpha = (_highlightAnimation.value * 80).round();

        return Container(
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
              // Animated highlight glow
              if (highlightAlpha > 0)
                BoxShadow(
                  color: context.htColors.draftAction.withAlpha(highlightAlpha),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.pick!.playerName ?? 'Unknown',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
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
                      widget.pick!.playerPosition ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Theme.of(context).colorScheme.onPrimary : positionColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.pick!.playerTeam ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final pickAssetColor = AppTheme.positionRecFlex;

    // Format the pick asset display
    final season = widget.pick!.pickAssetSeason ?? 0;
    final round = widget.pick!.pickAssetRound ?? 1;
    final originalTeam = widget.pick!.pickAssetOriginalTeam;

    // Display format: "2026 Rd 1" and original team
    final roundLabel = '$season Rd $round';

    final cell = AnimatedBuilder(
      animation: _highlightAnimation,
      builder: (context, child) {
        final highlightAlpha = (_highlightAnimation.value * 80).round();

        return Container(
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
              if (highlightAlpha > 0)
                BoxShadow(
                  color: context.htColors.draftAction.withAlpha(highlightAlpha),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: child,
        );
      },
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
                        color: isDark ? theme.colorScheme.onPrimary : pickAssetColor,
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
