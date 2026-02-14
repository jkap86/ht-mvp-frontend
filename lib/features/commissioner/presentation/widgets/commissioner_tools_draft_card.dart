import 'package:flutter/material.dart';

/// Commissioner draft admin card.
///
/// Provides chess clock adjustment, force autopick, and undo last pick
/// for an active in-progress draft.
class CommissionerToolsDraftCard extends StatelessWidget {
  final int draftId;
  final String draftLabel;
  final List<Map<String, dynamic>> members;
  final void Function(int rosterId, int deltaSeconds) onAdjustChessClock;
  final VoidCallback onForceAutopick;
  final VoidCallback onUndoLastPick;

  const CommissionerToolsDraftCard({
    super.key,
    required this.draftId,
    required this.draftLabel,
    required this.members,
    required this.onAdjustChessClock,
    required this.onForceAutopick,
    required this.onUndoLastPick,
  });

  Future<void> _confirmForceAutopick(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Autopick?'),
        content: const Text(
          'This will force an autopick for the current drafter. '
          'The best available player from their queue (or overall rankings) '
          'will be selected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Force Autopick'),
          ),
        ],
      ),
    );
    if (confirmed == true) onForceAutopick();
  }

  Future<void> _confirmUndoLastPick(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Undo Last Pick?'),
        content: const Text(
          'This will undo the most recent draft pick and revert the draft state. '
          'The picked player will be returned to the available pool.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Undo Pick'),
          ),
        ],
      ),
    );
    if (confirmed == true) onUndoLastPick();
  }

  void _showClockAdjustDialog(BuildContext context, int rosterId, String teamName) {
    showDialog(
      context: context,
      builder: (ctx) => _ChessClockAdjustDialog(
        teamName: teamName,
        onConfirm: (deltaSeconds) {
          onAdjustChessClock(rosterId, deltaSeconds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_football, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Draft Admin: $draftLabel',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Chess clock adjustments
            const Text(
              'Chess Clock Adjustments',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...members.map((member) {
              final rosterId = member['roster_id'] as int;
              final teamName = member['team_name'] as String? ??
                  member['username'] as String? ??
                  'Team $rosterId';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(teamName),
                trailing: IconButton(
                  icon: const Icon(Icons.timer),
                  tooltip: 'Adjust clock',
                  onPressed: () => _showClockAdjustDialog(context, rosterId, teamName),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _confirmForceAutopick(context),
                  icon: const Icon(Icons.fast_forward),
                  label: const Text('Force Autopick'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmUndoLastPick(context),
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo Last Pick'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChessClockAdjustDialog extends StatefulWidget {
  final String teamName;
  final void Function(int deltaSeconds) onConfirm;

  const _ChessClockAdjustDialog({
    required this.teamName,
    required this.onConfirm,
  });

  @override
  State<_ChessClockAdjustDialog> createState() => _ChessClockAdjustDialogState();
}

class _ChessClockAdjustDialogState extends State<_ChessClockAdjustDialog> {
  int _deltaSeconds = 60;
  bool _isAdding = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Clock: ${widget.teamName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Add Time')),
              ButtonSegment(value: false, label: Text('Remove Time')),
            ],
            selected: {_isAdding},
            onSelectionChanged: (values) {
              setState(() => _isAdding = values.first);
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 60, 120, 300].map((seconds) {
              final label = seconds >= 60
                  ? '${seconds ~/ 60}m'
                  : '${seconds}s';
              return ChoiceChip(
                label: Text(label),
                selected: _deltaSeconds == seconds,
                onSelected: (_) => setState(() => _deltaSeconds = seconds),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            _isAdding
                ? 'Add ${_formatDelta(_deltaSeconds)} to clock'
                : 'Remove ${_formatDelta(_deltaSeconds)} from clock',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            final delta = _isAdding ? _deltaSeconds : -_deltaSeconds;
            widget.onConfirm(delta);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  String _formatDelta(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      if (s == 0) return '${m}m';
      return '${m}m ${s}s';
    }
    return '${seconds}s';
  }
}
