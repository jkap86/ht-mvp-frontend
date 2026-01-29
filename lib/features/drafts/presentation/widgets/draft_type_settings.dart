import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Settings section for draft type and rounds.
/// Used in the edit draft settings dialog.
class DraftTypeSettings extends StatelessWidget {
  final String draftType;
  final TextEditingController roundsController;
  final bool enabled;
  final ValueChanged<String?> onDraftTypeChanged;
  final String? Function(String?)? roundsValidator;

  const DraftTypeSettings({
    super.key,
    required this.draftType,
    required this.roundsController,
    required this.enabled,
    required this.onDraftTypeChanged,
    this.roundsValidator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Draft Type
        Text('Draft Type', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: draftType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'snake', child: Text('Snake')),
            DropdownMenuItem(value: 'linear', child: Text('Linear')),
            DropdownMenuItem(value: 'auction', child: Text('Auction')),
          ],
          onChanged: enabled ? onDraftTypeChanged : null,
        ),

        const SizedBox(height: 16),

        // Rounds
        Text('Rounds', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: roundsController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Number of rounds',
            helperText: '1-30 rounds',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: roundsValidator,
          enabled: enabled,
        ),
      ],
    );
  }
}
