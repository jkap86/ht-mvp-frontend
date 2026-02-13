import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/draft_activity_event.dart';
import '../providers/draft_room_provider.dart';

/// Compact activity feed showing recent draft events.
class DraftActivityFeed extends ConsumerWidget {
  final DraftRoomKey providerKey;

  const DraftActivityFeed({super.key, required this.providerKey});

  static IconData _iconForType(DraftActivityType type) {
    return switch (type) {
      DraftActivityType.pickMade => Icons.sports_football,
      DraftActivityType.autoPick => Icons.smart_toy,
      DraftActivityType.timerExpired => Icons.timer_off,
      DraftActivityType.draftStarted => Icons.play_arrow,
      DraftActivityType.draftPaused => Icons.pause,
      DraftActivityType.draftResumed => Icons.play_arrow,
      DraftActivityType.draftCompleted => Icons.flag,
      DraftActivityType.pickUndone => Icons.undo,
      DraftActivityType.autodraftToggled => Icons.autorenew,
      DraftActivityType.derbySlotPicked => Icons.pin_drop,
      DraftActivityType.derbyTimeout => Icons.timer_off,
      DraftActivityType.derbyCompleted => Icons.check_circle,
      DraftActivityType.nominationTimeout => Icons.timer_off,
      DraftActivityType.autoNominated => Icons.smart_toy,
    };
  }

  static String _relativeTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityFeed = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.activityFeed),
    );
    final colorScheme = Theme.of(context).colorScheme;

    if (activityFeed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No activity yet',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: activityFeed.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final event = activityFeed[index];
        return _ActivityRow(
          icon: _iconForType(event.type),
          message: event.message,
          timestamp: _relativeTimestamp(event.timestamp),
          colorScheme: colorScheme,
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String message;
  final String timestamp;
  final ColorScheme colorScheme;

  const _ActivityRow({
    required this.icon,
    required this.message,
    required this.timestamp,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          timestamp,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
