import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/scoring_settings_editor.dart';
import '../../../home/presentation/widgets/roster_config_editor.dart';
import '../providers/commissioner_provider.dart';

/// Card for editing league settings (commissioner only)
class EditLeagueCard extends ConsumerStatefulWidget {
  final int leagueId;
  final CommissionerState state;

  const EditLeagueCard({
    super.key,
    required this.leagueId,
    required this.state,
  });

  @override
  ConsumerState<EditLeagueCard> createState() => _EditLeagueCardState();
}

class _EditLeagueCardState extends ConsumerState<EditLeagueCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late String _selectedMode;
  late bool _isPublic;
  late int _rookieDraftRounds;
  late int _totalRosters;

  late ScoringSettings _scoringSettings;
  late RosterConfig _rosterConfig;

  bool _scoringExpanded = false;
  bool _rosterConfigExpanded = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeFromLeague();
  }

  @override
  void didUpdateWidget(EditLeagueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.league?.id != widget.state.league?.id) {
      _initializeFromLeague();
    }
  }

  void _initializeFromLeague() {
    final league = widget.state.league;
    if (league == null) return;

    _nameController.text = league.name;
    _selectedMode = league.mode;
    _isPublic = league.isPublic;
    _rookieDraftRounds = league.settings['rookie_draft_rounds'] as int? ?? 5;
    _totalRosters = league.totalRosters;

    _scoringSettings = _parseScoringSettings(league.settings['scoring_settings']);
    _rosterConfig = _parseRosterConfig(league.settings['roster_config']);
    _hasChanges = false;
  }

  ScoringSettings _parseScoringSettings(Map<String, dynamic>? json) {
    if (json == null) return ScoringSettings();

    return ScoringSettings(
      passingTdPoints: (json['pass_td'] as num?)?.toInt() ?? 4,
      passingYardsPerPoint: json['pass_yd'] != null && json['pass_yd'] != 0
          ? (1.0 / (json['pass_yd'] as num)).round()
          : 25,
      interceptionPoints: (json['pass_int'] as num?)?.toInt() ?? -1,
      rushingTdPoints: (json['rush_td'] as num?)?.toInt() ?? 6,
      rushingYardsPerPoint: json['rush_yd'] != null && json['rush_yd'] != 0
          ? (1.0 / (json['rush_yd'] as num)).round()
          : 10,
      pprValue: (json['rec'] as num?)?.toDouble() ?? 1.0,
      receivingTdPoints: (json['rec_td'] as num?)?.toInt() ?? 6,
      receivingYardsPerPoint: json['rec_yd'] != null && json['rec_yd'] != 0
          ? (1.0 / (json['rec_yd'] as num)).round()
          : 10,
      tePremium: (json['te_premium'] as num?)?.toDouble() ?? 0.0,
      bonus100YardRush: (json['bonus_rush_yd_100'] as num?)?.toInt() ?? 0,
      bonus100YardRec: (json['bonus_rec_yd_100'] as num?)?.toInt() ?? 0,
      bonus300YardPass: (json['bonus_pass_yd_300'] as num?)?.toInt() ?? 0,
      bonus40YardTd: (json['bonus_40_yd_td'] as num?)?.toInt() ?? 0,
      fumbleLostPoints: (json['fum_lost'] as num?)?.toInt() ?? -2,
      twoPtConversion: (json['two_pt'] as num?)?.toInt() ?? 2,
    );
  }

  RosterConfig _parseRosterConfig(Map<String, dynamic>? json) {
    if (json == null) return RosterConfig();

    return RosterConfig(
      qbSlots: (json['QB'] as num?)?.toInt() ?? 1,
      rbSlots: (json['RB'] as num?)?.toInt() ?? 2,
      wrSlots: (json['WR'] as num?)?.toInt() ?? 2,
      teSlots: (json['TE'] as num?)?.toInt() ?? 1,
      flexSlots: (json['FLEX'] as num?)?.toInt() ?? 1,
      superFlexSlots: (json['SUPER_FLEX'] as num?)?.toInt() ?? 0,
      recFlexSlots: (json['REC_FLEX'] as num?)?.toInt() ?? 0,
      kSlots: (json['K'] as num?)?.toInt() ?? 1,
      defSlots: (json['DEF'] as num?)?.toInt() ?? 1,
      dlSlots: (json['DL'] as num?)?.toInt() ?? 0,
      lbSlots: (json['LB'] as num?)?.toInt() ?? 0,
      dbSlots: (json['DB'] as num?)?.toInt() ?? 0,
      idpFlexSlots: (json['IDP_FLEX'] as num?)?.toInt() ?? 0,
      bnSlots: (json['BN'] as num?)?.toInt() ?? 6,
      irSlots: (json['IR'] as num?)?.toInt() ?? 0,
      taxiSlots: (json['TAXI'] as num?)?.toInt() ?? 0,
    );
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final league = widget.state.league;
    if (league == null) return;

    // Build settings map, preserving existing settings
    final updatedSettings = Map<String, dynamic>.from(league.settings);
    updatedSettings['roster_config'] = _rosterConfig.toJson();
    if (_selectedMode == 'dynasty') {
      updatedSettings['rookie_draft_rounds'] = _rookieDraftRounds;
    }

    final success = await ref.read(commissionerProvider(widget.leagueId).notifier).updateLeague(
      name: _nameController.text != league.name ? _nameController.text : null,
      mode: _selectedMode != league.mode ? _selectedMode : null,
      isPublic: _isPublic != league.isPublic ? _isPublic : null,
      settings: updatedSettings,
      scoringSettings: _scoringSettings.toJson(),
      totalRosters: _totalRosters != league.totalRosters ? _totalRosters : null,
    );

    if (success) {
      setState(() => _hasChanges = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final league = widget.state.league;
    if (league == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings),
                  const SizedBox(width: 8),
                  Text(
                    'Edit League Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // League Name
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
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: 16),

              // League Mode
              DropdownButtonFormField<String>(
                value: _selectedMode,
                decoration: const InputDecoration(labelText: 'League Mode'),
                items: const [
                  DropdownMenuItem(value: 'redraft', child: Text('Redraft')),
                  DropdownMenuItem(value: 'keeper', child: Text('Keeper')),
                  DropdownMenuItem(value: 'dynasty', child: Text('Dynasty')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedMode = value);
                    _markChanged();
                  }
                },
              ),

              // Rookie Draft Rounds (only for dynasty)
              if (_selectedMode == 'dynasty') ...[
                const SizedBox(height: 16),
                _buildRookieDraftRoundsInput(colorScheme),
              ],

              const SizedBox(height: 16),

              // Team Count - only show pre-draft
              if (league.status == 'pre_draft') ...[
                _buildTeamCountSelector(colorScheme),
                const SizedBox(height: 12),
              ],

              // Public Toggle
              _buildPublicToggle(colorScheme),

              const SizedBox(height: 12),

              // Scoring Settings Editor
              ScoringSettingsEditor(
                settings: _scoringSettings,
                isExpanded: _scoringExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _scoringExpanded = expanded);
                },
                onSettingsChanged: () {
                  setState(() {});
                  _markChanged();
                },
              ),

              const SizedBox(height: 12),

              // Roster Config Editor
              RosterConfigEditor(
                config: _rosterConfig,
                isExpanded: _rosterConfigExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _rosterConfigExpanded = expanded);
                },
                onConfigChanged: () {
                  setState(() {});
                  _markChanged();
                },
                leagueMode: _selectedMode,
              ),

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _hasChanges ? _handleSave : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRookieDraftRoundsInput(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Rookie Draft Rounds',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Number of rounds for annual rookie drafts',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _rookieDraftRounds > 1
                    ? () {
                        setState(() => _rookieDraftRounds--);
                        _markChanged();
                      }
                    : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_rookieDraftRounds',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _rookieDraftRounds < 10
                    ? () {
                        setState(() => _rookieDraftRounds++);
                        _markChanged();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCountSelector(ColorScheme colorScheme) {
    // Count active (non-benched) members
    final activeMembers = widget.state.members.where((m) => m['is_benched'] != true).length;
    final benchedMembers = widget.state.members.where((m) => m['is_benched'] == true).length;
    final willBenchMembers = _totalRosters < activeMembers;
    final membersToBlench = willBenchMembers ? activeMembers - _totalRosters : 0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: willBenchMembers
              ? colorScheme.error.withAlpha(128)
              : colorScheme.outlineVariant.withAlpha(128),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Team Count',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Maximum number of active teams in the league',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$activeMembers active${benchedMembers > 0 ? ', $benchedMembers benched' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _totalRosters > 2
                    ? () {
                        setState(() => _totalRosters--);
                        _markChanged();
                      }
                    : null,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$_totalRosters',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _totalRosters < 20
                    ? () {
                        setState(() => _totalRosters++);
                        _markChanged();
                      }
                    : null,
              ),
            ],
          ),
          if (willBenchMembers) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$membersToBlench member${membersToBlench > 1 ? 's' : ''} will become viewers.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPublicToggle(ColorScheme colorScheme) {
    return Container(
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
            onChanged: (value) {
              setState(() => _isPublic = value);
              _markChanged();
            },
          ),
        ],
      ),
    );
  }
}
