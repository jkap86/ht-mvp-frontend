import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Commissioner waiver admin card.
///
/// Provides reset priority, set priority per roster, and FAAB budget adjustment.
class CommissionerToolsWaiversCard extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final bool hasFaab;
  final VoidCallback onResetPriority;
  final void Function(int rosterId, int priority) onSetPriority;
  final void Function(int rosterId, num setTo) onSetFaabBudget;

  const CommissionerToolsWaiversCard({
    super.key,
    required this.members,
    required this.hasFaab,
    required this.onResetPriority,
    required this.onSetPriority,
    required this.onSetFaabBudget,
  });

  Future<void> _confirmResetPriority(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Waiver Priority?'),
        content: const Text(
          'This will reset all waiver priorities back to the default roster order. '
          'Any manual priority changes will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) onResetPriority();
  }

  void _showSetPriorityDialog(BuildContext context, int rosterId, String teamName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Priority: $teamName'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'New priority (1-${members.length})',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final priority = int.tryParse(controller.text);
              if (priority != null && priority >= 1 && priority <= members.length) {
                Navigator.of(ctx).pop();
                onSetPriority(rosterId, priority);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showSetFaabDialog(BuildContext context, int rosterId, String teamName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set FAAB: $teamName'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'New FAAB budget',
            prefixText: '\$',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = int.tryParse(controller.text);
              if (amount != null && amount >= 0) {
                Navigator.of(ctx).pop();
                onSetFaabBudget(rosterId, amount);
              }
            },
            child: const Text('Set'),
          ),
        ],
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
                Icon(Icons.format_list_numbered, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Waiver Admin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Reset priority button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmResetPriority(context),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset All Priorities'),
              ),
            ),
            const SizedBox(height: 16),

            // Per-roster controls
            const Text(
              'Per-Team Adjustments',
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.low_priority, size: 20),
                      tooltip: 'Set waiver priority',
                      onPressed: () => _showSetPriorityDialog(context, rosterId, teamName),
                    ),
                    if (hasFaab)
                      IconButton(
                        icon: const Icon(Icons.attach_money, size: 20),
                        tooltip: 'Set FAAB budget',
                        onPressed: () => _showSetFaabDialog(context, rosterId, teamName),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
