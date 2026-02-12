import 'package:flutter/material.dart';

/// Card for managing league schedule
class ScheduleManagementCard extends StatefulWidget {
  final void Function(int weeks) onGenerateSchedule;

  const ScheduleManagementCard({
    super.key,
    required this.onGenerateSchedule,
  });

  @override
  State<ScheduleManagementCard> createState() => _ScheduleManagementCardState();
}

class _ScheduleManagementCardState extends State<ScheduleManagementCard> {
  final _weeksController = TextEditingController(text: '14');

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  void _showGenerateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will create a new round-robin schedule. Any existing schedule will be replaced. This action cannot be undone.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weeksController,
              decoration: const InputDecoration(
                labelText: 'Number of weeks',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final weeks = int.tryParse(_weeksController.text) ?? 14;
              widget.onGenerateSchedule(weeks);
            },
            child: const Text('Generate'),
          ),
        ],
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
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                Text(
                  'Schedule Management',
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
                onPressed: _showGenerateScheduleDialog,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Generate Schedule'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creates a round-robin schedule for all teams. Existing schedule will be replaced.',
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
