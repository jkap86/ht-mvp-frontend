import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A subtle indicator that shows when data may be outdated.
///
/// Usage:
/// ```dart
/// StaleDataIndicator(
///   lastUpdated: state.lastUpdated,
///   staleThreshold: Duration(minutes: 5),
///   onRefresh: () => ref.read(myProvider.notifier).loadData(),
/// )
/// ```
class StaleDataIndicator extends StatelessWidget {
  final DateTime? lastUpdated;
  final Duration staleThreshold;
  final VoidCallback? onRefresh;

  const StaleDataIndicator({
    super.key,
    required this.lastUpdated,
    this.staleThreshold = const Duration(minutes: 5),
    this.onRefresh,
  });

  bool get isStale {
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!) > staleThreshold;
  }

  String get _timeAgoText {
    if (lastUpdated == null) return '';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes == 1) return 'Updated 1 minute ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} minutes ago';
    if (diff.inHours == 1) return 'Updated 1 hour ago';
    return 'Updated ${diff.inHours} hours ago';
  }

  @override
  Widget build(BuildContext context) {
    if (!isStale) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            _timeAgoText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Icon(
                Icons.refresh,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A banner that shows when data may be outdated.
/// Suitable for showing at the top of a list or screen.
class StaleDataBanner extends StatelessWidget {
  final DateTime? lastUpdated;
  final Duration staleThreshold;
  final VoidCallback? onRefresh;

  const StaleDataBanner({
    super.key,
    required this.lastUpdated,
    this.staleThreshold = const Duration(minutes: 5),
    this.onRefresh,
  });

  bool get isStale {
    if (lastUpdated == null) return false;
    return DateTime.now().difference(lastUpdated!) > staleThreshold;
  }

  @override
  Widget build(BuildContext context) {
    if (!isStale) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data may be outdated. Pull to refresh.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onRefresh != null)
            TextButton(
              onPressed: onRefresh,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Refresh'),
            ),
        ],
      ),
    );
  }
}
