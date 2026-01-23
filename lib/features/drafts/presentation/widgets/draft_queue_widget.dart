import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_queue_provider.dart';

class DraftQueueWidget extends ConsumerWidget {
  final int leagueId;
  final int draftId;
  final Set<int> draftedPlayerIds;

  const DraftQueueWidget({
    super.key,
    required this.leagueId,
    required this.draftId,
    required this.draftedPlayerIds,
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

    // Filter out already drafted players from queue display
    final availableQueue = state.queue
        .where((e) => !draftedPlayerIds.contains(e.playerId))
        .toList();

    if (availableQueue.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Your queue is empty',
              style: TextStyle(color: Colors.grey),
            ),
            Text(
              'Add players to auto-draft from when the timer runs out',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.queue, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'My Queue (${availableQueue.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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
                final playerIds = availableQueue.map((e) => e.playerId).toList();
                if (playerIds.isEmpty) return;
                if (newIndex < 0) newIndex = 0;
                if (newIndex >= playerIds.length) newIndex = playerIds.length - 1;
                if (oldIndex == newIndex) return;

                final item = playerIds.removeAt(oldIndex);
                playerIds.insert(newIndex, item);
                ref.read(draftQueueProvider(_providerKey).notifier).reorderQueue(playerIds);
              },
              itemBuilder: (context, index) {
                final entry = availableQueue[index];
                return _QueuePlayerCard(
                  key: ValueKey(entry.playerId),
                  entry: entry,
                  position: index + 1,
                  onRemove: () {
                    ref.read(draftQueueProvider(_providerKey).notifier)
                        .removeFromQueue(entry.playerId);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
                  backgroundColor: Colors.blue,
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
