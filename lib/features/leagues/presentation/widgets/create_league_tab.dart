import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/scoring_settings_editor.dart';
import '../../../home/presentation/widgets/roster_config_editor.dart';
import '../../data/league_repository.dart';
import 'draft_structure_selector.dart';

class CreateLeagueTab extends ConsumerStatefulWidget {
  const CreateLeagueTab({super.key});

  @override
  ConsumerState<CreateLeagueTab> createState() => _CreateLeagueTabState();
}

class _CreateLeagueTabState extends ConsumerState<CreateLeagueTab>
    with AutomaticKeepAliveClientMixin {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;

  // Season from Sleeper API (read-only)
  String? _leagueCreateSeason;
  bool _isLoadingSeason = true;

  // Basic settings
  int _selectedRosters = 12;
  String _selectedLeagueMode = 'redraft';
  bool _isPublic = false;
  int _rookieDraftRounds = 5;
  String _draftStructure = 'combined';

  // Extracted settings models
  final _scoringSettings = ScoringSettings();
  final _rosterConfig = RosterConfig();

  // Expansion state
  bool _rosterConfigExpanded = false;
  bool _scoringExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNflState();
  }

  Future<void> _loadNflState() async {
    try {
      final nflState = await ref.read(leagueRepositoryProvider).getNflState();
      if (mounted) {
        setState(() {
          _leagueCreateSeason = nflState['league_create_season'] as String?;
          _isLoadingSeason = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fallback to current year if API fails
          _leagueCreateSeason = DateTime.now().year.toString();
          _isLoadingSeason = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeagueNameField(),
                const SizedBox(height: 16),
                _buildSeasonDisplay(),
                const SizedBox(height: 16),
                _buildTeamCountDropdown(),
                const SizedBox(height: 16),
                _buildLeagueModeDropdown(),
                const SizedBox(height: 16),
                DraftStructureSelector(
                  leagueMode: _selectedLeagueMode,
                  selectedStructure: _draftStructure,
                  onChanged: (value) {
                    setState(() => _draftStructure = value);
                  },
                ),
                if (_selectedLeagueMode == 'dynasty' || _selectedLeagueMode == 'devy') ...[
                  const SizedBox(height: 16),
                  _buildRookieDraftRoundsInput(),
                ],
                const SizedBox(height: 16),
                _buildPublicToggle(colorScheme),
                const SizedBox(height: 12),
                ScoringSettingsEditor(
                  settings: _scoringSettings,
                  isExpanded: _scoringExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _scoringExpanded = expanded);
                  },
                  onSettingsChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                RosterConfigEditor(
                  config: _rosterConfig,
                  isExpanded: _rosterConfigExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _rosterConfigExpanded = expanded);
                  },
                  onConfigChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isCreating ? null : _handleCreate,
                  icon: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: Text(_isCreating ? 'Creating...' : 'Create League'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'League Name',
        hintText: 'Enter league name',
        border: OutlineInputBorder(),
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
    );
  }

  Widget _buildSeasonDisplay() {
    if (_isLoadingSeason) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Season',
          border: OutlineInputBorder(),
        ),
        child: SizedBox(
          height: 24,
          child: Center(child: LinearProgressIndicator()),
        ),
      );
    }
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Season',
        border: OutlineInputBorder(),
      ),
      child: Text(
        _leagueCreateSeason ?? 'Unknown',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildTeamCountDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedRosters,
      decoration: const InputDecoration(
        labelText: 'Number of Teams',
        border: OutlineInputBorder(),
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
    );
  }

  Widget _buildLeagueModeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedLeagueMode,
      decoration: const InputDecoration(
        labelText: 'League Mode',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'redraft', child: Text('Redraft')),
        DropdownMenuItem(value: 'keeper', child: Text('Keeper')),
        DropdownMenuItem(value: 'dynasty', child: Text('Dynasty')),
        DropdownMenuItem(value: 'devy', child: Text('Devy')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedLeagueMode = value;
            // Reset draft structure to 'combined' when mode changes
            _draftStructure = 'combined';
          });
        }
      },
    );
  }

  Widget _buildRookieDraftRoundsInput() {
    final colorScheme = Theme.of(context).colorScheme;

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
                    ? () => setState(() => _rookieDraftRounds--)
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
                    ? () => setState(() => _rookieDraftRounds++)
                    : null,
              ),
            ],
          ),
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
                      : 'Invite members directly to join',
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
    );
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_leagueCreateSeason == null) return;

    setState(() => _isCreating = true);

    try {
      await ref.read(myLeaguesProvider.notifier).createLeague(
            name: _nameController.text,
            season: _leagueCreateSeason!,
            totalRosters: _selectedRosters,
            scoringSettings: _scoringSettings.toJson(),
            mode: _selectedLeagueMode,
            settings: {
              'roster_config': _rosterConfig.toJson(),
              if (_selectedLeagueMode == 'dynasty' || _selectedLeagueMode == 'devy')
                'rookie_draft_rounds': _rookieDraftRounds,
            },
            isPublic: _isPublic,
            draftStructure: _draftStructure,
          );

      if (!mounted) return;

      // Get the created league from state
      final leaguesState = ref.read(myLeaguesProvider);
      if (leaguesState.error == null && leaguesState.leagues.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('League created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigate back to leagues screen
        context.pop();
      } else if (leaguesState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leaguesState.error!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
