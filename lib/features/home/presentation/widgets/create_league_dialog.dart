import 'package:flutter/material.dart';

import 'scoring_settings_editor.dart';
import 'roster_config_editor.dart';

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

  // Basic settings
  String _selectedSeason = DateTime.now().year.toString();
  int _selectedRosters = 12;
  String _selectedLeagueMode = 'redraft';
  bool _isPublic = false;

  // Extracted settings models
  final _scoringSettings = ScoringSettings();
  final _rosterConfig = RosterConfig();

  // Expansion state
  bool _rosterConfigExpanded = false;
  bool _scoringExpanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                _buildLeagueNameField(),
                const SizedBox(height: 16),
                _buildSeasonDropdown(),
                const SizedBox(height: 16),
                _buildTeamCountDropdown(),
                const SizedBox(height: 16),
                _buildLeagueModeDropdown(),
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
          child: Text('Cancel',
              style: TextStyle(color: colorScheme.onSurface.withAlpha(179))),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _handleCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create League'),
        ),
      ],
    );
  }

  Widget _buildLeagueNameField() {
    return TextFormField(
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
    );
  }

  Widget _buildSeasonDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSeason,
      decoration: const InputDecoration(labelText: 'Season'),
      items: [
        for (int year = DateTime.now().year; year <= DateTime.now().year + 1; year++)
          DropdownMenuItem(value: year.toString(), child: Text(year.toString())),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedSeason = value);
        }
      },
    );
  }

  Widget _buildTeamCountDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedRosters,
      decoration: const InputDecoration(labelText: 'Number of Teams'),
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
      decoration: const InputDecoration(labelText: 'League Mode'),
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
            onChanged: (value) => setState(() => _isPublic = value),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      await widget.onCreateLeague(
        name: _nameController.text,
        season: _selectedSeason,
        totalRosters: _selectedRosters,
        scoringSettings: _scoringSettings.toJson(),
        mode: _selectedLeagueMode,
        settings: {
          'roster_config': _rosterConfig.toJson(),
        },
        isPublic: _isPublic,
      );
    }
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
