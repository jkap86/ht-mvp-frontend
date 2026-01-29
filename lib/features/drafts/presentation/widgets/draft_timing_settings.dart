import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Settings section for pick timer (snake/linear drafts).
/// Used in the edit draft settings dialog.
class DraftTimingSettings extends StatelessWidget {
  final TextEditingController pickTimeController;
  final bool enabled;
  final String? Function(String?)? validator;

  const DraftTimingSettings({
    super.key,
    required this.pickTimeController,
    required this.enabled,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pick Time (seconds)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: pickTimeController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seconds per pick',
            helperText: '30-600 seconds',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          enabled: enabled,
        ),
      ],
    );
  }
}
