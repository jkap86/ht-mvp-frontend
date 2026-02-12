import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency.dart';
import '../../../../core/widgets/data_freshness_bar.dart';
import '../../domain/draft_activity_event.dart';
import '../providers/draft_room_provider.dart';
import '../widgets/derby_slot_grid.dart';
import '../widgets/derby_turn_indicator.dart';

/// Screen displayed during the derby phase (draft order selection)
class DerbyScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final int draftId;

  const DerbyScreen({
    super.key,
    required this.leagueId,
    required this.draftId,
  });

  @override
  ConsumerState<DerbyScreen> createState() => _DerbyScreenState();
}

class _DerbyScreenState extends ConsumerState<DerbyScreen> {
  Timer? _refreshTimer;

  DraftRoomKey get _draftKey => (leagueId: widget.leagueId, draftId: widget.draftId);

  @override
  void initState() {
    super.initState();
    // Tick every 30s to update the "last updated" relative time text
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      final isCommissioner = state.isCommissioner;
      final isDerbySubmitting = state.isDerbySubmitting;

      return Scaffold(
        appBar: AppBar(title: const Text('Draft Order Selection')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shuffle,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Derby Draft Order',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Teams will pick their draft position in random order',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (isCommissioner)
                ElevatedButton.icon(
                  onPressed: isDerbySubmitting
                      ? null
                      : () {
                          final key = newIdempotencyKey();
                          ref.read(draftRoomProvider(_draftKey).notifier).startDerby(idempotencyKey: key);
                        },
                  icon: isDerbySubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(isDerbySubmitting ? 'Starting...' : 'Start Derby'),
                )
              else
                Text(
                  'Waiting for commissioner to start...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final claimedCount = derbyState.claimedSlots.length;
    final totalTeams = derbyState.turnOrder.length;
    // Filter activity feed for derby events only
    final derbyEvents = state.activityFeed.where((e) =>
      e.type == DraftActivityType.derbySlotPicked ||
      e.type == DraftActivityType.derbyTimeout ||
      e.type == DraftActivityType.derbyCompleted
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Draft Order Selection'),
        actions: [
          // Phase badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pin_drop, size: 14,
                      color: Theme.of(context).colorScheme.onTertiaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Picking Slots',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
          // Freshness indicator
          DataFreshnessBar(
            lastUpdatedDisplay: state.lastUpdatedDisplay,
            isStale: state.isStale,
            label: 'Derby Phase',
            labelIcon: Icons.shuffle,
          ),
          // Turn indicator and timer
          Padding(
            padding: const EdgeInsets.all(16),
            child: DerbyTurnIndicator(draftKey: _draftKey),
          ),
          // Timed picks policy notice
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select your preferred draft position. Lower numbers pick earlier in round 1.\nTimed picks will be auto-handled.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Slot grid
          Expanded(
            flex: 3,
            child: DerbySlotGrid(draftKey: _draftKey),
          ),
          // Derby event log
          if (derbyEvents.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      reverse: false,
                      shrinkWrap: true,
                      itemCount: derbyEvents.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final event = derbyEvents[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                event.type == DraftActivityType.derbySlotPicked
                                    ? Icons.pin_drop
                                    : event.type == DraftActivityType.derbyTimeout
                                        ? Icons.timer_off
                                        : Icons.check_circle,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.message,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
