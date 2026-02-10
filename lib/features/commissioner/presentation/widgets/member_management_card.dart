import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/commissioner_provider.dart';

/// Card for managing league members
class MemberManagementCard extends StatelessWidget {
  final CommissionerState state;
  final void Function(int rosterId, String teamName, String username) onKickMember;
  final void Function(int rosterId, String teamName) onReinstateMember;

  const MemberManagementCard({
    super.key,
    required this.state,
    required this.onKickMember,
    required this.onReinstateMember,
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
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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

  void _showReinstateConfirmation(
    BuildContext context,
    int rosterId,
    String teamName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reinstate Member'),
        content: Text(
          'Are you sure you want to reinstate $teamName?\n\n'
          'They will become an active member again and count against the team limit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onReinstateMember(rosterId, teamName);
            },
            child: const Text('Reinstate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate active and benched members
    final activeMembers = state.members.where((m) => m['is_benched'] != true).toList();
    final benchedMembers = state.members.where((m) => m['is_benched'] == true).toList();

    // Check if there's room to reinstate (active count < total_rosters)
    final canReinstate = state.league != null &&
        activeMembers.length < state.league!.totalRosters;

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

            // Active Members Section
            if (activeMembers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No active members found'),
              )
            else
              ...activeMembers.map((member) => _buildMemberTile(
                context,
                member,
                isBenched: false,
                canReinstate: false,
              )),

            // Benched Members Section
            if (benchedMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.buttonRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pause_circle_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Benched Members (${benchedMembers.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...benchedMembers.map((member) => _buildMemberTile(
                context,
                member,
                isBenched: true,
                canReinstate: canReinstate,
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    Map<String, dynamic> member, {
    required bool isBenched,
    required bool canReinstate,
  }) {
    final rosterId = member['roster_id'] as int?;
    final memberId = member['id'] as int?;
    final isCommissioner = rosterId != null && rosterId == state.league?.commissionerRosterId;
    final teamName = (member['team_name'] as String?) ?? 'Team $rosterId';
    final username = (member['username'] as String?) ?? 'Unknown';

    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isBenched ? 0.6 : 1.0,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: isCommissioner
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          child: Icon(
            isCommissioner ? Icons.star : (isBenched ? Icons.pause : Icons.person),
            color: isCommissioner
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          teamName,
          style: isBenched
              ? const TextStyle(fontStyle: FontStyle.italic)
              : null,
        ),
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
            : isBenched && memberId != null
                ? TextButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Reinstate'),
                    onPressed: canReinstate
                        ? () => _showReinstateConfirmation(
                              context,
                              memberId,
                              teamName,
                            )
                        : null,
                  )
                : memberId != null
                    ? IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                        onPressed: () => _showKickConfirmation(
                          context,
                          memberId,
                          teamName,
                          username,
                        ),
                        tooltip: 'Kick member',
                      )
                    : null,
      ),
    );
  }
}
