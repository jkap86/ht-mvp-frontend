import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Settings section for auction-specific settings.
/// Used in the edit draft settings dialog.
class DraftAuctionSettings extends StatelessWidget {
  // Timing settings
  final TextEditingController bidWindowController;
  final TextEditingController nominationSecondsController;
  final TextEditingController resetOnBidSecondsController;
  final TextEditingController minIncrementController;

  // Mode settings
  final String auctionMode;
  final void Function(String)? onAuctionModeChanged;
  final bool canEditMode;

  // Nomination limit settings
  final TextEditingController maxActivePerTeamController;
  final TextEditingController maxActiveGlobalController;
  final TextEditingController dailyNominationLimitController;

  final bool enabled;
  final String? Function(String?, {int? min, int? max, String? fieldName})
      validator;

  const DraftAuctionSettings({
    super.key,
    required this.bidWindowController,
    required this.nominationSecondsController,
    required this.resetOnBidSecondsController,
    required this.minIncrementController,
    required this.auctionMode,
    this.onAuctionModeChanged,
    this.canEditMode = false,
    required this.maxActivePerTeamController,
    required this.maxActiveGlobalController,
    required this.dailyNominationLimitController,
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

        // Auction Mode toggle
        Text('Auction Mode', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'slow', label: Text('Slow')),
            ButtonSegment(value: 'fast', label: Text('Fast')),
          ],
          selected: {auctionMode},
          onSelectionChanged: canEditMode && onAuctionModeChanged != null
              ? (selected) => onAuctionModeChanged!(selected.first)
              : null,
        ),
        if (!canEditMode)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mode cannot be changed after draft has started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        const SizedBox(height: 24),
        Text('Timing', style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 12),

        // Bid Window
        Text('Bid Window (seconds)', style: theme.textTheme.bodyMedium),
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
        Text('Nomination Time (seconds)', style: theme.textTheme.bodyMedium),
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
        Text('Bid Reset Time (seconds)', style: theme.textTheme.bodyMedium),
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
        Text('Minimum Bid Increment', style: theme.textTheme.bodyMedium),
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

        const SizedBox(height: 24),
        Text('Nomination Limits', style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 12),

        // Max Active Per Team
        Text('Max Active Per Team', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: maxActivePerTeamController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Max concurrent auctions per team',
            helperText: '1-10 (default: 2)',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) =>
              validator(v, min: 1, max: 10, fieldName: 'Max per team'),
          enabled: enabled,
        ),

        const SizedBox(height: 16),

        // Max Active Global
        Text('Max Active League-Wide', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: maxActiveGlobalController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Max concurrent auctions league-wide',
            helperText: '1-100 (default: 25)',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) =>
              validator(v, min: 1, max: 100, fieldName: 'Max global'),
          enabled: enabled,
        ),

        const SizedBox(height: 16),

        // Daily Nomination Limit
        Text('Daily Nomination Limit', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: dailyNominationLimitController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Leave empty for unlimited',
            helperText: '1-10 per day, or empty for unlimited',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.isEmpty) return null; // Optional field
            return validator(v, min: 1, max: 10, fieldName: 'Daily limit');
          },
          enabled: enabled,
        ),
      ],
    );
  }
}
