import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class LineupLockedBanner extends StatelessWidget {
  final String message;

  const LineupLockedBanner({
    super.key,
    this.message = 'Lineup is locked for this week. Games have started.',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.15),
        borderRadius: AppSpacing.buttonRadius,
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        children: [
          Icon(Icons.lock, color: colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}
