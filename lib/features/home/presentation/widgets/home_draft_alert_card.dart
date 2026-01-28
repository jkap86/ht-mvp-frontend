import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_dashboard_provider.dart';

/// Card showing upcoming or active drafts
class HomeDraftAlertCard extends StatelessWidget {
  final List<DashboardDraft> drafts;

  const HomeDraftAlertCard({
    super.key,
    required this.drafts,
  });

  @override
  Widget build(BuildContext context) {
    if (drafts.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Separate active from ready-to-start
    final activeDrafts = drafts.where((d) => d.isInProgress).toList();
    final upcomingDrafts = drafts.where((d) => d.isReadyToStart && !d.isInProgress).toList();

    return Card(
      color: activeDrafts.isNotEmpty
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  activeDrafts.isNotEmpty ? Icons.timer : Icons.event,
                  color: activeDrafts.isNotEmpty
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  activeDrafts.isNotEmpty ? 'Draft In Progress!' : 'Upcoming Drafts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: activeDrafts.isNotEmpty
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Show active drafts first
          ...activeDrafts.map((d) => _DraftItem(
                draft: d,
                isActive: true,
              )),
          // Then upcoming drafts
          ...upcomingDrafts.map((d) => _DraftItem(
                draft: d,
                isActive: false,
              )),
        ],
      ),
    );
  }
}

class _DraftItem extends StatelessWidget {
  final DashboardDraft draft;
  final bool isActive;

  const _DraftItem({
    required this.draft,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        context.go('/leagues/${draft.leagueId}/drafts/${draft.draft.id}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    draft.leagueName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  if (isActive)
                    Text(
                      'Draft is live!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    )
                  else
                    Text(
                      'Ready to start',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {
                context.go('/leagues/${draft.leagueId}/drafts/${draft.draft.id}');
              },
              style: isActive
                  ? FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    )
                  : null,
              child: Text(isActive ? 'Enter Draft' : 'View'),
            ),
          ],
        ),
      ),
    );
  }
}
