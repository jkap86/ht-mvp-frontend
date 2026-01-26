import 'package:flutter/material.dart';

import '../../../drafts/domain/draft_type.dart';

class CreateDraftDialog extends StatefulWidget {
  final Future<void> Function({
    required DraftType draftType,
    required int rounds,
    required int pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
  }) onCreateDraft;

  const CreateDraftDialog({super.key, required this.onCreateDraft});

  @override
  State<CreateDraftDialog> createState() => _CreateDraftDialogState();
}

class _CreateDraftDialogState extends State<CreateDraftDialog> {
  DraftType _selectedDraftType = DraftType.snake;
  int _rounds = 15;
  int _pickTimeSeconds = 90;

  // Auction settings
  int _auctionBudget = 200;
  int _minBid = 1;
  int _nominationTimeSeconds = 30;

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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  _buildOptionSelector(
                    label: 'Rounds',
                    options: [
                      (label: '12', value: 12),
                      (label: '15', value: 15),
                      (label: '18', value: 18),
                      (label: '20', value: 20),
                    ],
                    selectedValue: _rounds,
                    onSelected: (v) => setState(() => _rounds = v),
                  ),
                  _buildOptionSelector(
                    label: 'Pick Timer',
                    options: [
                      (label: '30s', value: 30),
                      (label: '60s', value: 60),
                      (label: '90s', value: 90),
                      (label: '120s', value: 120),
                    ],
                    selectedValue: _pickTimeSeconds,
                    onSelected: (v) => setState(() => _pickTimeSeconds = v),
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
            Navigator.pop(context);
            await widget.onCreateDraft(
              draftType: _selectedDraftType,
              rounds: _rounds,
              pickTimeSeconds: _pickTimeSeconds,
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
  required Future<void> Function({
    required DraftType draftType,
    required int rounds,
    required int pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
  }) onCreateDraft,
}) {
  showDialog(
    context: context,
    builder: (context) => CreateDraftDialog(onCreateDraft: onCreateDraft),
  );
}
