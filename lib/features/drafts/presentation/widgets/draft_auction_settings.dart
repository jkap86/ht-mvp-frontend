import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Settings section for auction-specific settings.
/// Used in the edit draft settings dialog.
class DraftAuctionSettings extends StatelessWidget {
  final TextEditingController bidWindowController;
  final TextEditingController nominationSecondsController;
  final TextEditingController resetOnBidSecondsController;
  final TextEditingController minIncrementController;
  final bool enabled;
  final String? Function(String?, {int? min, int? max, String? fieldName})
      validator;

  const DraftAuctionSettings({
    super.key,
    required this.bidWindowController,
    required this.nominationSecondsController,
    required this.resetOnBidSecondsController,
    required this.minIncrementController,
    required this.enabled,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text('Auction Settings', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // Bid Window
        Text('Bid Window (seconds)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: bidWindowController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seconds for bidding',
            helperText: '3600-172800 (1 hour to 2 days)',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) =>
              validator(v, min: 3600, max: 172800, fieldName: 'Bid window'),
          enabled: enabled,
        ),

        const SizedBox(height: 16),

        // Nomination Time
        Text('Nomination Time (seconds)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: nominationSecondsController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seconds for nomination',
            helperText: '15-120 seconds',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) =>
              validator(v, min: 15, max: 120, fieldName: 'Nomination time'),
          enabled: enabled,
        ),

        const SizedBox(height: 16),

        // Bid Reset Time
        Text('Bid Reset Time (seconds)', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: resetOnBidSecondsController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Seconds to add on new bid',
            helperText: '5-30 seconds',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) =>
              validator(v, min: 5, max: 30, fieldName: 'Reset time'),
          enabled: enabled,
        ),

        const SizedBox(height: 16),

        // Min Bid Increment
        Text('Minimum Bid Increment', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: minIncrementController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Minimum bid increment',
            prefixText: '\$ ',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => validator(v, min: 1, fieldName: 'Min increment'),
          enabled: enabled,
        ),
      ],
    );
  }
}
