import 'package:flutter/material.dart';

/// Card for managing scoring and finalizing weeks
class ScoringCard extends StatefulWidget {
  final int currentWeek;
  final void Function(int week) onFinalizeWeek;

  const ScoringCard({
    super.key,
    required this.currentWeek,
    required this.onFinalizeWeek,
  });

  @override
  State<ScoringCard> createState() => _ScoringCardState();
}

class _ScoringCardState extends State<ScoringCard> {
  int _selectedWeek = 1;

  void _showFinalizeWeekDialog() {
    setState(() => _selectedWeek = widget.currentWeek);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Finalize Week'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will lock in all scores for the selected week and update standings. '
                'This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedWeek,
                decoration: const InputDecoration(
                  labelText: 'Week',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(18, (i) => i + 1)
                    .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _selectedWeek = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onFinalizeWeek(_selectedWeek);
              },
              child: const Text('Finalize Week'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.scoreboard),
                const SizedBox(width: 8),
                Text(
                  'Scoring',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showFinalizeWeekDialog,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finalize Week'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lock in scores and update standings for a completed week.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
