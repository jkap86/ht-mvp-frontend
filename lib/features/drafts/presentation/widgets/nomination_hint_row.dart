import 'package:flutter/material.dart';

/// Hint row shown above the nomination player list in auction mode.
///
/// Displays an icon and text instructing users to tap a player to nominate.
class NominationHintRow extends StatelessWidget {
  const NominationHintRow({super.key});

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.person_add, size: 16, color: hintColor),
          const SizedBox(width: 4),
          Text(
            'Tap a player to nominate',
            style: TextStyle(
              fontSize: 12,
              color: hintColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
