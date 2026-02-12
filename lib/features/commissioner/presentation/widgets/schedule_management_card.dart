import 'package:flutter/material.dart';

/// Schedule type options
enum ScheduleType { randomize, matchupsDraft }

/// Card for managing league schedule
class ScheduleManagementCard extends StatefulWidget {
  final void Function(int weeks) onGenerateSchedule;
  final Future<int?> Function({
    required int weeks,
    required int pickTimeSeconds,
    required bool randomizeDraftOrder,
  }) onStartMatchupsDraft;
  final bool seasonHasStarted;

  const ScheduleManagementCard({
    super.key,
    required this.onGenerateSchedule,
    required this.onStartMatchupsDraft,
    required this.seasonHasStarted,
  });

  @override
  State<ScheduleManagementCard> createState() => _ScheduleManagementCardState();
}

class _ScheduleManagementCardState extends State<ScheduleManagementCard> {
  final _weeksController = TextEditingController(text: '14');
  ScheduleType _selectedScheduleType = ScheduleType.randomize;
  int _pickTimeSeconds = 90;
  bool _randomizeDraftOrder = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  Widget _buildMatchupsDraftSettings(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Draft Settings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Pick Time',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: _pickTimeSeconds,
              items: const [
                DropdownMenuItem(value: 30, child: Text('30 seconds')),
                DropdownMenuItem(value: 60, child: Text('60 seconds')),
                DropdownMenuItem(value: 90, child: Text('90 seconds')),
                DropdownMenuItem(value: 120, child: Text('2 minutes')),
                DropdownMenuItem(value: 180, child: Text('3 minutes')),
                DropdownMenuItem(value: 300, child: Text('5 minutes')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _pickTimeSeconds = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Draft Order',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            RadioListTile<bool>(
              title: const Text('Randomize'),
              value: true,
              groupValue: _randomizeDraftOrder,
              onChanged: (value) {
                setState(() {
                  _randomizeDraftOrder = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            RadioListTile<bool>(
              title: const Text('Manual (set after creation)'),
              value: false,
              groupValue: _randomizeDraftOrder,
              onChanged: (value) {
                setState(() {
                  _randomizeDraftOrder = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
    );
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

  void _showStartMatchupsDraftDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start Matchups Draft'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will create a matchups draft where managers pick their opponents for each week of the season.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weeksController,
              decoration: const InputDecoration(
                labelText: 'Number of weeks',
                border: OutlineInputBorder(),
                helperText: 'Total regular season weeks to draft',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Draft Summary',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick Time: ${_pickTimeSeconds}s',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Draft Order: ${_randomizeDraftOrder ? "Randomized" : "Manual"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final weeks = int.tryParse(_weeksController.text) ?? 14;

              setState(() {
                _isProcessing = true;
              });

              final draftId = await widget.onStartMatchupsDraft(
                weeks: weeks,
                pickTimeSeconds: _pickTimeSeconds,
                randomizeDraftOrder: _randomizeDraftOrder,
              );

              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            },
            child: const Text('Start Draft'),
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
            const SizedBox(height: 16),
            Text(
              'Schedule Type:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<ScheduleType>(
              title: const Text('Randomize Schedule'),
              subtitle: const Text('Automatically generate a round-robin schedule'),
              value: ScheduleType.randomize,
              groupValue: _selectedScheduleType,
              onChanged: widget.seasonHasStarted
                  ? null
                  : (value) {
                      setState(() {
                        _selectedScheduleType = value!;
                      });
                    },
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<ScheduleType>(
              title: const Text('Matchups Draft'),
              subtitle: const Text('Let managers draft their opponents each week'),
              value: ScheduleType.matchupsDraft,
              groupValue: _selectedScheduleType,
              onChanged: widget.seasonHasStarted
                  ? null
                  : (value) {
                      setState(() {
                        _selectedScheduleType = value!;
                      });
                    },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            if (_selectedScheduleType == ScheduleType.matchupsDraft) ...[
              _buildMatchupsDraftSettings(context),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: _isProcessing
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      onPressed: widget.seasonHasStarted
                          ? null
                          : _selectedScheduleType == ScheduleType.randomize
                              ? _showGenerateScheduleDialog
                              : _showStartMatchupsDraftDialog,
                      icon: Icon(_selectedScheduleType == ScheduleType.randomize
                          ? Icons.auto_fix_high
                          : Icons.gavel),
                      label: Text(_selectedScheduleType == ScheduleType.randomize
                          ? 'Generate Schedule'
                          : 'Start Matchups Draft'),
                    ),
            ),
            if (widget.seasonHasStarted) ...[
              const SizedBox(height: 8),
              Text(
                'Cannot start matchups draft after season has started',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
