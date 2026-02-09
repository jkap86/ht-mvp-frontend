import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../drafts/data/draft_pick_asset_repository.dart';
import '../../../drafts/domain/draft_pick_asset.dart';

/// Provider for roster pick assets used in trade pick selection
final tradeRosterPicksProvider =
    FutureProvider.family<List<DraftPickAsset>, int>(
  (ref, rosterId) async {
    final repo = ref.watch(draftPickAssetRepositoryProvider);
    final picks = await repo.getRosterPickAssets(rosterId);
    // Sort by value (earlier picks first)
    picks.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return picks;
  },
);

/// Widget for selecting draft pick assets from a roster for trading
class DraftPickSelectorWidget extends ConsumerWidget {
  final int rosterId;
  final Set<int> selectedPickAssetIds;
  final void Function(Set<int>) onSelectionChanged;
  final String title;
  final bool disabled;

  const DraftPickSelectorWidget({
    super.key,
    required this.rosterId,
    required this.selectedPickAssetIds,
    required this.onSelectionChanged,
    required this.title,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picksAsync = ref.watch(tradeRosterPicksProvider(rosterId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.sports_football,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Draft Picks',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
        picksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Error loading picks',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
          data: (picks) => _buildPickList(context, picks),
        ),
      ],
    );
  }

  Widget _buildPickList(BuildContext context, List<DraftPickAsset> picks) {
    if (picks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Center(
          child: Text(
            'No draft picks available',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    // Group picks by season
    final picksBySeason = <int, List<DraftPickAsset>>{};
    for (final pick in picks) {
      picksBySeason.putIfAbsent(pick.season, () => []).add(pick);
    }
    final sortedSeasons = picksBySeason.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < sortedSeasons.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _buildSeasonSection(
              context,
              sortedSeasons[i],
              picksBySeason[sortedSeasons[i]]!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeasonSection(
    BuildContext context,
    int season,
    List<DraftPickAsset> picks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.grey.shade100,
          child: Text(
            '$season Draft',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
          ),
        ),
        ...picks.map((pick) => _buildPickRow(context, pick)),
      ],
    );
  }

  Widget _buildPickRow(BuildContext context, DraftPickAsset pick) {
    final isSelected = selectedPickAssetIds.contains(pick.id);

    return InkWell(
      onTap: disabled
          ? null
          : () {
              final newSelection = Set<int>.from(selectedPickAssetIds);
              if (isSelected) {
                newSelection.remove(pick.id);
              } else {
                newSelection.add(pick.id);
              }
              onSelectionChanged(newSelection);
            },
      child: Container(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'R${pick.round}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pick.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                  if (pick.originDescription != null)
                    Text(
                      pick.originDescription!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
