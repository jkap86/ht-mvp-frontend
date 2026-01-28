import 'package:flutter/material.dart';

import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';
import '../utils/position_colors.dart';

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
    // Determine colors based on traded status
    final borderColor = isCurrentPick
        ? Colors.amber
        : isTraded
            ? Colors.orange.shade300
            : Colors.grey.shade300;
    final backgroundColor = isCurrentPick
        ? Colors.amber.shade50
        : isTraded
            ? Colors.orange.shade50
            : Colors.grey.shade50;

    final cell = Container(
      width: 80,
      height: 52,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: isCurrentPick ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
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
                    fontSize: 10,
                    color: isTraded ? Colors.orange.shade700 : Colors.grey.shade400,
                  ),
                ),
                if (isTraded && pickAsset?.originalUsername != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    pickAsset!.originalUsername!,
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.orange.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Traded indicator icon
          if (isTraded)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.swap_horiz,
                size: 12,
                color: Colors.orange.shade600,
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
    final positionColor = getPositionColor(pick!.playerPosition ?? '');

    final cell = Container(
      width: 80,
      height: 52,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isTraded
              ? Colors.orange.withValues(alpha: 0.7)
              : positionColor.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(4),
        color: positionColor.withValues(alpha: 0.15),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pick!.playerName ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: positionColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      pick!.playerPosition ?? '',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: positionColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      pick!.playerTeam ?? '',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.grey.shade600,
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
                size: 10,
                color: Colors.orange.shade600,
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
