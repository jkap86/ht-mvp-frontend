import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../players/domain/player.dart';
import '../../domain/roster_player.dart';

/// Shows a bottom sheet to select a player to drop when adding a new player
/// to a full roster.
void showAddDropPlayerSheet({
  required BuildContext context,
  required Player addPlayer,
  required List<RosterPlayer> rosterPlayers,
  required Future<bool> Function(int dropPlayerId) onDropSelected,
  VoidCallback? onSuccess,
  int? maxRosterSize,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return _AddDropPlayerSheet(
        addPlayer: addPlayer,
        rosterPlayers: rosterPlayers,
        onDropSelected: onDropSelected,
        onSuccess: onSuccess,
        maxRosterSize: maxRosterSize,
      );
    },
  );
}

class _AddDropPlayerSheet extends StatefulWidget {
  final Player addPlayer;
  final List<RosterPlayer> rosterPlayers;
  final Future<bool> Function(int dropPlayerId) onDropSelected;
  final VoidCallback? onSuccess;
  final int? maxRosterSize;

  const _AddDropPlayerSheet({
    required this.addPlayer,
    required this.rosterPlayers,
    required this.onDropSelected,
    this.onSuccess,
    this.maxRosterSize,
  });

  @override
  State<_AddDropPlayerSheet> createState() => _AddDropPlayerSheetState();
}

class _AddDropPlayerSheetState extends State<_AddDropPlayerSheet> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rosterCount = widget.rosterPlayers.length;
    final maxSize = widget.maxRosterSize;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Select Player to Drop',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (maxSize != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withAlpha(150),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Roster: $rosterCount/$maxSize',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: maxSize != null
                              ? 'Your roster is full ($rosterCount/$maxSize players). '
                              : 'Your roster is full. ',
                        ),
                        const TextSpan(text: 'Select a player to drop to add '),
                        TextSpan(
                          text: widget.addPlayer.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.rosterPlayers.length,
                  itemBuilder: (context, index) {
                    final dropPlayer = widget.rosterPlayers[index];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: getPositionColor(dropPlayer.position),
                          borderRadius: AppSpacing.buttonRadius,
                        ),
                        child: Center(
                          child: Text(
                            dropPlayer.position ?? '?',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      title: Text(dropPlayer.fullName ?? 'Unknown'),
                      subtitle: Text(
                        [
                          dropPlayer.team ?? 'FA',
                          if (dropPlayer.projectedPoints != null)
                            '${dropPlayer.projectedPoints!.toStringAsFixed(1)} proj pts',
                        ].join(' - '),
                      ),
                      trailing: Icon(
                        Icons.remove_circle_outline,
                        color: colorScheme.error,
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final success = await widget.onDropSelected(dropPlayer.playerId);
                        if (success) {
                          widget.onSuccess?.call();
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
