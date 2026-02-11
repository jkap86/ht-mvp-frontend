import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/league_repository.dart';
import '../../domain/league_filter.dart';
import 'league_filter_sheet.dart';

class LeaguesSearchBar extends ConsumerStatefulWidget {
  const LeaguesSearchBar({super.key});

  @override
  ConsumerState<LeaguesSearchBar> createState() => _LeaguesSearchBarState();
}

class _LeaguesSearchBarState extends ConsumerState<LeaguesSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(myLeaguesProvider.select((s) => s.filters));
    final filterCount = filters.activeFilterCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search leagues...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _controller.clear();
                            ref
                                .read(myLeaguesProvider.notifier)
                                .updateSearchQuery('');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onChanged: (value) {
                  ref
                      .read(myLeaguesProvider.notifier)
                      .updateSearchQuery(value);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            child: IconButton(
              icon: Icon(
                Icons.filter_list,
                color: filters.hasActiveFilters
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () => _showFilterSheet(context),
              tooltip: 'Filters',
            ),
          ),
          _buildSortButton(context, filters),
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, LeagueFilterCriteria filters) {
    return PopupMenuButton<LeagueSortField>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort',
      onSelected: (field) {
        ref.read(myLeaguesProvider.notifier).updateSort(field);
      },
      itemBuilder: (context) => LeagueSortField.values.map((field) {
        final isSelected = filters.sortField == field;
        return PopupMenuItem<LeagueSortField>(
          value: field,
          child: Row(
            children: [
              Expanded(child: Text(field.displayName)),
              if (isSelected)
                Icon(
                  filters.sortDirection == SortDirection.ascending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LeagueFilterSheet(),
    );
  }
}
