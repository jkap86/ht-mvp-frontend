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
  String _selectedLeagueMode = 'redraft';

  // Scoring categories (Sleeper-style)
  // Passing
  int _passingTdPoints = 4;
  int _passingYardsPerPoint = 25;
  int _interceptionPoints = -1;

  // Rushing
  int _rushingTdPoints = 6;
  int _rushingYardsPerPoint = 10;

  // Receiving
  double _pprValue = 1.0;
  int _receivingTdPoints = 6;
  int _receivingYardsPerPoint = 10;
  double _tePremium = 0.0;

  // Bonuses
  int _bonus100YardRush = 0;
  int _bonus100YardRec = 0;
  int _bonus300YardPass = 0;
  int _bonus40YardTd = 0;

  // Misc
  int _fumbleLostPoints = -2;
  int _twoPtConversion = 2;

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

  Map<String, dynamic> _getScoringSettings() {
    return {
      // Passing
      'pass_td': _passingTdPoints,
      'pass_yd': 1.0 / _passingYardsPerPoint,
      'pass_int': _interceptionPoints,
      // Rushing
      'rush_td': _rushingTdPoints,
      'rush_yd': 1.0 / _rushingYardsPerPoint,
      // Receiving
      'rec': _pprValue,
      'rec_td': _receivingTdPoints,
      'rec_yd': 1.0 / _receivingYardsPerPoint,
      'te_premium': _tePremium,
      // Bonuses
      'bonus_rush_yd_100': _bonus100YardRush,
      'bonus_rec_yd_100': _bonus100YardRec,
      'bonus_pass_yd_300': _bonus300YardPass,
      'bonus_40_yd_td': _bonus40YardTd,
      // Misc
      'fum_lost': _fumbleLostPoints,
      'two_pt': _twoPtConversion,
    };
  }

  Widget _buildScoringOption({
    required String label,
    required List<({String label, dynamic value})> options,
    required dynamic selectedValue,
    required void Function(dynamic) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(204),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: options.map((option) {
                  final isSelected = option.value == selectedValue;
                  final isFirst = options.first == option;
                  final isLast = options.last == option;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelected(option.value),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.horizontal(
                            left: isFirst ? const Radius.circular(8) : Radius.zero,
                            right: isLast ? const Radius.circular(8) : Radius.zero,
                          ),
                        ),
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withAlpha(179),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emoji_events, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Create League'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 20),
              // Scoring Categories Header
              Row(
                children: [
                  Icon(Icons.scoreboard_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Scoring Settings',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Passing Section
              _buildScoringSection(
                title: 'Passing',
                icon: Icons.sports_football,
                children: [
                  _buildScoringOption(
                    label: 'Passing TD',
                    options: [(label: '4', value: 4), (label: '5', value: 5), (label: '6', value: 6)],
                    selectedValue: _passingTdPoints,
                    onSelected: (v) => setState(() => _passingTdPoints = v),
                  ),
                  _buildScoringOption(
                    label: 'Yards / Point',
                    options: [(label: '20', value: 20), (label: '25', value: 25), (label: '30', value: 30)],
                    selectedValue: _passingYardsPerPoint,
                    onSelected: (v) => setState(() => _passingYardsPerPoint = v),
                  ),
                  _buildScoringOption(
                    label: 'Interception',
                    options: [(label: '0', value: 0), (label: '-1', value: -1), (label: '-2', value: -2)],
                    selectedValue: _interceptionPoints,
                    onSelected: (v) => setState(() => _interceptionPoints = v),
                  ),
                ],
              ),

              // Rushing Section
              _buildScoringSection(
                title: 'Rushing',
                icon: Icons.directions_run,
                children: [
                  _buildScoringOption(
                    label: 'Rushing TD',
                    options: [(label: '6', value: 6), (label: '7', value: 7), (label: '8', value: 8)],
                    selectedValue: _rushingTdPoints,
                    onSelected: (v) => setState(() => _rushingTdPoints = v),
                  ),
                  _buildScoringOption(
                    label: 'Yards / Point',
                    options: [(label: '8', value: 8), (label: '10', value: 10), (label: '12', value: 12)],
                    selectedValue: _rushingYardsPerPoint,
                    onSelected: (v) => setState(() => _rushingYardsPerPoint = v),
                  ),
                ],
              ),

              // Receiving Section
              _buildScoringSection(
                title: 'Receiving',
                icon: Icons.catching_pokemon,
                children: [
                  _buildScoringOption(
                    label: 'PPR',
                    options: [(label: '0', value: 0.0), (label: '0.5', value: 0.5), (label: '1', value: 1.0)],
                    selectedValue: _pprValue,
                    onSelected: (v) => setState(() => _pprValue = v),
                  ),
                  _buildScoringOption(
                    label: 'Receiving TD',
                    options: [(label: '6', value: 6), (label: '7', value: 7), (label: '8', value: 8)],
                    selectedValue: _receivingTdPoints,
                    onSelected: (v) => setState(() => _receivingTdPoints = v),
                  ),
                  _buildScoringOption(
                    label: 'Yards / Point',
                    options: [(label: '8', value: 8), (label: '10', value: 10), (label: '12', value: 12)],
                    selectedValue: _receivingYardsPerPoint,
                    onSelected: (v) => setState(() => _receivingYardsPerPoint = v),
                  ),
                  _buildScoringOption(
                    label: 'TE Premium',
                    options: [(label: 'Off', value: 0.0), (label: '+0.5', value: 0.5), (label: '+1', value: 1.0)],
                    selectedValue: _tePremium,
                    onSelected: (v) => setState(() => _tePremium = v),
                  ),
                ],
              ),

              // Bonuses Section
              _buildScoringSection(
                title: 'Bonuses',
                icon: Icons.star_outline,
                children: [
                  _buildScoringOption(
                    label: '100+ Rush Yds',
                    options: [(label: 'Off', value: 0), (label: '+3', value: 3), (label: '+5', value: 5)],
                    selectedValue: _bonus100YardRush,
                    onSelected: (v) => setState(() => _bonus100YardRush = v),
                  ),
                  _buildScoringOption(
                    label: '100+ Rec Yds',
                    options: [(label: 'Off', value: 0), (label: '+3', value: 3), (label: '+5', value: 5)],
                    selectedValue: _bonus100YardRec,
                    onSelected: (v) => setState(() => _bonus100YardRec = v),
                  ),
                  _buildScoringOption(
                    label: '300+ Pass Yds',
                    options: [(label: 'Off', value: 0), (label: '+3', value: 3), (label: '+5', value: 5)],
                    selectedValue: _bonus300YardPass,
                    onSelected: (v) => setState(() => _bonus300YardPass = v),
                  ),
                  _buildScoringOption(
                    label: '40+ Yd TD',
                    options: [(label: 'Off', value: 0), (label: '+1', value: 1), (label: '+2', value: 2)],
                    selectedValue: _bonus40YardTd,
                    onSelected: (v) => setState(() => _bonus40YardTd = v),
                  ),
                ],
              ),

              // Misc Section
              _buildScoringSection(
                title: 'Miscellaneous',
                icon: Icons.more_horiz,
                children: [
                  _buildScoringOption(
                    label: 'Fumble Lost',
                    options: [(label: '0', value: 0), (label: '-1', value: -1), (label: '-2', value: -2)],
                    selectedValue: _fumbleLostPoints,
                    onSelected: (v) => setState(() => _fumbleLostPoints = v),
                  ),
                  _buildScoringOption(
                    label: '2PT Conversion',
                    options: [(label: '1', value: 1), (label: '2', value: 2), (label: '3', value: 3)],
                    selectedValue: _twoPtConversion,
                    onSelected: (v) => setState(() => _twoPtConversion = v),
                  ),
                ],
              ),
              // Roster Position Configuration
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(Icons.groups, size: 18, color: colorScheme.primary),
                    title: const Text('Roster Positions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      'QB:$_qbSlots  RB:$_rbSlots  WR:$_wrSlots  TE:$_teSlots  FLEX:$_flexSlots',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(153)),
                    ),
                    initiallyExpanded: _rosterConfigExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() => _rosterConfigExpanded = expanded);
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: [
                            _buildPositionSlotRow('QB', _qbSlots, 0, 3, (v) => setState(() => _qbSlots = v)),
                            _buildPositionSlotRow('RB', _rbSlots, 0, 4, (v) => setState(() => _rbSlots = v)),
                            _buildPositionSlotRow('WR', _wrSlots, 0, 4, (v) => setState(() => _wrSlots = v)),
                            _buildPositionSlotRow('TE', _teSlots, 0, 3, (v) => setState(() => _teSlots = v)),
                            _buildPositionSlotRow('FLEX', _flexSlots, 0, 4, (v) => setState(() => _flexSlots = v)),
                            _buildPositionSlotRow('K', _kSlots, 0, 2, (v) => setState(() => _kSlots = v)),
                            _buildPositionSlotRow('DEF', _defSlots, 0, 2, (v) => setState(() => _defSlots = v)),
                            _buildPositionSlotRow('Bench', _bnSlots, 0, 15, (v) => setState(() => _bnSlots = v)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withAlpha(128),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Total: ${_qbSlots + _rbSlots + _wrSlots + _teSlots + _flexSlots + _kSlots + _defSlots + _bnSlots} roster spots',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colorScheme.onSurface.withAlpha(179))),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context);
              await widget.onCreateLeague(
                name: _nameController.text,
                season: _selectedSeason,
                totalRosters: _selectedRosters,
                scoringSettings: _getScoringSettings(),
                mode: _selectedLeagueMode,
                settings: {
                  'roster_config': _getRosterConfig(),
                },
              );
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create League'),
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
