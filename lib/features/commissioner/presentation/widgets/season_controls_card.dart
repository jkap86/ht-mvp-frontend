import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/idempotency.dart';
import '../../../leagues/domain/league.dart';
import '../providers/commissioner_provider.dart';

/// Card for manually controlling season status and current week
class SeasonControlsCard extends ConsumerStatefulWidget {
  final int leagueId;
  final CommissionerState state;

  const SeasonControlsCard({
    super.key,
    required this.leagueId,
    required this.state,
  });

  @override
  ConsumerState<SeasonControlsCard> createState() => _SeasonControlsCardState();
}

class _SeasonControlsCardState extends ConsumerState<SeasonControlsCard> {
  late SeasonStatus _selectedStatus;
  late int _selectedWeek;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.state.league?.seasonStatus ?? SeasonStatus.preSeason;
    _selectedWeek = widget.state.league?.currentWeek ?? 1;
  }

  @override
  void didUpdateWidget(SeasonControlsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset to current values when state changes externally
    if (!_hasChanges) {
      _selectedStatus = widget.state.league?.seasonStatus ?? SeasonStatus.preSeason;
      _selectedWeek = widget.state.league?.currentWeek ?? 1;
    }
  }

  void _updateStatus(SeasonStatus? status) {
    if (status != null) {
      setState(() {
        _selectedStatus = status;
        _hasChanges = _selectedStatus != widget.state.league?.seasonStatus ||
            _selectedWeek != widget.state.league?.currentWeek;
      });
    }
  }

  void _updateWeek(int week) {
    setState(() {
      _selectedWeek = week;
      _hasChanges = _selectedStatus != widget.state.league?.seasonStatus ||
          _selectedWeek != widget.state.league?.currentWeek;
    });
  }

  String _statusToApiValue(SeasonStatus status) {
    switch (status) {
      case SeasonStatus.preSeason:
        return 'pre_season';
      case SeasonStatus.regularSeason:
        return 'regular_season';
      case SeasonStatus.playoffs:
        return 'playoffs';
      case SeasonStatus.offseason:
        return 'offseason';
    }
  }

  Future<void> _saveChanges() async {
    final key = newIdempotencyKey();
    final success = await ref.read(commissionerProvider(widget.leagueId).notifier).updateSeasonControls(
          seasonStatus: _statusToApiValue(_selectedStatus),
          currentWeek: _selectedWeek,
          idempotencyKey: key,
        );
    if (success) {
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Season Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: AppSpacing.buttonRadius,
                border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: colorScheme.tertiary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing these settings affects schedules, lineups, and scoring.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Season Status Dropdown
            DropdownButtonFormField<SeasonStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Season Status',
                border: OutlineInputBorder(),
              ),
              items: SeasonStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: _updateStatus,
            ),
            const SizedBox(height: 16),
            // Current Week Dropdown
            DropdownButtonFormField<int>(
              value: _selectedWeek,
              decoration: const InputDecoration(
                labelText: 'Current Week',
                border: OutlineInputBorder(),
              ),
              items: List.generate(18, (index) {
                final week = index + 1;
                return DropdownMenuItem(
                  value: week,
                  child: Text('Week $week'),
                );
              }),
              onChanged: (week) {
                if (week != null) _updateWeek(week);
              },
            ),
            const SizedBox(height: 16),
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                  foregroundColor: _hasChanges ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
                onPressed: _hasChanges ? _saveChanges : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
