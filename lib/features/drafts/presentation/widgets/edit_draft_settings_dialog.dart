import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../leagues/domain/league.dart';
import '../../domain/draft_status.dart';

/// Dialog for editing draft settings (commissioner only).
/// Settings editable depend on draft status:
/// - not_started: All settings
/// - paused: Timer settings only
/// - in_progress/completed: None (dialog won't show)
class EditDraftSettingsDialog extends StatefulWidget {
  final Draft draft;
  final Future<void> Function({
    String? draftType,
    int? rounds,
    int? pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
  }) onSave;

  const EditDraftSettingsDialog({
    super.key,
    required this.draft,
    required this.onSave,
  });

  /// Shows the edit draft settings dialog.
  static Future<void> show(
    BuildContext context, {
    required Draft draft,
    required Future<void> Function({
      String? draftType,
      int? rounds,
      int? pickTimeSeconds,
      Map<String, dynamic>? auctionSettings,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditDraftSettingsDialog(
        draft: draft,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditDraftSettingsDialog> createState() => _EditDraftSettingsDialogState();
}

class _EditDraftSettingsDialogState extends State<EditDraftSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _error;

  late String _draftType;
  late TextEditingController _roundsController;
  late TextEditingController _pickTimeController;
  late TextEditingController _bidWindowController;
  late TextEditingController _nominationSecondsController;
  late TextEditingController _resetOnBidSecondsController;
  late TextEditingController _minIncrementController;

  bool get _isNotStarted => widget.draft.status == DraftStatus.notStarted;
  bool get _isPaused => widget.draft.status == DraftStatus.paused;
  bool get _canEditStructural => _isNotStarted;
  bool get _canEditTimers => _isNotStarted || _isPaused;
  bool get _isAuction => _draftType == 'auction';

  @override
  void initState() {
    super.initState();
    _draftType = widget.draft.draftType.name;
    _roundsController = TextEditingController(text: widget.draft.rounds.toString());
    _pickTimeController = TextEditingController(text: widget.draft.pickTimeSeconds.toString());

    final settings = (widget.draft.settings as Map<String, dynamic>?) ?? <String, dynamic>{};
    _bidWindowController = TextEditingController(
      text: (settings['bidWindowSeconds'] ?? 43200).toString(),
    );
    _nominationSecondsController = TextEditingController(
      text: (settings['nominationSeconds'] ?? 45).toString(),
    );
    _resetOnBidSecondsController = TextEditingController(
      text: (settings['resetOnBidSeconds'] ?? 10).toString(),
    );
    _minIncrementController = TextEditingController(
      text: (settings['minIncrement'] ?? 1).toString(),
    );
  }

  @override
  void dispose() {
    _roundsController.dispose();
    _pickTimeController.dispose();
    _bidWindowController.dispose();
    _nominationSecondsController.dispose();
    _resetOnBidSecondsController.dispose();
    _minIncrementController.dispose();
    super.dispose();
  }

  String? _validatePositiveInt(String? value, {int? min, int? max, String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Must be a number';
    }
    if (min != null && parsed < min) {
      return '${fieldName ?? 'Value'} must be at least $min';
    }
    if (max != null && parsed > max) {
      return '${fieldName ?? 'Value'} cannot exceed $max';
    }
    return null;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      // Build the update payload
      String? draftType;
      int? rounds;
      int? pickTimeSeconds;
      Map<String, dynamic>? auctionSettings;

      if (_canEditStructural) {
        if (_draftType != widget.draft.draftType.name) {
          draftType = _draftType;
        }
        final newRounds = int.parse(_roundsController.text);
        if (newRounds != widget.draft.rounds) {
          rounds = newRounds;
        }
      }

      if (_canEditTimers) {
        final newPickTime = int.parse(_pickTimeController.text);
        if (newPickTime != widget.draft.pickTimeSeconds) {
          pickTimeSeconds = newPickTime;
        }

        if (_isAuction) {
          final newBidWindow = int.parse(_bidWindowController.text);
          final newNominationSeconds = int.parse(_nominationSecondsController.text);
          final newResetOnBid = int.parse(_resetOnBidSecondsController.text);
          final newMinIncrement = int.parse(_minIncrementController.text);

          final settings = (widget.draft.settings as Map<String, dynamic>?) ?? <String, dynamic>{};
          final hasChanges = newBidWindow != (settings['bidWindowSeconds'] ?? 43200) ||
              newNominationSeconds != (settings['nominationSeconds'] ?? 45) ||
              newResetOnBid != (settings['resetOnBidSeconds'] ?? 10) ||
              newMinIncrement != (settings['minIncrement'] ?? 1);

          if (hasChanges) {
            auctionSettings = {
              'bid_window_seconds': newBidWindow,
              'nomination_seconds': newNominationSeconds,
              'reset_on_bid_seconds': newResetOnBid,
              'min_increment': newMinIncrement,
            };
          }
        }
      }

      // Only call onSave if there are changes
      if (draftType != null || rounds != null || pickTimeSeconds != null || auctionSettings != null) {
        await widget.onSave(
          draftType: draftType,
          rounds: rounds,
          pickTimeSeconds: pickTimeSeconds,
          auctionSettings: auctionSettings,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Draft Settings'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_isPaused) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Draft is paused. Only timer settings can be changed.',
                          style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Draft Type
              Text('Draft Type', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _draftType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'snake', child: Text('Snake')),
                  DropdownMenuItem(value: 'linear', child: Text('Linear')),
                  DropdownMenuItem(value: 'auction', child: Text('Auction')),
                ],
                onChanged: _canEditStructural
                    ? (value) => setState(() => _draftType = value!)
                    : null,
              ),

              const SizedBox(height: 16),

              // Rounds
              Text('Rounds', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _roundsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Number of rounds',
                  helperText: '1-30 rounds',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => _validatePositiveInt(v, min: 1, max: 30, fieldName: 'Rounds'),
                enabled: _canEditStructural,
              ),

              const SizedBox(height: 16),

              // Pick Time (for snake/linear)
              if (!_isAuction) ...[
                Text('Pick Time (seconds)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pickTimeController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seconds per pick',
                    helperText: '30-600 seconds',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validatePositiveInt(v, min: 30, max: 600, fieldName: 'Pick time'),
                  enabled: _canEditTimers,
                ),
              ],

              // Auction settings
              if (_isAuction) ...[
                const Divider(height: 24),
                Text('Auction Settings', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),

                Text('Bid Window (seconds)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bidWindowController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seconds for bidding',
                    helperText: '3600-172800 (1 hour to 2 days)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validatePositiveInt(v, min: 3600, max: 172800, fieldName: 'Bid window'),
                  enabled: _canEditTimers,
                ),

                const SizedBox(height: 16),

                Text('Nomination Time (seconds)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nominationSecondsController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seconds for nomination',
                    helperText: '15-120 seconds',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validatePositiveInt(v, min: 15, max: 120, fieldName: 'Nomination time'),
                  enabled: _canEditTimers,
                ),

                const SizedBox(height: 16),

                Text('Bid Reset Time (seconds)', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _resetOnBidSecondsController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Seconds to add on new bid',
                    helperText: '5-30 seconds',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validatePositiveInt(v, min: 5, max: 30, fieldName: 'Reset time'),
                  enabled: _canEditTimers,
                ),

                const SizedBox(height: 16),

                Text('Minimum Bid Increment', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minIncrementController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Minimum bid increment',
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => _validatePositiveInt(v, min: 1, fieldName: 'Min increment'),
                  enabled: _canEditTimers,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
