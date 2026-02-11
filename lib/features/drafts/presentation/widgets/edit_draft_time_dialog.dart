import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../../leagues/domain/league.dart';

/// Simple dialog for editing a draft's scheduled start time.
/// Only shown to commissioners when draft has not started.
class EditDraftTimeDialog extends StatefulWidget {
  final Draft draft;
  final Future<void> Function(DateTime? scheduledStart) onSave;

  const EditDraftTimeDialog({
    super.key,
    required this.draft,
    required this.onSave,
  });

  /// Shows the edit draft time dialog.
  static Future<void> show(
    BuildContext context, {
    required Draft draft,
    required Future<void> Function(DateTime? scheduledStart) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => EditDraftTimeDialog(
        draft: draft,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditDraftTimeDialog> createState() => _EditDraftTimeDialogState();
}

class _EditDraftTimeDialogState extends State<EditDraftTimeDialog> {
  DateTime? _scheduledStart;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scheduledStart = widget.draft.scheduledStart;
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $amPm';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final initialDate = _scheduledStart ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledStart ?? initialDate),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledStart = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _onSave() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.onSave(_scheduledStart);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = ErrorSanitizer.sanitize(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.schedule, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Schedule Draft'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: AppSpacing.buttonRadius,
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Set a scheduled start time for your draft. League members will see when the draft is planned to begin.',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDateTime,
            borderRadius: AppSpacing.buttonRadius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: AppSpacing.buttonRadius,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled Start',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _scheduledStart != null
                              ? _formatDateTime(_scheduledStart!)
                              : 'Not scheduled',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _scheduledStart != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ],
              ),
            ),
          ),
          if (_scheduledStart != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _scheduledStart = null),
                icon: Icon(
                  Icons.clear,
                  size: 16,
                  color: colorScheme.error,
                ),
                label: Text(
                  'Clear scheduled time',
                  style: TextStyle(color: colorScheme.error, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurface.withAlpha(179)),
          ),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _onSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
