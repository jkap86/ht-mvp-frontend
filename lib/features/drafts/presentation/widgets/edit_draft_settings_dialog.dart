import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_sanitizer.dart';
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
  final String leagueMode;
  final Future<void> Function({
    String? draftType,
    int? rounds,
    int? pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
    List<String>? playerPool,
    bool? includeRookiePicks,
    int? rookiePicksSeason,
    int? rookiePicksRounds,
  }) onSave;

  const EditDraftSettingsDialog({
    super.key,
    required this.draft,
    required this.leagueMode,
    required this.onSave,
  });

  /// Shows the edit draft settings dialog.
  static Future<void> show(
    BuildContext context, {
    required Draft draft,
    required String leagueMode,
    required Future<void> Function({
      String? draftType,
      int? rounds,
      int? pickTimeSeconds,
      Map<String, dynamic>? auctionSettings,
      List<String>? playerPool,
      bool? includeRookiePicks,
      int? rookiePicksSeason,
      int? rookiePicksRounds,
    }) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditDraftSettingsDialog(
        draft: draft,
        leagueMode: leagueMode,
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

  // Player pool
  late Set<String> _selectedPlayerPool;

  // Rookie draft picks settings
  late bool _includeRookiePicks;
  late TextEditingController _rookiePicksSeasonController;
  late int _rookiePicksRounds;

  bool get _isNotStarted => widget.draft.status == DraftStatus.notStarted;
  bool get _isPaused => widget.draft.status == DraftStatus.paused;
  bool get _canEditStructural => _isNotStarted;
  bool get _canEditTimers => _isNotStarted || _isPaused;
  bool get _isAuction => _draftType == 'auction';
  bool get _isSlowAuction => _isAuction && _auctionMode == 'slow';
  bool get _isDevyLeague => widget.leagueMode == 'devy';
  bool get _isVetOnlyDraft => _selectedPlayerPool.length == 1 && _selectedPlayerPool.contains('veteran');

  @override
  void initState() {
    super.initState();
    _draftType = widget.draft.draftType.name;
    _roundsController =
        TextEditingController(text: widget.draft.rounds.toString());
    _pickTimeController =
        TextEditingController(text: widget.draft.pickTimeSeconds.toString());

    final settings = widget.draft.settings;

    // Auction timing settings
    _bidWindowController = TextEditingController(
      text: (settings?.bidWindowSeconds ?? 43200).toString(),
    );
    _nominationSecondsController = TextEditingController(
      text: (settings?.nominationSeconds ?? 45).toString(),
    );
    _resetOnBidSecondsController = TextEditingController(
      text: (settings?.resetOnBidSeconds ?? 10).toString(),
    );
    _minIncrementController = TextEditingController(
      text: (settings?.minIncrement ?? 1).toString(),
    );

    // Auction mode and nomination limits
    _auctionMode = settings?.auctionMode ?? 'slow';
    _maxActivePerTeamController = TextEditingController(
      text: (settings?.maxActiveNominationsPerTeam ?? 2).toString(),
    );
    _maxActiveGlobalController = TextEditingController(
      text: '25', // Default - not stored in AuctionSettings
    );
    _dailyNominationLimitController = TextEditingController(
      text: '', // Default - not stored in AuctionSettings
    );

    // Player pool - read from rawSettings, default to veteran + rookie if not set
    final rawPlayerPool = widget.draft.rawSettings?['playerPool'];
    _selectedPlayerPool = Set<String>.from(
      rawPlayerPool is List ? rawPlayerPool.cast<String>() : ['veteran', 'rookie'],
    );

    // Rookie draft picks settings - read from rawSettings
    _includeRookiePicks = widget.draft.rawSettings?['includeRookiePicks'] ?? false;
    final currentYear = DateTime.now().year;
    final rookiePicksSeason = widget.draft.rawSettings?['rookiePicksSeason'] ?? currentYear;
    _rookiePicksSeasonController = TextEditingController(text: rookiePicksSeason.toString());
    _rookiePicksRounds = widget.draft.rawSettings?['rookiePicksRounds'] ?? 5;
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
    _rookiePicksSeasonController.dispose();
    super.dispose();
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final element in a) {
      if (!b.contains(element)) return false;
    }
    return true;
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
      List<String>? playerPool;

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
          final settings = widget.draft.settings;

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
              newBidWindow != (settings?.bidWindowSeconds ?? 43200) ||
                  newNominationSeconds !=
                      (settings?.nominationSeconds ?? 45) ||
                  newResetOnBid != (settings?.resetOnBidSeconds ?? 10) ||
                  newMinIncrement != (settings?.minIncrement ?? 1);

          final hasModeChange = _canEditStructural &&
              _auctionMode != (settings?.auctionMode ?? 'slow');

          final hasLimitChanges =
              newMaxPerTeam !=
                  (settings?.maxActiveNominationsPerTeam ?? 2) ||
                  newMaxGlobal != 25 || // Default - not stored in AuctionSettings
                  newDailyLimit != null; // Default is no limit

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

      // Check for player pool changes
      bool? includeRookiePicks;
      int? rookiePicksSeason;
      int? rookiePicksRounds;
      if (_canEditStructural) {
        final rawPlayerPool = widget.draft.rawSettings?['playerPool'];
        final originalPool = Set<String>.from(
          rawPlayerPool is List ? rawPlayerPool.cast<String>() : ['veteran', 'rookie'],
        );
        if (!_setEquals(_selectedPlayerPool, originalPool)) {
          playerPool = _selectedPlayerPool.toList();
        }

        // Check for rookie picks settings changes (only for vet-only drafts)
        final originalIncludeRookiePicks = widget.draft.rawSettings?['includeRookiePicks'] ?? false;
        final originalRookiePicksSeason = widget.draft.rawSettings?['rookiePicksSeason'];
        final originalRookiePicksRounds = widget.draft.rawSettings?['rookiePicksRounds'] ?? 5;

        if (_includeRookiePicks != originalIncludeRookiePicks) {
          includeRookiePicks = _includeRookiePicks;
        }

        if (_includeRookiePicks && _rookiePicksSeasonController.text.isNotEmpty) {
          final newSeason = int.tryParse(_rookiePicksSeasonController.text);
          if (newSeason != null && newSeason != originalRookiePicksSeason) {
            rookiePicksSeason = newSeason;
          }
          // Also set season if includeRookiePicks is being enabled for the first time
          if (includeRookiePicks == true && rookiePicksSeason == null) {
            rookiePicksSeason = newSeason;
          }
        }

        // Check for rounds change
        if (_includeRookiePicks && _rookiePicksRounds != originalRookiePicksRounds) {
          rookiePicksRounds = _rookiePicksRounds;
        }
        // Also set rounds if includeRookiePicks is being enabled for the first time
        if (includeRookiePicks == true && rookiePicksRounds == null) {
          rookiePicksRounds = _rookiePicksRounds;
        }
      }

      // Only call onSave if there are changes
      if (draftType != null ||
          rounds != null ||
          pickTimeSeconds != null ||
          auctionSettings != null ||
          playerPool != null ||
          includeRookiePicks != null ||
          rookiePicksSeason != null ||
          rookiePicksRounds != null) {
        await widget.onSave(
          draftType: draftType,
          rounds: rounds,
          pickTimeSeconds: pickTimeSeconds,
          auctionSettings: auctionSettings,
          playerPool: playerPool,
          includeRookiePicks: includeRookiePicks,
          rookiePicksSeason: rookiePicksSeason,
          rookiePicksRounds: rookiePicksRounds,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = ErrorSanitizer.sanitize(e);
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
                    _validatePositiveInt(v, min: 1, max: 30, fieldName: _isSlowAuction ? 'Max nominations' : 'Rounds'),
                isSlowAuction: _isSlowAuction,
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

              // Player Pool (only when structural edits are allowed)
              if (_canEditStructural) ...[
                const SizedBox(height: 16),
                _buildPlayerPoolSection(theme),
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

  Widget _buildPlayerPoolSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Player Pool', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildPoolCheckbox(
          theme,
          'veteran',
          'Veterans',
          'NFL players with 1+ years experience',
        ),
        _buildPoolCheckbox(
          theme,
          'rookie',
          'Rookies',
          'First-year NFL players',
        ),
        _buildPoolCheckbox(
          theme,
          'college',
          'College',
          _isDevyLeague ? 'College players' : 'Only available in Devy leagues',
        ),
        // Rookie draft picks option (only for vet-only drafts)
        if (_isVetOnlyDraft) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildRookiePicksSettings(theme),
        ],
      ],
    );
  }

  Widget _buildRookiePicksSettings(ThemeData theme) {
    final currentYear = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rookie Draft Picks', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Include rookie draft picks as draftable items',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _includeRookiePicks,
          onChanged: (value) => setState(() => _includeRookiePicks = value),
          title: const Text(
            'Include Rookie Picks',
            style: TextStyle(fontSize: 13),
          ),
          subtitle: const Text(
            'Draft pick assets alongside veteran players',
            style: TextStyle(fontSize: 11),
          ),
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        if (_includeRookiePicks) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: int.tryParse(_rookiePicksSeasonController.text) ?? currentYear,
            decoration: const InputDecoration(
              labelText: 'Rookie Draft Season',
              helperText: 'Which year\'s rookie picks to include',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (int year = currentYear; year <= currentYear + 2; year++)
                DropdownMenuItem(
                  value: year,
                  child: Text('$year Rookie Draft'),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _rookiePicksSeasonController.text = value.toString());
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _rookiePicksRounds,
            decoration: const InputDecoration(
              labelText: 'Number of Rounds',
              helperText: 'How many rounds of picks to generate',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (int rounds = 1; rounds <= 5; rounds++)
                DropdownMenuItem(
                  value: rounds,
                  child: Text('$rounds Round${rounds > 1 ? 's' : ''}'),
                ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _rookiePicksRounds = value);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPoolCheckbox(
    ThemeData theme,
    String value,
    String label,
    String description,
  ) {
    final isSelected = _selectedPlayerPool.contains(value);
    final isCollegeDisabled = value == 'college' && !_isDevyLeague;

    return CheckboxListTile(
      value: isCollegeDisabled ? false : isSelected,
      onChanged: isCollegeDisabled
          ? null
          : (checked) {
              setState(() {
                if (checked == true) {
                  _selectedPlayerPool.add(value);
                } else if (_selectedPlayerPool.length > 1) {
                  // Prevent unchecking all - at least one must remain
                  _selectedPlayerPool.remove(value);
                }
              });
            },
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isCollegeDisabled
              ? theme.colorScheme.onSurface.withAlpha(102)
              : null,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          fontSize: 11,
          color: isCollegeDisabled
              ? theme.colorScheme.onSurface.withAlpha(102)
              : theme.colorScheme.onSurface.withAlpha(153),
        ),
      ),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppSpacing.buttonRadius,
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
        borderRadius: AppSpacing.buttonRadius,
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
