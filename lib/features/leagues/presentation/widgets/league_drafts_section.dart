import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../drafts/domain/draft_order_entry.dart';
import '../../../drafts/domain/draft_status.dart';
import '../../domain/league.dart';

class LeagueDraftsSection extends StatelessWidget {
  final int leagueId;
  final List<Draft> drafts;
  final bool isCommissioner;
  final VoidCallback onCreateDraft;
  final Future<void> Function(Draft draft) onStartDraft;
  final Future<List<DraftOrderEntry>?> Function(Draft draft) onRandomizeDraftOrder;
  final Future<void> Function(Draft draft) onEditSettings;

  const LeagueDraftsSection({
    super.key,
    required this.leagueId,
    required this.drafts,
    this.isCommissioner = false,
    required this.onCreateDraft,
    required this.onStartDraft,
    required this.onRandomizeDraftOrder,
    required this.onEditSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Drafts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isCommissioner)
                  TextButton.icon(
                    onPressed: onCreateDraft,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (drafts.isEmpty)
              _buildEmptyState(context)
            else
              ...drafts.map((draft) => _DraftItem(
                    key: ValueKey(draft.id),
                    leagueId: leagueId,
                    draft: draft,
                    isCommissioner: isCommissioner,
                    onStartDraft: onStartDraft,
                    onRandomizeDraftOrder: onRandomizeDraftOrder,
                    onEditSettings: onEditSettings,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No drafts yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftItem extends StatefulWidget {
  final int leagueId;
  final Draft draft;
  final bool isCommissioner;
  final Future<void> Function(Draft draft) onStartDraft;
  final Future<List<DraftOrderEntry>?> Function(Draft draft) onRandomizeDraftOrder;
  final Future<void> Function(Draft draft) onEditSettings;

  const _DraftItem({
    super.key,
    required this.leagueId,
    required this.draft,
    required this.isCommissioner,
    required this.onStartDraft,
    required this.onRandomizeDraftOrder,
    required this.onEditSettings,
  });

  @override
  State<_DraftItem> createState() => _DraftItemState();
}

class _DraftItemState extends State<_DraftItem> with SingleTickerProviderStateMixin {
  List<DraftOrderEntry>? _draftOrder;
  bool _isShuffling = false;
  List<String> _shuffleDisplay = [];
  Timer? _shuffleTimer;

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRandomize() async {
    setState(() {
      _isShuffling = true;
      _draftOrder = null;
    });

    // Start the shuffle animation
    _startShuffleAnimation();

    // Run API call and minimum 5 second timer in parallel
    final results = await Future.wait([
      widget.onRandomizeDraftOrder(widget.draft),
      Future.delayed(const Duration(seconds: 5)),
    ]);

    final order = results[0] as List<DraftOrderEntry>?;

    // Stop the animation
    _shuffleTimer?.cancel();

    if (mounted) {
      setState(() {
        _isShuffling = false;
        _draftOrder = order;
        _shuffleDisplay = [];
      });
    }
  }

  void _startShuffleAnimation() {
    final random = Random();
    final names = ['Team 1', 'Team 2', 'Team 3', 'Team 4', 'Team 5', 'Team 6'];

    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Show random shuffled order
        final shuffled = List<String>.from(names);
        for (int i = shuffled.length - 1; i > 0; i--) {
          final j = random.nextInt(i + 1);
          final temp = shuffled[i];
          shuffled[i] = shuffled[j];
          shuffled[j] = temp;
        }
        _shuffleDisplay = shuffled.take(4).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Slow auctions don't use draft order - nominations are open to all teams
    final isSlowAuction = widget.draft.isAuction &&
        widget.draft.settings?.isFastAuction != true;

    final canRandomize = widget.isCommissioner &&
        widget.draft.status == DraftStatus.notStarted &&
        !widget.draft.orderConfirmed &&
        !isSlowAuction;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
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
                      'Draft #${widget.draft.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.draft.draftType.label} • ${widget.draft.rounds} rounds',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Edit settings button for commissioners (not shown for completed drafts)
              if (widget.isCommissioner && widget.draft.status != DraftStatus.completed)
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  tooltip: 'Edit Settings',
                  onPressed: () => widget.onEditSettings(widget.draft),
                ),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/leagues/${widget.leagueId}/drafts/${widget.draft.id}'),
                  child: const Text('View Draft Room'),
                ),
              ),
              if (widget.draft.status == DraftStatus.notStarted && widget.isCommissioner) ...[
                const SizedBox(width: 8),
                _buildStartButton(context),
              ],
            ],
          ),
          if (canRandomize) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isShuffling ? null : () => _showRandomizeConfirmation(context),
                icon: _isShuffling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shuffle, size: 18),
                label: Text(_isShuffling ? 'Shuffling...' : 'Randomize Order'),
              ),
            ),
          ],
          // Shuffle animation display
          if (_isShuffling && _shuffleDisplay.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildShuffleAnimation(),
          ],
          // Show draft order after randomization
          if (_draftOrder != null && _draftOrder!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDraftOrderDisplay(),
          ],
          // Show order confirmed message if already randomized
          if (widget.draft.orderConfirmed && _draftOrder == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Draft order confirmed',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShuffleAnimation() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shuffle,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Shuffling teams...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _shuffleDisplay.asMap().entries.map((entry) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 50),
                opacity: 1.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${entry.key + 1}. ${entry.value}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftOrderDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
              const SizedBox(width: 6),
              Text(
                'Draft Order Set!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_draftOrder!.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.draftPosition}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.username,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (widget.draft.status) {
      case DraftStatus.notStarted:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = 'Not Started';
        break;
      case DraftStatus.inProgress:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        label = 'Live';
        break;
      case DraftStatus.completed:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        label = 'Completed';
        break;
      case DraftStatus.paused:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        label = 'Paused';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    // Auctions don't require order confirmation (initial order is created automatically)
    final canStart = widget.draft.orderConfirmed || widget.draft.isAuction;
    return Tooltip(
      message: canStart ? '' : 'Randomize draft order first',
      child: ElevatedButton(
        onPressed: canStart ? () => widget.onStartDraft(widget.draft) : null,
        child: const Text('Start'),
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
              _handleRandomize();
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Randomize'),
          ),
        ],
      ),
    );
  }
}
