import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_queue_provider.dart';

class DraftQueueWidget extends ConsumerWidget {
  final int leagueId;
  final int draftId;
  final Set<int> draftedPlayerIds;
  final Set<int> draftedPickAssetIds;

  const DraftQueueWidget({
    super.key,
    required this.leagueId,
    required this.draftId,
    required this.draftedPlayerIds,
    this.draftedPickAssetIds = const {},
  });

  DraftQueueKey get _providerKey => (leagueId: leagueId, draftId: draftId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftQueueProvider(_providerKey));

    if (state.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Filter out already drafted items from queue display
    final availableQueue = state.queue.where((e) {
      if (e.isPlayer) {
        return !draftedPlayerIds.contains(e.playerId);
      } else if (e.isPickAsset) {
        return !draftedPickAssetIds.contains(e.pickAssetId);
      }
      return false;
    }).toList();

    if (availableQueue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.queue, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'My Queue (0)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.queue, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'My Queue (${availableQueue.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
          SizedBox(
            height: 80,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: availableQueue.length,
              onReorder: (oldIndex, newIndex) {
                // Adjust for the removal behavior
                if (newIndex > oldIndex) newIndex--;

                // Bounds checking to prevent crashes
                final entryIds = availableQueue.map((e) => e.id).toList();
                if (entryIds.isEmpty) return;
                if (newIndex < 0) newIndex = 0;
                if (newIndex >= entryIds.length) newIndex = entryIds.length - 1;
                if (oldIndex == newIndex) return;

                final item = entryIds.removeAt(oldIndex);
                entryIds.insert(newIndex, item);
                ref.read(draftQueueProvider(_providerKey).notifier).reorderQueueByEntryIds(entryIds);
              },
              itemBuilder: (context, index) {
                final entry = availableQueue[index];
                if (entry.isPlayer) {
                  return _QueuePlayerCard(
                    key: ValueKey('player-${entry.playerId}'),
                    entry: entry,
                    position: index + 1,
                    onRemove: () {
                      ref.read(draftQueueProvider(_providerKey).notifier)
                          .removeFromQueue(entry.playerId!);
                    },
                  );
                } else {
                  return _QueuePickAssetCard(
                    key: ValueKey('pick-${entry.pickAssetId}'),
                    entry: entry,
                    position: index + 1,
                    onRemove: () {
                      ref.read(draftQueueProvider(_providerKey).notifier)
                          .removePickAssetFromQueue(entry.pickAssetId!);
                    },
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}

class _QueuePlayerCard extends StatelessWidget {
  final QueueEntry entry;
  final int position;
  final VoidCallback onRemove;

  const _QueuePlayerCard({
    super.key,
    required this.entry,
    required this.position,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.grey[600],
                  child: Text(
                    '$position',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Text(
                  entry.playerName ?? 'Unknown',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Text(
              '${entry.playerPosition ?? ''} - ${entry.playerTeam ?? ''}',
              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuePickAssetCard extends StatelessWidget {
  final QueueEntry entry;
  final int position;
  final VoidCallback onRemove;

  const _QueuePickAssetCard({
    super.key,
    required this.entry,
    required this.position,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      color: Colors.amber[50],
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: Colors.amber[700],
                  child: Text(
                    '$position',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.how_to_vote_outlined, size: 16, color: Colors.amber[700]),
                    const SizedBox(height: 2),
                    Text(
                      entry.pickAssetDisplayName ?? 'Pick',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            Text(
              '${entry.pickAssetRound ?? '?'}',
              style: TextStyle(fontSize: 9, color: Colors.amber[800]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
