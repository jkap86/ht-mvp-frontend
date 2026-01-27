import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../drafts/domain/draft_status.dart';
import '../../domain/league.dart';

class LeagueDraftsTab extends StatelessWidget {
  final int leagueId;
  final List<Draft> drafts;
  final bool isCommissioner;
  final VoidCallback onCreateDraft;
  final Future<void> Function(Draft draft)? onStartDraft;
  final Future<void> Function(Draft draft)? onRandomizeDraftOrder;

  const LeagueDraftsTab({
    super.key,
    required this.leagueId,
    required this.drafts,
    this.isCommissioner = false,
    required this.onCreateDraft,
    this.onStartDraft,
    this.onRandomizeDraftOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: drafts.isEmpty
              ? _buildEmptyState(context)
              : _buildDraftsList(context),
        ),
        if (isCommissioner)
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: onCreateDraft,
              icon: const Icon(Icons.add),
              label: const Text('Create Draft'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No drafts yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return _DraftCard(
          leagueId: leagueId,
          draft: draft,
          isCommissioner: isCommissioner,
          onStartDraft: onStartDraft,
          onRandomizeDraftOrder: onRandomizeDraftOrder,
        );
      },
    );
  }
}

class _DraftCard extends StatelessWidget {
  final int leagueId;
  final Draft draft;
  final bool isCommissioner;
  final Future<void> Function(Draft draft)? onStartDraft;
  final Future<void> Function(Draft draft)? onRandomizeDraftOrder;

  const _DraftCard({
    required this.leagueId,
    required this.draft,
    this.isCommissioner = false,
    this.onStartDraft,
    this.onRandomizeDraftOrder,
  });

  @override
  Widget build(BuildContext context) {
    final canRandomize = isCommissioner &&
        draft.status == DraftStatus.notStarted &&
        onRandomizeDraftOrder != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Draft #${draft.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text('Type: ${draft.draftType.label}'),
                      Text('Status: ${draft.status}'),
                      Text('Rounds: ${draft.rounds}'),
                    ],
                  ),
                ),
                _DraftActionWidget(
                  draft: draft,
                  onStartDraft: onStartDraft,
                ),
              ],
            ),
            if (canRandomize) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.shuffle, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Commissioner Actions', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showRandomizeConfirmation(context),
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('Randomize Order'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/leagues/$leagueId/drafts/${draft.id}'),
                child: const Text('View Draft Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRandomizeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randomize Draft Order?'),
        content: const Text(
          'This will randomly shuffle the draft order for all teams. '
          'This action can only be done before the draft starts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              onRandomizeDraftOrder?.call(draft);
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Randomize'),
          ),
        ],
      ),
    );
  }
}

class _DraftActionWidget extends StatelessWidget {
  final Draft draft;
  final Future<void> Function(Draft draft)? onStartDraft;

  const _DraftActionWidget({
    required this.draft,
    this.onStartDraft,
  });

  @override
  Widget build(BuildContext context) {
    switch (draft.status) {
      case DraftStatus.notStarted:
        final canStart = draft.orderConfirmed && onStartDraft != null;
        return Tooltip(
          message: draft.orderConfirmed ? '' : 'Randomize draft order first',
          child: ElevatedButton(
            onPressed: canStart ? () => onStartDraft!(draft) : null,
            child: const Text('Start'),
          ),
        );
      case DraftStatus.inProgress:
        return const Chip(
          label: Text('Live'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        );
      case DraftStatus.completed:
        return const Chip(label: Text('Completed'));
      case DraftStatus.paused:
        return const Chip(
          label: Text('Paused'),
          backgroundColor: Colors.orange,
          labelStyle: TextStyle(color: Colors.white),
        );
    }
  }
}
