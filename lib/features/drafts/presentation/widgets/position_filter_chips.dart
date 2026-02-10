import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';

class PositionFilterChips extends StatelessWidget {
  final String? selectedPosition;
  final ValueChanged<String?> onPositionSelected;

  const PositionFilterChips({
    super.key,
    required this.selectedPosition,
    required this.onPositionSelected,
  });

  static const List<String> positions = ['ALL', 'QB', 'RB', 'WR', 'TE', 'K', 'DEF'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: positions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final position = positions[index];
          final isSelected = (position == 'ALL' && selectedPosition == null) ||
              position == selectedPosition;
          final color = position == 'ALL'
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : getPositionColor(position);

          return FilterChip(
            label: Text(
              position,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            selected: isSelected,
            onSelected: (_) {
              onPositionSelected(position == 'ALL' ? null : position);
            },
            backgroundColor: color.withValues(alpha: 0.1),
            selectedColor: color,
            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              side: BorderSide(color: color, width: 1.5),
            ),
          );
        },
      ),
    );
  }
}
