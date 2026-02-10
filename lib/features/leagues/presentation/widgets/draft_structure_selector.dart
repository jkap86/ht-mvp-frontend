import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Represents a draft structure option for league creation.
class DraftStructureOption {
  final String id;
  final String label;
  final String description;

  const DraftStructureOption(this.id, this.label, this.description);
}

/// Widget for selecting draft structure when creating a league.
/// Shows different options based on whether the league is devy or standard.
class DraftStructureSelector extends StatelessWidget {
  final String leagueMode;
  final String selectedStructure;
  final ValueChanged<String> onChanged;

  const DraftStructureSelector({
    super.key,
    required this.leagueMode,
    required this.selectedStructure,
    required this.onChanged,
  });

  static const _standardOptions = [
    DraftStructureOption(
      'combined',
      '1 Draft - Combined',
      'Veterans and rookies together',
    ),
    DraftStructureOption(
      'split',
      '2 Drafts - Separate',
      'Veteran draft + Rookie draft',
    ),
  ];

  static const _devyOptions = [
    DraftStructureOption(
      'combined',
      '1 Draft - Combined',
      'All players together',
    ),
    DraftStructureOption(
      'nfl_college',
      '2 Drafts - NFL + College',
      'NFL players and college separately',
    ),
    DraftStructureOption(
      'vet_future',
      '2 Drafts - Vets + Future',
      'Veterans, then rookies + college',
    ),
    DraftStructureOption(
      'split_three',
      '3 Drafts - Full Split',
      'Veterans, rookies, college separately',
    ),
  ];

  List<DraftStructureOption> get _options =>
      leagueMode == 'devy' ? _devyOptions : _standardOptions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Draft Structure',
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
            'How many drafts and what player pools each includes',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 12),
          ..._options.map((opt) => _buildOption(context, opt)),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, DraftStructureOption option) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedStructure == option.id;

    return InkWell(
      onTap: () => onChanged(option.id),
      borderRadius: AppSpacing.buttonRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(128)
              : Colors.transparent,
          borderRadius: AppSpacing.buttonRadius,
          border: isSelected
              ? Border.all(color: colorScheme.primary.withAlpha(128))
              : null,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: option.id,
              groupValue: selectedStructure,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    option.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
