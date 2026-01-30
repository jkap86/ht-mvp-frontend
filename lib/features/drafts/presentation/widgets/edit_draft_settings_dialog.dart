import 'package:flutter/material.dart';

import '../../../leagues/domain/league.dart';
import '../../domain/draft_status.dart';
import 'draft_auction_settings.dart';
import 'draft_timing_settings.dart';
import 'draft_type_settings.dart';

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
  State<EditDraftSettingsDialog> createState() =>
      _EditDraftSettingsDialogState();
}

class _EditDraftSettingsDialogState extends State<EditDraftSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _error;

  late String _draftType;
  late TextEditingController _roundsController;
  late TextEditingController _pickTimeController;

  // Auction timing settings
  late TextEditingController _bidWindowController;
  late TextEditingController _nominationSecondsController;
  late TextEditingController _resetOnBidSecondsController;
  late TextEditingController _minIncrementController;

  // Auction mode and nomination limits
  late String _auctionMode;
  late TextEditingController _maxActivePerTeamController;
  late TextEditingController _maxActiveGlobalController;
  late TextEditingController _dailyNominationLimitController;

  bool get _isNotStarted => widget.draft.status == DraftStatus.notStarted;
  bool get _isPaused => widget.draft.status == DraftStatus.paused;
  bool get _canEditStructural => _isNotStarted;
  bool get _canEditTimers => _isNotStarted || _isPaused;
  bool get _isAuction => _draftType == 'auction';

  @override
  void initState() {
    super.initState();
    _draftType = widget.draft.draftType.name;
    _roundsController =
        TextEditingController(text: widget.draft.rounds.toString());
    _pickTimeController =
        TextEditingController(text: widget.draft.pickTimeSeconds.toString());

    final settings =
        (widget.draft.settings as Map<String, dynamic>?) ?? <String, dynamic>{};

    // Auction timing settings
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

    // Auction mode and nomination limits
    _auctionMode = (settings['auctionMode'] as String?) ?? 'slow';
    _maxActivePerTeamController = TextEditingController(
      text: (settings['maxActiveNominationsPerTeam'] ?? 2).toString(),
    );
    _maxActiveGlobalController = TextEditingController(
      text: (settings['maxActiveNominationsGlobal'] ?? 25).toString(),
    );
    _dailyNominationLimitController = TextEditingController(
      text: settings['dailyNominationLimit']?.toString() ?? '',
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
    _maxActivePerTeamController.dispose();
    _maxActiveGlobalController.dispose();
    _dailyNominationLimitController.dispose();
    super.dispose();
  }

  String? _validatePositiveInt(String? value,
      {int? min, int? max, String? fieldName}) {
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
          final settings =
              (widget.draft.settings as Map<String, dynamic>?) ??
                  <String, dynamic>{};

          final newBidWindow = int.parse(_bidWindowController.text);
          final newNominationSeconds =
              int.parse(_nominationSecondsController.text);
          final newResetOnBid = int.parse(_resetOnBidSecondsController.text);
          final newMinIncrement = int.parse(_minIncrementController.text);
          final newMaxPerTeam = int.parse(_maxActivePerTeamController.text);
          final newMaxGlobal = int.parse(_maxActiveGlobalController.text);
          final newDailyLimit = _dailyNominationLimitController.text.isEmpty
              ? null
              : int.parse(_dailyNominationLimitController.text);

          // Check for changes
          final hasTimingChanges =
              newBidWindow != (settings['bidWindowSeconds'] ?? 43200) ||
                  newNominationSeconds !=
                      (settings['nominationSeconds'] ?? 45) ||
                  newResetOnBid != (settings['resetOnBidSeconds'] ?? 10) ||
                  newMinIncrement != (settings['minIncrement'] ?? 1);

          final hasModeChange = _canEditStructural &&
              _auctionMode != (settings['auctionMode'] ?? 'slow');

          final hasLimitChanges =
              newMaxPerTeam !=
                  (settings['maxActiveNominationsPerTeam'] ?? 2) ||
                  newMaxGlobal !=
                      (settings['maxActiveNominationsGlobal'] ?? 25) ||
                  newDailyLimit != settings['dailyNominationLimit'];

          if (hasTimingChanges || hasModeChange || hasLimitChanges) {
            auctionSettings = {
              'bid_window_seconds': newBidWindow,
              'nomination_seconds': newNominationSeconds,
              'reset_on_bid_seconds': newResetOnBid,
              'min_increment': newMinIncrement,
              'max_active_nominations_per_team': newMaxPerTeam,
              'max_active_nominations_global': newMaxGlobal,
              if (newDailyLimit != null) 'daily_nomination_limit': newDailyLimit,
            };

            // Only include auction_mode if we can edit it
            if (_canEditStructural) {
              auctionSettings['auction_mode'] = _auctionMode;
            }
          }
        }
      }

      // Only call onSave if there are changes
      if (draftType != null ||
          rounds != null ||
          pickTimeSeconds != null ||
          auctionSettings != null) {
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
              // Error message
              if (_error != null) ...[
                _buildErrorBanner(theme),
                const SizedBox(height: 16),
              ],

              // Paused status info
              if (_isPaused) ...[
                _buildInfoBanner(theme),
                const SizedBox(height: 16),
              ],

              // Draft Type and Rounds
              DraftTypeSettings(
                draftType: _draftType,
                roundsController: _roundsController,
                enabled: _canEditStructural,
                onDraftTypeChanged: (value) =>
                    setState(() => _draftType = value!),
                roundsValidator: (v) =>
                    _validatePositiveInt(v, min: 1, max: 30, fieldName: 'Rounds'),
              ),

              const SizedBox(height: 16),

              // Pick Time (for snake/linear)
              if (!_isAuction)
                DraftTimingSettings(
                  pickTimeController: _pickTimeController,
                  enabled: _canEditTimers,
                  validator: (v) => _validatePositiveInt(v,
                      min: 30, max: 600, fieldName: 'Pick time'),
                ),

              // Auction settings
              if (_isAuction)
                DraftAuctionSettings(
                  bidWindowController: _bidWindowController,
                  nominationSecondsController: _nominationSecondsController,
                  resetOnBidSecondsController: _resetOnBidSecondsController,
                  minIncrementController: _minIncrementController,
                  auctionMode: _auctionMode,
                  onAuctionModeChanged: (mode) =>
                      setState(() => _auctionMode = mode),
                  canEditMode: _canEditStructural,
                  maxActivePerTeamController: _maxActivePerTeamController,
                  maxActiveGlobalController: _maxActiveGlobalController,
                  dailyNominationLimitController: _dailyNominationLimitController,
                  enabled: _canEditTimers,
                  validator: _validatePositiveInt,
                ),
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

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
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
    );
  }

  Widget _buildInfoBanner(ThemeData theme) {
    return Container(
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
    );
  }
}
