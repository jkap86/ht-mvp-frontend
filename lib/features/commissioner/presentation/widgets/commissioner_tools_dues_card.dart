import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Commissioner dues admin card.
///
/// Provides CSV export of dues payment status.
class CommissionerToolsDuesCard extends StatelessWidget {
  final Future<String?> Function() onExportCsv;

  const CommissionerToolsDuesCard({
    super.key,
    required this.onExportCsv,
  });

  Future<void> _exportCsv(BuildContext context) async {
    final csv = await onExportCsv();
    if (csv == null || !context.mounted) return;

    // Copy CSV to clipboard for the user to paste into a file
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dues CSV copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Dues Export',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              'Export a CSV of all dues payment statuses for your records.',
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportCsv(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copy Dues CSV'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
