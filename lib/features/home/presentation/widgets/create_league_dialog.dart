import 'package:flutter/material.dart';

class CreateLeagueDialog extends StatefulWidget {
  final Future<void> Function({
    required String name,
    required String season,
    required int totalRosters,
    required Map<String, dynamic> scoringSettings,
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
  }) onCreateLeague,
}) {
  showDialog(
    context: context,
    builder: (context) => CreateLeagueDialog(onCreateLeague: onCreateLeague),
  );
}
