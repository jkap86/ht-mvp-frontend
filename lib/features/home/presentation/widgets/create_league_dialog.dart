import 'package:flutter/material.dart';

class CreateLeagueDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required String season,
    required int totalRosters,
    required Map<String, dynamic> scoringSettings,
    required String mode,
    required Map<String, dynamic> settings,
    required bool isPublic,
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
  bool _isPublic = false;

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
  bool _scoringExpanded = false;

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

  Widget _buildScoringInput({
    required String label,
    required num value,
    required void Function(num) onChanged,
    bool allowDecimal = false,
    bool allowNegative = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(
      text: allowDecimal ? value.toStringAsFixed(1) : value.toInt().toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(204),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            height: 36,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: allowDecimal,
                signed: allowNegative,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onChanged: (text) {
                if (text.isEmpty) return;
                final parsed = allowDecimal ? double.tryParse(text) : int.tryParse(text);
                if (parsed != null) {
                  onChanged(parsed);
                }
              },
            ),
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
              const SizedBox(height: 16),
              // Public/Private Toggle
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public League',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            _isPublic
                                ? 'Anyone can find and join this league'
                                : 'Only people with the invite code can join',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Scoring Settings - Collapsible
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(Icons.scoreboard_outlined, size: 18, color: colorScheme.primary),
                    title: const Text('Scoring Settings', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      'PPR: $_pprValue  Pass TD: $_passingTdPoints  Rush TD: $_rushingTdPoints',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(153)),
                    ),
                    initiallyExpanded: _scoringExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() => _scoringExpanded = expanded);
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Passing
                            Text('Passing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            _buildScoringInput(
                              label: 'Passing TD',
                              value: _passingTdPoints,
                              onChanged: (v) => setState(() => _passingTdPoints = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: 'Yards per Point',
                              value: _passingYardsPerPoint,
                              onChanged: (v) => setState(() => _passingYardsPerPoint = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: 'Interception',
                              value: _interceptionPoints,
                              onChanged: (v) => setState(() => _interceptionPoints = v.toInt()),
                              allowNegative: true,
                            ),
                            const SizedBox(height: 12),

                            // Rushing
                            Text('Rushing', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            _buildScoringInput(
                              label: 'Rushing TD',
                              value: _rushingTdPoints,
                              onChanged: (v) => setState(() => _rushingTdPoints = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: 'Yards per Point',
                              value: _rushingYardsPerPoint,
                              onChanged: (v) => setState(() => _rushingYardsPerPoint = v.toInt()),
                            ),
                            const SizedBox(height: 12),

                            // Receiving
                            Text('Receiving', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            _buildScoringInput(
                              label: 'PPR (per reception)',
                              value: _pprValue,
                              onChanged: (v) => setState(() => _pprValue = v.toDouble()),
                              allowDecimal: true,
                            ),
                            _buildScoringInput(
                              label: 'Receiving TD',
                              value: _receivingTdPoints,
                              onChanged: (v) => setState(() => _receivingTdPoints = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: 'Yards per Point',
                              value: _receivingYardsPerPoint,
                              onChanged: (v) => setState(() => _receivingYardsPerPoint = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: 'TE Premium',
                              value: _tePremium,
                              onChanged: (v) => setState(() => _tePremium = v.toDouble()),
                              allowDecimal: true,
                            ),
                            const SizedBox(height: 12),

                            // Bonuses
                            Text('Bonuses', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            _buildScoringInput(
                              label: '100+ Rush Yards',
                              value: _bonus100YardRush,
                              onChanged: (v) => setState(() => _bonus100YardRush = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: '100+ Rec Yards',
                              value: _bonus100YardRec,
                              onChanged: (v) => setState(() => _bonus100YardRec = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: '300+ Pass Yards',
                              value: _bonus300YardPass,
                              onChanged: (v) => setState(() => _bonus300YardPass = v.toInt()),
                            ),
                            _buildScoringInput(
                              label: '40+ Yard TD',
                              value: _bonus40YardTd,
                              onChanged: (v) => setState(() => _bonus40YardTd = v.toInt()),
                            ),
                            const SizedBox(height: 12),

                            // Misc
                            Text('Miscellaneous', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colorScheme.primary)),
                            const SizedBox(height: 4),
                            _buildScoringInput(
                              label: 'Fumble Lost',
                              value: _fumbleLostPoints,
                              onChanged: (v) => setState(() => _fumbleLostPoints = v.toInt()),
                              allowNegative: true,
                            ),
                            _buildScoringInput(
                              label: '2PT Conversion',
                              value: _twoPtConversion,
                              onChanged: (v) => setState(() => _twoPtConversion = v.toInt()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                isPublic: _isPublic,
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
    required bool isPublic,
  }) onCreateLeague,
}) {
  showDialog(
    context: context,
    builder: (context) => CreateLeagueDialog(onCreateLeague: onCreateLeague),
  );
}
