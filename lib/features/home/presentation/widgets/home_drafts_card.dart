import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';

/// Card showing drafts summary with navigation to drafts page
class HomeDraftsCard extends StatelessWidget {
  final int activeCount;

  const HomeDraftsCard({
    super.key,
    required this.activeCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasActive = activeCount > 0;

    return Card(
      color: hasActive ? colorScheme.errorContainer : null,
      child: InkWell(
        onTap: () => context.go('/drafts'),
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hasActive
                      ? colorScheme.error
                      : colorScheme.primaryContainer,
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Icon(
                  Icons.assignment,
                  size: 24,
                  color: hasActive
                      ? colorScheme.onError
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drafts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasActive ? colorScheme.onErrorContainer : null,
                          ),
                    ),
                    Text(
                      hasActive
                          ? '$activeCount draft${activeCount == 1 ? '' : 's'} in progress'
                          : 'View all your drafts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasActive
                                ? colorScheme.onErrorContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: hasActive
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
