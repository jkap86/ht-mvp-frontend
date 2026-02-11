import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_filter_chip.dart';
import '../../data/league_repository.dart';
import '../../domain/league.dart';
import '../../domain/league_filter.dart';

class LeagueFilterSheet extends ConsumerWidget {
  const LeagueFilterSheet({super.key});

  static const _modes = ['redraft', 'dynasty', 'keeper', 'devy'];
  static const _modeLabels = {
    'redraft': 'Redraft',
    'dynasty': 'Dynasty',
    'keeper': 'Keeper',
    'devy': 'Devy',
  };
  static const _scoringTypes = ['PPR', 'Half-PPR', 'Standard'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(myLeaguesProvider.select((s) => s.filters));
    final notifier = ref.read(myLeaguesProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: filters.hasActiveFilters
                        ? () => notifier.clearAllFilters()
                        : null,
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const Divider(),
              // Filter sections
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildSection(
                      context,
                      title: 'League Mode',
                      children: _modes.map((mode) {
                        return AppFilterChip(
                          label: _modeLabels[mode]!,
                          selected: filters.modes.contains(mode),
                          onSelected: () => notifier.toggleModeFilter(mode),
                        );
                      }).toList(),
                    ),
                    _buildSection(
                      context,
                      title: 'Season Status',
                      children: SeasonStatus.values.map((status) {
                        return AppFilterChip(
                          label: status.displayName,
                          selected: filters.seasonStatuses.contains(status),
                          onSelected: () =>
                              notifier.toggleSeasonStatusFilter(status),
                        );
                      }).toList(),
                    ),
                    _buildSection(
                      context,
                      title: 'Scoring',
                      children: _scoringTypes.map((type) {
                        return AppFilterChip(
                          label: type,
                          selected: filters.scoringTypes.contains(type),
                          onSelected: () => notifier.toggleScoringFilter(type),
                        );
                      }).toList(),
                    ),
                    _buildSection(
                      context,
                      title: 'Roster Features',
                      children: RosterFeature.values.map((feature) {
                        return AppFilterChip(
                          label: feature.displayName,
                          selected: filters.rosterFeatures.contains(feature),
                          onSelected: () =>
                              notifier.toggleRosterFeatureFilter(feature),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Done button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: children,
          ),
        ],
      ),
    );
  }
}
