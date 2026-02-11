import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/draft_status.dart';
import '../domain/draft_type.dart';
import 'providers/drafts_list_provider.dart';

class DraftsListScreen extends ConsumerWidget {
  const DraftsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Drafts'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(draftsListProvider.notifier).loadDrafts(),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DraftsListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading drafts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.drafts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No drafts yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Drafts will appear here when created',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    // Build items list for ListView.builder
    final items = <Widget>[];

    // In Progress section
    if (state.inProgressDrafts.isNotEmpty) {
      items.add(_SectionHeader(
        title: 'In Progress',
        icon: Icons.play_circle_filled,
        color: Theme.of(context).colorScheme.error,
      ));
      items.add(const SizedBox(height: 8));
      for (final d in state.inProgressDrafts) {
        items.add(_DraftCard(draft: d));
      }
      items.add(const SizedBox(height: 24));
    }

    // Upcoming section
    if (state.upcomingDrafts.isNotEmpty) {
      items.add(_SectionHeader(
        title: 'Upcoming',
        icon: Icons.schedule,
        color: Theme.of(context).colorScheme.primary,
      ));
      items.add(const SizedBox(height: 8));
      for (final d in state.upcomingDrafts) {
        items.add(_DraftCard(draft: d));
      }
      items.add(const SizedBox(height: 24));
    }

    // Completed section
    if (state.completedDrafts.isNotEmpty) {
      items.add(_SectionHeader(
        title: 'Completed',
        icon: Icons.check_circle,
        color: Theme.of(context).colorScheme.outline,
      ));
      items.add(const SizedBox(height: 8));
      for (final d in state.completedDrafts) {
        items.add(_DraftCard(draft: d));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _DraftCard extends StatelessWidget {
  final DraftsListItem draft;

  const _DraftCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = draft.isInProgress || draft.isPaused;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isActive ? colorScheme.errorContainer : null,
      child: InkWell(
        onTap: () {
          context.push('/leagues/${draft.leagueId}/drafts/${draft.draft.id}');
        },
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor(context, draft.draft.status),
                  borderRadius: AppSpacing.badgeRadius,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.leagueName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isActive ? colorScheme.onErrorContainer : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${draft.leagueSeason}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? colorScheme.onErrorContainer.withOpacity(0.8)
                                    : colorScheme.outline,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isActive
                                ? colorScheme.onErrorContainer.withOpacity(0.8)
                                : colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getDraftTypeLabel(draft.draft.draftType),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isActive
                                    ? colorScheme.onErrorContainer.withOpacity(0.8)
                                    : colorScheme.outline,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            color: isActive
                                ? colorScheme.onErrorContainer.withOpacity(0.8)
                                : colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusLabel(draft.draft),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: isActive ? FontWeight.bold : null,
                                color: isActive
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                    // Show scheduled start time for upcoming drafts
                    if (draft.isNotStarted && draft.draft.scheduledStart != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Starts: ${_formatScheduledTime(draft.draft.scheduledStart!.toLocal())}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right,
                color: isActive
                    ? colorScheme.onErrorContainer
                    : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, DraftStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case DraftStatus.inProgress:
        return colorScheme.error;
      case DraftStatus.paused:
        return colorScheme.tertiary;
      case DraftStatus.notStarted:
        return colorScheme.primary;
      case DraftStatus.completed:
        return colorScheme.outline;
    }
  }

  String _getDraftTypeLabel(DraftType type) {
    switch (type) {
      case DraftType.snake:
        return 'Snake Draft';
      case DraftType.linear:
        return 'Linear Draft';
      case DraftType.auction:
        return 'Auction Draft';
    }
  }

  String _getStatusLabel(draft) {
    switch (draft.status) {
      case DraftStatus.inProgress:
        final round = draft.currentRound ?? 1;
        final rounds = draft.rounds;
        return 'Round $round/$rounds';
      case DraftStatus.paused:
        return 'Paused';
      case DraftStatus.notStarted:
        return 'Not started';
      case DraftStatus.completed:
        return 'Completed';
      default:
        return '';
    }
  }

  String _formatScheduledTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $amPm';
  }
}
