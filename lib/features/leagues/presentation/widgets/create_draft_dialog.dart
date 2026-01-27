import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../drafts/domain/draft_type.dart';

class CreateDraftDialog extends StatefulWidget {
  final Future<void> Function({
    required DraftType draftType,
    required int rounds,
    required int pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
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

  // Controllers for text inputs
  late TextEditingController _roundsController;
  late TextEditingController _timerController;

  // Auction settings
  int _auctionBudget = 200;
  int _minBid = 1;
  int _nominationTimeSeconds = 30;

  @override
  void initState() {
    super.initState();
    _pickTimeSeconds = 90;
    _rounds = _calculateDefaultRounds();
    _roundsController = TextEditingController(text: _rounds.toString());
    _timerController = TextEditingController(text: _pickTimeSeconds.toString());
  }

  @override
  void dispose() {
    _roundsController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  int _calculateDefaultRounds() {
    if (widget.leagueMode == 'dynasty' && _draftSubtype == 'rookie') {
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
                        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(8),
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
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDynasty = widget.leagueMode == 'dynasty';

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
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
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
                  if (isDynasty) _buildDynastySubtypeSelector(),
                  _buildNumericInput(
                    label: 'Rounds',
                    controller: _roundsController,
                    min: 1,
                    max: 30,
                    onChanged: (v) => setState(() => _rounds = v),
                    helperText: '1-30 rounds',
                  ),
                  _buildNumericInput(
                    label: 'Pick Timer',
                    controller: _timerController,
                    min: 30,
                    max: 600,
                    onChanged: (v) => setState(() => _pickTimeSeconds = v),
                    helperText: '30-600 seconds',
                  ),
                ],
              ),

              // Auction Settings (conditional)
              if (_selectedDraftType == DraftType.auction)
                _buildSection(
                  title: 'Auction Settings',
                  icon: Icons.attach_money,
                  children: [
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
                      'budget': _auctionBudget,
                      'min_bid': _minBid,
                      'nomination_time_seconds': _nominationTimeSeconds,
                    }
                  : null,
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
