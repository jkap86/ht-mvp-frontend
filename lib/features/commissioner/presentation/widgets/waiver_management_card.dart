import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

class WaiverManagementCard extends StatefulWidget {
  final bool waiversInitialized;
  final void Function({int? faabBudget}) onInitializeWaivers;
  final VoidCallback onProcessWaivers;

  const WaiverManagementCard({
    super.key,
    required this.waiversInitialized,
    required this.onInitializeWaivers,
    required this.onProcessWaivers,
  });

  @override
  State<WaiverManagementCard> createState() => _WaiverManagementCardState();
}

class _WaiverManagementCardState extends State<WaiverManagementCard> {
  int _selectedFaabBudget = 100;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Waiver Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Initialize the waiver system to allow players to submit waiver claims. '
              'You can optionally set a FAAB (Free Agent Acquisition Budget) for auction-style waivers.',
            ),
            const SizedBox(height: 16),

            // FAAB Budget selector
            Row(
              children: [
                const Text('FAAB Budget: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedFaabBudget,
                  items: [0, 50, 100, 200, 500].map((budget) {
                    return DropdownMenuItem(
                      value: budget,
                      child: Text(budget == 0 ? 'None (Priority)' : '\$$budget'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedFaabBudget = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onInitializeWaivers(
                      faabBudget: _selectedFaabBudget > 0 ? _selectedFaabBudget : null,
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(widget.waiversInitialized
                      ? 'Reinitialize Waivers'
                      : 'Initialize Waivers'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.onProcessWaivers,
                  icon: const Icon(Icons.sync),
                  label: const Text('Process Waivers Now'),
                ),
              ],
            ),

            if (widget.waiversInitialized) ...[
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(30),
                    borderRadius: AppSpacing.buttonRadius,
                    border: Border.all(color: colorScheme.primary.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Waivers initialized',
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
