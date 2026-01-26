import 'package:flutter/material.dart';

import '../providers/commissioner_provider.dart';

/// Card for managing league members
class MemberManagementCard extends StatelessWidget {
  final CommissionerState state;
  final void Function(int rosterId, String teamName, String username) onKickMember;

  const MemberManagementCard({
    super.key,
    required this.state,
    required this.onKickMember,
  });

  void _showKickConfirmation(
    BuildContext context,
    int rosterId,
    String teamName,
    String username,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Member'),
        content: Text(
          'Are you sure you want to remove $teamName ($username) from the league?\n\n'
          'This will:\n'
          '- Release all their players\n'
          '- Cancel their pending trades\n'
          '- Cancel their waiver claims\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              onKickMember(rosterId, teamName, username);
            },
            child: const Text('Kick Member'),
          ),
        ],
      ),
    );
  }

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
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Text(
                  'Member Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (state.members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No members found'),
              )
            else
              ...state.members.map((member) {
                final rosterId = member['roster_id'] as int?;
                final memberId = member['id'] as int?;
                final isCommissioner = rosterId != null && rosterId == state.league?.commissionerRosterId;
                final teamName = (member['team_name'] as String?) ?? 'Team $rosterId';
                final username = (member['username'] as String?) ?? 'Unknown';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isCommissioner
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey.shade200,
                    child: Icon(
                      isCommissioner ? Icons.star : Icons.person,
                      color: isCommissioner
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(teamName),
                  subtitle: Text(username),
                  trailing: isCommissioner
                      ? Chip(
                          label: const Text('Commissioner'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : memberId != null
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _showKickConfirmation(
                                context,
                                memberId,
                                teamName,
                                username,
                              ),
                              tooltip: 'Kick member',
                            )
                          : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}
