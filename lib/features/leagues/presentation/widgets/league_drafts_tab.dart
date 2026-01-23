import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/league.dart';

class LeagueDraftsTab extends StatelessWidget {
  final int leagueId;
  final List<Draft> drafts;
  final VoidCallback onCreateDraft;
  final Future<void> Function(Draft draft)? onStartDraft;

  const LeagueDraftsTab({
    super.key,
    required this.leagueId,
    required this.drafts,
    required this.onCreateDraft,
    this.onStartDraft,
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
          onStartDraft: onStartDraft,
        );
      },
    );
  }
}

class _DraftCard extends StatelessWidget {
  final int leagueId;
  final Draft draft;
  final Future<void> Function(Draft draft)? onStartDraft;

  const _DraftCard({
    required this.leagueId,
    required this.draft,
    this.onStartDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          'Draft #${draft.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: ${draft.draftType}'),
            Text('Status: ${draft.status}'),
            Text('Rounds: ${draft.rounds}'),
          ],
        ),
        trailing: _DraftActionWidget(
          draft: draft,
          onStartDraft: onStartDraft,
        ),
        onTap: () => context.go('/leagues/$leagueId/drafts/${draft.id}'),
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
      case 'not_started':
        return ElevatedButton(
          onPressed: onStartDraft != null ? () => onStartDraft!(draft) : null,
          child: const Text('Start'),
        );
      case 'in_progress':
        return const Chip(
          label: Text('Live'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        );
      case 'completed':
        return const Chip(label: Text('Completed'));
      default:
        return const SizedBox.shrink();
    }
  }
}
