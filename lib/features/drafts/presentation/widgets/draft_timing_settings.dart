import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Settings section for pick timer and overnight pause (snake/linear drafts).
/// Used in the edit draft settings dialog.
class DraftTimingSettings extends StatelessWidget {
  final TextEditingController pickTimeController;
  final bool enabled;
  final String? Function(String?)? validator;
  // Overnight pause settings
  final bool? overnightPauseEnabled;
  final ValueChanged<bool>? onOvernightPauseToggled;
  final TimeOfDay? overnightPauseStart;
  final TimeOfDay? overnightPauseEnd;
  final ValueChanged<TimeOfDay?>? onPauseStartChanged;
  final ValueChanged<TimeOfDay?>? onPauseEndChanged;

  const DraftTimingSettings({
    super.key,
    required this.pickTimeController,
    required this.enabled,
    this.validator,
    this.overnightPauseEnabled,
    this.onOvernightPauseToggled,
    this.overnightPauseStart,
    this.overnightPauseEnd,
    this.onPauseStartChanged,
    this.onPauseEndChanged,
  });

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay? initialTime,
    ValueChanged<TimeOfDay?>? onChanged,
  ) async {
    if (onChanged == null) return;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 23, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pauseEnabled = overnightPauseEnabled ?? false;

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
        const SizedBox(height: 24),
        // Overnight pause section
        if (onOvernightPauseToggled != null) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overnight Pause', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Automatically pause draft during late hours',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: pauseEnabled,
                onChanged: enabled ? onOvernightPauseToggled : null,
              ),
            ],
          ),
          if (pauseEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pause Start',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: enabled
                            ? () => _selectTime(
                                  context,
                                  overnightPauseStart,
                                  onPauseStartChanged,
                                )
                            : null,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(_formatTime(overnightPauseStart)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pause End',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: enabled
                            ? () => _selectTime(
                                  context,
                                  overnightPauseEnd,
                                  onPauseEndChanged,
                                )
                            : null,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(_formatTime(overnightPauseEnd)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Times are in UTC. Draft will automatically pause during this window.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
