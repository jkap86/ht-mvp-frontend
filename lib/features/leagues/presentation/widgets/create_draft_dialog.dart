import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../drafts/domain/draft_type.dart';

class CreateDraftDialog extends StatefulWidget {
  final Future<void> Function({
    required DraftType draftType,
    required int rounds,
    required int pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
    List<String>? playerPool,
    DateTime? scheduledStart,
  }) onCreateDraft;

  final String leagueMode;
  final int rosterSlotsCount;
  final int? rookieDraftRounds;

  const CreateDraftDialog({
    super.key,
    required this.onCreateDraft,
    required this.leagueMode,
    required this.rosterSlotsCount,
    this.rookieDraftRounds,
  });

  @override
  State<CreateDraftDialog> createState() => _CreateDraftDialogState();
}

class _CreateDraftDialogState extends State<CreateDraftDialog> {
  DraftType _selectedDraftType = DraftType.snake;
  late int _rounds;
  late int _pickTimeSeconds;
  String _draftSubtype = 'startup'; // For dynasty leagues: 'startup' or 'rookie'

  // Player pool settings (default: veterans + rookies for standard redraft behavior)
  late Set<String> _selectedPlayerPool;

  bool get _isDevyLeague => widget.leagueMode == 'devy';
  bool get _isAuction => _selectedDraftType == DraftType.auction;
  bool get _isSlowAuction => _isAuction && _auctionMode == 'slow';

  // Controllers for text inputs
  late TextEditingController _roundsController;
  late TextEditingController _timerController;

  // Auction settings - shared
  int _auctionBudget = 200;
  int _minBid = 1;
  String _auctionMode = 'slow'; // 'slow' or 'fast'

  // Slow auction specific
  int _bidWindowHours = 12;
  int _maxActivePerTeam = 2;

  // Fast auction specific
  int _nominationTimeSeconds = 30;
  int _resetOnBidSeconds = 10;

  // Scheduled start time (optional)
  DateTime? _scheduledStart;

  @override
  void initState() {
    super.initState();
    _pickTimeSeconds = 90;
    _rounds = _calculateDefaultRounds();
    _roundsController = TextEditingController(text: _rounds.toString());
    _timerController = TextEditingController(text: _pickTimeSeconds.toString());
    // Initialize player pool - include college only for devy leagues
    _selectedPlayerPool = _isDevyLeague
        ? {'veteran', 'rookie', 'college'}
        : {'veteran', 'rookie'};
  }

  @override
  void dispose() {
    _roundsController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  int _calculateDefaultRounds() {
    if ((widget.leagueMode == 'dynasty' || widget.leagueMode == 'devy') && _draftSubtype == 'rookie') {
      return widget.rookieDraftRounds ?? 5;
    }
    return widget.rosterSlotsCount;
  }

  void _updateRoundsForSubtype(String subtype) {
    setState(() {
      _draftSubtype = subtype;
      _rounds = _calculateDefaultRounds();
      _roundsController.text = _rounds.toString();
    });
  }

  Widget _buildOptionSelector({
    required String label,
    required List<({String label, dynamic value})> options,
    required dynamic selectedValue,
    required void Function(dynamic) onSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: AppSpacing.buttonRadius,
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
                            left: isFirst ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
                            right: isLast ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
                          ),
                        ),
                        child: Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withAlpha(179),
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

  Widget _buildNumericInput({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    required void Function(int) onChanged,
    String? helperText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withAlpha(204),
                  ),
                ),
                if (helperText != null)
                  Text(
                    helperText,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withAlpha(128),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    final current = int.tryParse(controller.text) ?? min;
                    if (current > min) {
                      final newValue = current - 1;
                      controller.text = newValue.toString();
                      onChanged(newValue);
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: AppSpacing.buttonRadius,
                      ),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed >= min && parsed <= max) {
                        onChanged(parsed);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    final current = int.tryParse(controller.text) ?? max;
                    if (current < max) {
                      final newValue = current + 1;
                      controller.text = newValue.toString();
                      onChanged(newValue);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDynastySubtypeSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'Draft For',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(204),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: AppSpacing.buttonRadius,
              ),
              child: Row(
                children: [
                  _buildSubtypeOption('startup', 'Startup', isFirst: true),
                  _buildSubtypeOption('rookie', 'Rookie', isLast: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtypeOption(String value, String label, {bool isFirst = false, bool isLast = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _draftSubtype == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => _updateRoundsForSubtype(value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
              right: isLast ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerPoolCheckboxes() {
    return Column(
      children: [
        _buildPoolCheckbox('veteran', 'Veterans', 'NFL players with 1+ years experience'),
        _buildPoolCheckbox('rookie', 'Rookies', 'First-year NFL players'),
        _buildPoolCheckbox('college', 'College', 'College players (for dynasty/rookie drafts)'),
      ],
    );
  }

  Widget _buildPoolCheckbox(String value, String label, String description) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedPlayerPool.contains(value);

    // College players are only available in devy leagues
    final isCollegeDisabled = value == 'college' && !_isDevyLeague;
    final effectiveDescription = isCollegeDisabled
        ? 'Only available in Devy leagues'
        : description;

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
          color: isCollegeDisabled ? colorScheme.onSurface.withAlpha(102) : null,
        ),
      ),
      subtitle: Text(
        effectiveDescription,
        style: TextStyle(
          fontSize: 11,
          color: isCollegeDisabled
              ? colorScheme.onSurface.withAlpha(102)
              : colorScheme.onSurface.withAlpha(153),
        ),
      ),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildScheduledStartPicker() {
    final colorScheme = Theme.of(context).colorScheme;

    String formatDateTime(DateTime dt) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final amPm = dt.hour < 12 ? 'AM' : 'PM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $amPm';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Time',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withAlpha(204),
                  ),
                ),
                Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final initialDate = _scheduledStart ?? now.add(const Duration(days: 1));

                      final date = await showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                      );

                      if (date != null && mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_scheduledStart ?? initialDate),
                        );

                        if (time != null && mounted) {
                          setState(() {
                            _scheduledStart = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    borderRadius: AppSpacing.buttonRadius,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: AppSpacing.buttonRadius,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: colorScheme.onSurface.withAlpha(153),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _scheduledStart != null
                                  ? formatDateTime(_scheduledStart!)
                                  : 'Not scheduled',
                              style: TextStyle(
                                fontSize: 12,
                                color: _scheduledStart != null
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withAlpha(128),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_scheduledStart != null)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => setState(() => _scheduledStart = null),
                    tooltip: 'Clear scheduled time',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDynastyOrDevy = widget.leagueMode == 'dynasty' || widget.leagueMode == 'devy';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.event, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Create Draft'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Draft Type Section
              _buildSection(
                title: 'Draft Type',
                icon: Icons.style,
                children: [
                  ...DraftType.values.map((type) {
                    final isSelected = _selectedDraftType == type;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDraftType = type),
                        borderRadius: AppSpacing.buttonRadius,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surface,
                            borderRadius: AppSpacing.buttonRadius,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withAlpha(153),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      type.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isSelected
                                            ? colorScheme.onPrimaryContainer.withAlpha(179)
                                            : colorScheme.onSurface.withAlpha(153),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              // General Settings Section
              _buildSection(
                title: 'Settings',
                icon: Icons.settings,
                children: [
                  if (isDynastyOrDevy) _buildDynastySubtypeSelector(),
                  _buildNumericInput(
                    label: _isSlowAuction ? 'Max Nominations' : 'Rounds',
                    controller: _roundsController,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => _rounds = v),
                    helperText: _isSlowAuction
                        ? 'Max nominations per team'
                        : '1-30 rounds',
                  ),
                  if (!_isAuction)
                    _buildNumericInput(
                      label: 'Pick Timer',
                      controller: _timerController,
                      min: 30,
                      max: 600,
                      onChanged: (v) => setState(() => _pickTimeSeconds = v),
                      helperText: '30-600 seconds',
                    ),
                  _buildScheduledStartPicker(),
                ],
              ),

              // Player Pool Section (shown for ALL draft types)
              _buildSection(
                title: 'Player Pool',
                icon: Icons.people,
                children: [
                  _buildPlayerPoolCheckboxes(),
                ],
              ),

              // Auction Settings (conditional)
              if (_selectedDraftType == DraftType.auction)
                _buildSection(
                  title: 'Auction Settings',
                  icon: Icons.attach_money,
                  children: [
                    // Mode - always shown
                    _buildOptionSelector(
                      label: 'Mode',
                      options: [
                        (label: 'Slow', value: 'slow'),
                        (label: 'Fast', value: 'fast'),
                      ],
                      selectedValue: _auctionMode,
                      onSelected: (v) => setState(() => _auctionMode = v),
                    ),
                    // Budget - always shown
                    _buildOptionSelector(
                      label: 'Budget',
                      options: [
                        (label: '\$100', value: 100),
                        (label: '\$200', value: 200),
                        (label: '\$300', value: 300),
                        (label: '\$500', value: 500),
                      ],
                      selectedValue: _auctionBudget,
                      onSelected: (v) => setState(() => _auctionBudget = v),
                    ),
                    // Min Bid - always shown
                    _buildOptionSelector(
                      label: 'Min Bid',
                      options: [
                        (label: '\$1', value: 1),
                        (label: '\$2', value: 2),
                        (label: '\$5', value: 5),
                      ],
                      selectedValue: _minBid,
                      onSelected: (v) => setState(() => _minBid = v),
                    ),
                    // SLOW MODE ONLY
                    if (_auctionMode == 'slow') ...[
                      _buildOptionSelector(
                        label: 'Bid Window',
                        options: [
                          (label: '1hr', value: 1),
                          (label: '4hr', value: 4),
                          (label: '12hr', value: 12),
                          (label: '24hr', value: 24),
                        ],
                        selectedValue: _bidWindowHours,
                        onSelected: (v) => setState(() => _bidWindowHours = v),
                      ),
                      _buildOptionSelector(
                        label: 'Max Active',
                        options: [
                          (label: '1', value: 1),
                          (label: '2', value: 2),
                          (label: '3', value: 3),
                          (label: '5', value: 5),
                        ],
                        selectedValue: _maxActivePerTeam,
                        onSelected: (v) => setState(() => _maxActivePerTeam = v),
                      ),
                    ],
                    // FAST MODE ONLY
                    if (_auctionMode == 'fast') ...[
                      _buildOptionSelector(
                        label: 'Nom. Time',
                        options: [
                          (label: '15s', value: 15),
                          (label: '30s', value: 30),
                          (label: '45s', value: 45),
                        ],
                        selectedValue: _nominationTimeSeconds,
                        onSelected: (v) => setState(() => _nominationTimeSeconds = v),
                      ),
                      _buildOptionSelector(
                        label: 'Bid Reset',
                        options: [
                          (label: '5s', value: 5),
                          (label: '10s', value: 10),
                          (label: '15s', value: 15),
                          (label: '20s', value: 20),
                        ],
                        selectedValue: _resetOnBidSeconds,
                        onSelected: (v) => setState(() => _resetOnBidSeconds = v),
                      ),
                    ],
                  ],
                ),
            ],
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
            // Validate inputs before creating
            final rounds = int.tryParse(_roundsController.text) ?? _rounds;
            final timer = int.tryParse(_timerController.text) ?? _pickTimeSeconds;

            if (rounds < 1 || rounds > 30) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rounds must be between 1 and 30')),
              );
              return;
            }
            if (timer < 30 || timer > 600) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timer must be between 30 and 600 seconds')),
              );
              return;
            }

            Navigator.pop(context);
            await widget.onCreateDraft(
              draftType: _selectedDraftType,
              rounds: rounds,
              pickTimeSeconds: timer,
              auctionSettings: _selectedDraftType == DraftType.auction
                  ? {
                      'auction_mode': _auctionMode,
                      'budget': _auctionBudget,
                      'min_bid': _minBid,
                      // Slow mode fields
                      if (_auctionMode == 'slow') ...{
                        'bid_window_seconds': _bidWindowHours * 3600,
                        'max_active_nominations_per_team': _maxActivePerTeam,
                      },
                      // Fast mode fields
                      if (_auctionMode == 'fast') ...{
                        'nomination_seconds': _nominationTimeSeconds,
                        'reset_on_bid_seconds': _resetOnBidSeconds,
                      },
                    }
                  : null,
              playerPool: _selectedPlayerPool.toList(),
              scheduledStart: _scheduledStart,
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Draft'),
        ),
      ],
    );
  }
}

void showCreateDraftDialog(
  BuildContext context, {
  required String leagueMode,
  required int rosterSlotsCount,
  int? rookieDraftRounds,
  required Future<void> Function({
    required DraftType draftType,
    required int rounds,
    required int pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
    List<String>? playerPool,
    DateTime? scheduledStart,
  }) onCreateDraft,
}) {
  showDialog(
    context: context,
    builder: (context) => CreateDraftDialog(
      onCreateDraft: onCreateDraft,
      leagueMode: leagueMode,
      rosterSlotsCount: rosterSlotsCount,
      rookieDraftRounds: rookieDraftRounds,
    ),
  );
}
