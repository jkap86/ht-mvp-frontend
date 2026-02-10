import 'package:flutter/material.dart';

/// Data class representing a selectable team option.
class TeamOption {
  final int rosterId;
  final String teamName;
  final bool isCurrentUser;

  const TeamOption({
    required this.rosterId,
    required this.teamName,
    this.isCurrentUser = false,
  });
}

/// Shows a bottom sheet for selecting a team from a list.
void showTeamSelectorSheet({
  required BuildContext context,
  required List<TeamOption> teams,
  int? currentTeamId,
  required ValueChanged<int> onTeamSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TeamSelectorSheet(
      teams: teams,
      currentTeamId: currentTeamId,
      onTeamSelected: onTeamSelected,
    ),
  );
}

class _TeamSelectorSheet extends StatelessWidget {
  final List<TeamOption> teams;
  final int? currentTeamId;
  final ValueChanged<int> onTeamSelected;

  const _TeamSelectorSheet({
    required this.teams,
    this.currentTeamId,
    required this.onTeamSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.groups, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Select Team',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Team list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final isSelected = team.rosterId == currentTeamId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      child: Text(
                        team.teamName.isNotEmpty
                            ? team.teamName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      team.teamName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                    trailing: team.isCurrentUser
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: colorScheme.primary,
                          )
                        : null,
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context);
                      onTeamSelected(team.rosterId);
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
