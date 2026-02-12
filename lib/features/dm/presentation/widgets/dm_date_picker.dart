import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dm_conversation_provider.dart';

/// Date/time picker widget for jumping to specific points in DM conversation history
class DmDatePicker extends ConsumerStatefulWidget {
  final int conversationId;

  const DmDatePicker({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<DmDatePicker> createState() => _DmDatePickerState();
}

class _DmDatePickerState extends ConsumerState<DmDatePicker> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(2020); // Adjust based on app launch date

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  void _jumpToDate() {
    if (_selectedDate == null) return;

    final time = _selectedTime ?? const TimeOfDay(hour: 0, minute: 0);
    final timestamp = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      time.hour,
      time.minute,
    );

    ref
        .read(dmConversationProvider(widget.conversationId).notifier)
        .jumpToTimestamp(timestamp);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jump to Date',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Date selector
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDate != null
                    ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                    : 'Select date',
              ),
              onTap: () => _selectDate(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.dividerColor),
              ),
            ),
            const SizedBox(height: 8),

            // Time selector (optional)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Select time (optional)',
              ),
              onTap: () => _selectTime(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.dividerColor),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedDate != null ? _jumpToDate : null,
                  child: const Text('Jump'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Button that opens the date picker dialog for DMs
class DmDatePickerButton extends ConsumerWidget {
  final int conversationId;

  const DmDatePickerButton({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (BuildContext innerContext) => IconButton(
        icon: const Icon(Icons.date_range),
        onPressed: () {
          showDialog(
            context: innerContext,
            builder: (context) => DmDatePicker(conversationId: conversationId),
          );
        },
        tooltip: 'Jump to date',
      ),
    );
  }
}
