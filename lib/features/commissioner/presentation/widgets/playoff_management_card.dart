import 'package:flutter/material.dart';

import '../../../playoffs/domain/playoff.dart';
import '../providers/commissioner_provider.dart';

/// Card for managing playoffs
class PlayoffManagementCard extends StatefulWidget {
  final CommissionerState state;
  final int leagueId;
  final void Function({
    required int playoffTeams,
    required int startWeek,
    bool? enableThirdPlaceGame,
    String? consolationType,
    int? consolationTeams,
  }) onGeneratePlayoffBracket;
  final void Function(int week) onAdvanceWinners;
  final void Function() onViewBracket;

  const PlayoffManagementCard({
    super.key,
    required this.state,
    required this.leagueId,
    required this.onGeneratePlayoffBracket,
    required this.onAdvanceWinners,
    required this.onViewBracket,
  });

  @override
  State<PlayoffManagementCard> createState() => _PlayoffManagementCardState();
}

class _PlayoffManagementCardState extends State<PlayoffManagementCard> {
  int _selectedWeek = 1;
  int _playoffTeams = 6;
  int _playoffStartWeek = 15;
  bool _enableThirdPlaceGame = false;
  String _consolationType = 'NONE';
  int? _consolationTeams;

  void _showGeneratePlayoffBracketDialog(int currentWeek) {
    setState(() {
      _playoffTeams = 6;
      _playoffStartWeek = currentWeek + 1;
      _enableThirdPlaceGame = false;
      _consolationType = 'NONE';
      _consolationTeams = null;
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Playoff Bracket'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create a playoff bracket based on current standings.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _playoffTeams,
                  decoration: const InputDecoration(
                    labelText: 'Playoff Teams',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text('4 teams (2 rounds)')),
                    DropdownMenuItem(value: 6, child: Text('6 teams (3 rounds, top 2 get bye)')),
                    DropdownMenuItem(value: 8, child: Text('8 teams (3 rounds)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _playoffTeams = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _playoffStartWeek,
                  decoration: const InputDecoration(
                    labelText: 'Start Week',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(18, (i) => i + 1)
                      .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _playoffStartWeek = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // 3rd Place Game toggle
                SwitchListTile(
                  title: const Text('3rd Place Game'),
                  subtitle: const Text('Semifinal losers compete for 3rd place'),
                  value: _enableThirdPlaceGame,
                  onChanged: (value) {
                    setDialogState(() => _enableThirdPlaceGame = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                // Consolation dropdown
                DropdownButtonFormField<String>(
                  value: _consolationType,
                  decoration: const InputDecoration(
                    labelText: 'Consolation Bracket',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NONE', child: Text('None')),
                    DropdownMenuItem(
                      value: 'CONSOLATION',
                      child: Text('Consolation (Winner Advances)'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _consolationType = value ?? 'NONE';
                      if (_consolationType == 'NONE') {
                        _consolationTeams = null;
                      }
                    });
                  },
                ),
                // Consolation teams (conditional)
                if (_consolationType != 'NONE') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _consolationTeams,
                    decoration: const InputDecoration(
                      labelText: 'Consolation Teams',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Auto (remaining non-playoff teams)'),
                      ),
                      DropdownMenuItem(value: 4, child: Text('4 teams')),
                      DropdownMenuItem(value: 6, child: Text('6 teams')),
                      DropdownMenuItem(value: 8, child: Text('8 teams')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _consolationTeams = value);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onGeneratePlayoffBracket(
                  playoffTeams: _playoffTeams,
                  startWeek: _playoffStartWeek,
                  enableThirdPlaceGame: _enableThirdPlaceGame ? true : null,
                  consolationType: _consolationType != 'NONE' ? _consolationType : null,
                  consolationTeams: _consolationTeams,
                );
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvanceWinnersDialog(int currentWeek) {
    setState(() => _selectedWeek = currentWeek);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Advance Winners'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Advance playoff winners from the selected week to the next round.'),
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
              onPressed: () {
                Navigator.pop(context);
                widget.onAdvanceWinners(_selectedWeek);
              },
              child: const Text('Advance'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayoffStatusChip(PlayoffStatus status) {
    Color color;
    String label;

    switch (status) {
      case PlayoffStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case PlayoffStatus.completed:
        color = Colors.blue;
        label = 'Completed';
        break;
      case PlayoffStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPlayoffInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPlayoffs = widget.state.hasPlayoffs;
    final bracket = widget.state.bracketView?.bracket;
    final isCompleted = bracket?.status == PlayoffStatus.completed;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events),
                const SizedBox(width: 8),
                Text(
                  'Playoff Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasPlayoffs) ...[
                  const Spacer(),
                  _buildPlayoffStatusChip(bracket!.status),
                ],
              ],
            ),
            const Divider(),
            if (hasPlayoffs) ...[
              // Show bracket info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPlayoffInfoItem(
                        'Teams',
                        '${bracket!.playoffTeams}',
                      ),
                    ),
                    Expanded(
                      child: _buildPlayoffInfoItem(
                        'Rounds',
                        '${bracket.totalRounds}',
                      ),
                    ),
                    Expanded(
                      child: _buildPlayoffInfoItem(
                        'Weeks',
                        '${bracket.startWeek}-${bracket.championshipWeek}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // View bracket button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onViewBracket,
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Bracket'),
                ),
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 8),
                // Advance winners button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAdvanceWinnersDialog(widget.state.league?.currentWeek ?? 1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Advance Winners'),
                  ),
                ),
                const SizedBox(height: 8),
                // Regenerate bracket button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showGeneratePlayoffBracketDialog(widget.state.league?.currentWeek ?? 14),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate Bracket'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                isCompleted
                    ? 'Playoffs are complete!'
                    : 'Advance winners after finalizing each playoff week.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showGeneratePlayoffBracketDialog(widget.state.league?.currentWeek ?? 14),
                  icon: const Icon(Icons.add),
                  label: const Text('Generate Playoff Bracket'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a playoff bracket based on current standings. Top seeds are determined by win-loss record.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
