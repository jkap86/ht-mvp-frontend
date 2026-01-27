import 'package:flutter/material.dart';

import '../../../leagues/domain/league.dart';
import '../providers/commissioner_provider.dart';

/// Card for resetting the league for a new season
class SeasonResetCard extends StatefulWidget {
  final CommissionerState state;
  final Future<bool> Function({
    required String newSeason,
    required String confirmationName,
    bool keepMembers,
    bool clearChat,
  }) onReset;

  const SeasonResetCard({
    super.key,
    required this.state,
    required this.onReset,
  });

  @override
  State<SeasonResetCard> createState() => _SeasonResetCardState();
}

class _SeasonResetCardState extends State<SeasonResetCard> {
  final _confirmationController = TextEditingController();
  bool _keepMembers = false;
  bool _clearChat = true;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _canReset {
    final status = widget.state.league?.seasonStatus;
    return status == SeasonStatus.offseason || status == SeasonStatus.preSeason;
  }

  void _showResetDialog() {
    _confirmationController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset League for New Season'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will clear all season data including drafts, matchups, trades, waivers, and rosters. League settings will be preserved.',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Keep Members'),
                  subtitle: const Text('Members keep their spots with empty rosters'),
                  value: _keepMembers,
                  onChanged: (value) {
                    setDialogState(() => _keepMembers = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Clear Chat'),
                  subtitle: const Text('Remove all chat messages'),
                  value: _clearChat,
                  onChanged: (value) {
                    setDialogState(() => _clearChat = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                Text(
                  'Type "${widget.state.league?.name}" to confirm:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmationController,
                  decoration: const InputDecoration(
                    labelText: 'League Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              onPressed: () async {
                Navigator.pop(context);
                final currentSeason = widget.state.league?.season ?? DateTime.now().year;
                await widget.onReset(
                  newSeason: currentSeason.toString(),
                  confirmationName: _confirmationController.text.trim(),
                  keepMembers: _keepMembers,
                  clearChat: _clearChat,
                );
              },
              child: const Text('Reset League'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.refresh, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Season Reset',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (!_canReset) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'League can only be reset during pre-season or offseason. Current status: ${widget.state.league?.seasonStatus.displayName ?? "Unknown"}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Clear all season data (drafts, matchups, trades, waivers, rosters) and start fresh for a new season. League configuration is preserved.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset for New Season'),
                onPressed: _canReset ? _showResetDialog : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
