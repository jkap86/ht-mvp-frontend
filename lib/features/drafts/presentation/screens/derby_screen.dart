import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_room_provider.dart';
import '../widgets/derby_slot_grid.dart';
import '../widgets/derby_turn_indicator.dart';

/// Screen displayed during the derby phase (draft order selection)
class DerbyScreen extends ConsumerWidget {
  final int leagueId;
  final int draftId;

  const DerbyScreen({
    super.key,
    required this.leagueId,
    required this.draftId,
  });

  DraftRoomKey get _draftKey => (leagueId: leagueId, draftId: draftId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftRoomProvider(_draftKey));
    final derbyState = state.derbyState;
    final isLoading = state.isLoading;
    final error = state.error;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Order Selection')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(draftRoomProvider(_draftKey).notifier).loadData();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (derbyState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Order Selection')),
        body: const Center(
          child: Text('Waiting for derby to start...'),
        ),
      );
    }

    final claimedCount = derbyState.claimedSlots.length;
    final totalTeams = derbyState.turnOrder.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Order Selection'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '$claimedCount/$totalTeams picked',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Turn indicator and timer
          Padding(
            padding: const EdgeInsets.all(16),
            child: DerbyTurnIndicator(draftKey: _draftKey),
          ),
          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select your preferred draft position. Lower numbers pick earlier in round 1.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          // Slot grid
          Expanded(
            child: DerbySlotGrid(draftKey: _draftKey),
          ),
        ],
      ),
    );
  }
}
