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
    List<int>? weeksByRound,
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
  Map<int, int> _roundWeeks = {}; // round number -> weeks (1 or 2)

  /// Get total rounds based on playoff teams
  int _getTotalRounds(int playoffTeams) {
    switch (playoffTeams) {
      case 4:
        return 2;
      case 6:
      case 8:
        return 3;
      default:
        return 3;
    }
  }

  /// Get round name for display
  String _getRoundName(int playoffTeams, int round, int totalRounds) {
    if (round == totalRounds) return 'Championship';
    if (round == totalRounds - 1) return 'Semifinals';
    if (playoffTeams == 8 && round == 1) return 'Quarterfinals';
    if (playoffTeams == 6 && round == 1) return 'Wild Card';
    return 'Round $round';
  }

  /// Calculate total playoff weeks
  int _calculateTotalWeeks(int totalRounds) {
    int total = 0;
    for (int r = 1; r <= totalRounds; r++) {
      total += _roundWeeks[r] ?? 1;
    }
    return total;
  }

  /// Get championship week based on start week and weeks per round
  int _getChampionshipWeek(int startWeek, int totalRounds) {
    return startWeek + _calculateTotalWeeks(totalRounds) - 1;
  }

  /// Build weeksByRound array from _roundWeeks map
  List<int>? _buildWeeksByRound(int totalRounds) {
    final list = <int>[];
    bool hasMultiWeek = false;
    for (int r = 1; r <= totalRounds; r++) {
      final weeks = _roundWeeks[r] ?? 1;
      list.add(weeks);
      if (weeks > 1) hasMultiWeek = true;
    }
    // Only return if at least one round has 2 weeks
    return hasMultiWeek ? list : null;
  }

  void _showGeneratePlayoffBracketDialog(int currentWeek) {
    setState(() {
      _playoffTeams = 6;
      _playoffStartWeek = currentWeek + 1;
      _enableThirdPlaceGame = false;
      _consolationType = 'NONE';
      _consolationTeams = null;
      _roundWeeks = {}; // Reset to all 1-week rounds
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
                // Weeks per Round section
                Text(
                  'Weeks per Round',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose 1 or 2 weeks per round. Multi-week rounds use aggregate scoring.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                // Round week selectors
                ...List.generate(_getTotalRounds(_playoffTeams), (index) {
                  final round = index + 1;
                  final totalRounds = _getTotalRounds(_playoffTeams);
                  final roundName = _getRoundName(_playoffTeams, round, totalRounds);
                  final selectedWeeks = _roundWeeks[round] ?? 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'R$round: $roundName',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1 Week')),
                              ButtonSegment(value: 2, label: Text('2 Weeks')),
                            ],
                            selected: {selectedWeeks},
                            onSelectionChanged: (Set<int> selected) {
                              setDialogState(() {
                                _roundWeeks[round] = selected.first;
                              });
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                // Week range display
                Builder(builder: (context) {
                  final totalRounds = _getTotalRounds(_playoffTeams);
                  final championshipWeek = _getChampionshipWeek(_playoffStartWeek, totalRounds);
                  final isValid = championshipWeek <= 18;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isValid
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isValid ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isValid ? Icons.check_circle : Icons.error,
                          color: isValid ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isValid
                              ? 'Playoffs: Week $_playoffStartWeek - $championshipWeek'
                              : 'Championship Week $championshipWeek exceeds Week 18',
                            style: TextStyle(
                              color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
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
            Builder(builder: (context) {
              final totalRounds = _getTotalRounds(_playoffTeams);
              final championshipWeek = _getChampionshipWeek(_playoffStartWeek, totalRounds);
              final isValid = championshipWeek <= 18;

              return FilledButton(
                onPressed: isValid
                  ? () {
                      Navigator.pop(context);
                      widget.onGeneratePlayoffBracket(
                        playoffTeams: _playoffTeams,
                        startWeek: _playoffStartWeek,
                        weeksByRound: _buildWeeksByRound(totalRounds),
                        enableThirdPlaceGame: _enableThirdPlaceGame ? true : null,
                        consolationType: _consolationType != 'NONE' ? _consolationType : null,
                        consolationTeams: _consolationTeams,
                      );
                    }
                  : null,
                child: const Text('Generate'),
              );
            }),
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
