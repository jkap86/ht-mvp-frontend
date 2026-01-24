import 'package:flutter/material.dart';

class CreateLeagueDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required String season,
    required int totalRosters,
    required Map<String, dynamic> scoringSettings,
    required String mode,
    required Map<String, dynamic> settings,
  }) onCreateLeague;

  const CreateLeagueDialog({super.key, required this.onCreateLeague});

  @override
  State<CreateLeagueDialog> createState() => _CreateLeagueDialogState();
}

class _CreateLeagueDialogState extends State<CreateLeagueDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedSeason = DateTime.now().year.toString();
  int _selectedRosters = 12;
  String _selectedScoringType = 'ppr';
  String _selectedLeagueMode = 'redraft';
  String _selectedDraftType = 'snake';
  int _auctionBudget = 200;

  // Roster position configuration
  int _qbSlots = 1;
  int _rbSlots = 2;
  int _wrSlots = 2;
  int _teSlots = 1;
  int _flexSlots = 1;
  int _kSlots = 1;
  int _defSlots = 1;
  int _bnSlots = 6;
  bool _rosterConfigExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getScoringSettings(String type) {
    switch (type) {
      case 'standard':
        return {'rec': 0.0};
      case 'half_ppr':
        return {'rec': 0.5};
      case 'ppr':
        return {'rec': 1.0};
      default:
        return {'rec': 1.0};
    }
  }

  Map<String, int> _getRosterConfig() {
    return {
      'QB': _qbSlots,
      'RB': _rbSlots,
      'WR': _wrSlots,
      'TE': _teSlots,
      'FLEX': _flexSlots,
      'K': _kSlots,
      'DEF': _defSlots,
      'BN': _bnSlots,
    };
  }

  Widget _buildPositionSlotRow(
    String label,
    int value,
    int min,
    int max,
    void Function(int) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: value > min ? () => onChanged(value - 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          SizedBox(
            width: 24,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: value < max ? () => onChanged(value + 1) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create League'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'League Name',
                  hintText: 'Enter league name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a league name';
                  }
                  if (value.length > 100) {
                    return 'Name must be 100 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedSeason,
                decoration: const InputDecoration(
                  labelText: 'Season',
                ),
                items: [
                  for (int year = DateTime.now().year;
                      year <= DateTime.now().year + 1;
                      year++)
                    DropdownMenuItem(
                        value: year.toString(), child: Text(year.toString())),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSeason = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedRosters,
                decoration: const InputDecoration(
                  labelText: 'Number of Teams',
                ),
                items: [
                  for (int i = 2; i <= 20; i++)
                    DropdownMenuItem(value: i, child: Text('$i teams')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRosters = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedScoringType,
                decoration: const InputDecoration(
                  labelText: 'Scoring Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'half_ppr', child: Text('Half-PPR')),
                  DropdownMenuItem(value: 'ppr', child: Text('PPR')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedScoringType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLeagueMode,
                decoration: const InputDecoration(
                  labelText: 'League Mode',
                ),
                items: const [
                  DropdownMenuItem(value: 'redraft', child: Text('Redraft')),
                  DropdownMenuItem(value: 'keeper', child: Text('Keeper')),
                  DropdownMenuItem(value: 'dynasty', child: Text('Dynasty')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLeagueMode = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDraftType,
                decoration: const InputDecoration(
                  labelText: 'Draft Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'snake', child: Text('Snake')),
                  DropdownMenuItem(value: 'linear', child: Text('Linear')),
                  DropdownMenuItem(value: 'auction', child: Text('Auction')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDraftType = value);
                  }
                },
              ),
              if (_selectedDraftType == 'auction') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _auctionBudget,
                  decoration: const InputDecoration(
                    labelText: 'Auction Budget',
                  ),
                  items: [
                    for (int budget in [100, 150, 200, 250, 300, 500])
                      DropdownMenuItem(value: budget, child: Text('\$$budget')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _auctionBudget = value);
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              // Roster Position Configuration
              ExpansionTile(
                title: const Text('Roster Positions'),
                subtitle: Text(
                  'QB:$_qbSlots RB:$_rbSlots WR:$_wrSlots TE:$_teSlots FLEX:$_flexSlots',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                initiallyExpanded: _rosterConfigExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _rosterConfigExpanded = expanded);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildPositionSlotRow('QB', _qbSlots, 0, 2, (v) => setState(() => _qbSlots = v)),
                        _buildPositionSlotRow('RB', _rbSlots, 0, 4, (v) => setState(() => _rbSlots = v)),
                        _buildPositionSlotRow('WR', _wrSlots, 0, 4, (v) => setState(() => _wrSlots = v)),
                        _buildPositionSlotRow('TE', _teSlots, 0, 2, (v) => setState(() => _teSlots = v)),
                        _buildPositionSlotRow('FLEX', _flexSlots, 0, 4, (v) => setState(() => _flexSlots = v)),
                        _buildPositionSlotRow('K', _kSlots, 0, 2, (v) => setState(() => _kSlots = v)),
                        _buildPositionSlotRow('DEF', _defSlots, 0, 2, (v) => setState(() => _defSlots = v)),
                        _buildPositionSlotRow('Bench', _bnSlots, 0, 10, (v) => setState(() => _bnSlots = v)),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${_qbSlots + _rbSlots + _wrSlots + _teSlots + _flexSlots + _kSlots + _defSlots + _bnSlots} roster spots',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              await widget.onCreateLeague(
                name: _nameController.text,
                season: _selectedSeason,
                totalRosters: _selectedRosters,
                scoringSettings: _getScoringSettings(_selectedScoringType),
                mode: _selectedLeagueMode,
                settings: {
                  'draftType': _selectedDraftType,
                  'roster_config': _getRosterConfig(),
                  if (_selectedDraftType == 'auction') 'auctionBudget': _auctionBudget,
                },
              );
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

void showCreateLeagueDialog(
  BuildContext context, {
  required Future<void> Function({
    required String name,
    required String season,
    required int totalRosters,
    required Map<String, dynamic> scoringSettings,
    required String mode,
    required Map<String, dynamic> settings,
  }) onCreateLeague,
}) {
  showDialog(
    context: context,
    builder: (context) => CreateLeagueDialog(onCreateLeague: onCreateLeague),
  );
}
