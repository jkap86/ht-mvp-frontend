import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../domain/league.dart';

class LeagueMembersSection extends StatelessWidget {
  final League league;
  final List<Roster> members;
  final int totalSlots;
  final VoidCallback? onInviteTap;

  const LeagueMembersSection({
    super.key,
    required this.league,
    required this.members,
    required this.totalSlots,
    this.onInviteTap,
  });

  void _copyInviteCode(BuildContext context) {
    if (league.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: league.inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Teams',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (league.inviteCode != null)
                  TextButton.icon(
                    onPressed: onInviteTap ?? () => _copyInviteCode(context),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Invite'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalSlots,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index < members.length) {
                  final member = members[index];
                  if (member.userId != null) {
                    // Real member with user
                    return _MemberTile(
                      member: member,
                      isCommissioner:
                          member.rosterId == league.commissionerRosterId,
                      isCurrentUser: member.rosterId == league.userRosterId,
                    );
                  } else {
                    // Empty roster placeholder (created for draft order)
                    return _EmptyRosterTile(
                        rosterId: member.rosterId ?? (index + 1));
                  }
                }
                return _EmptySlotTile(slotNumber: index + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Roster member;
  final bool isCommissioner;
  final bool isCurrentUser;

  const _MemberTile({
    required this.member,
    required this.isCommissioner,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(
        name: member.username,
        isHighlighted: isCurrentUser,
        showCommissionerBadge: isCommissioner,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.teamName ?? member.username,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        member.username,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '#${member.rosterId}',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptySlotTile extends StatelessWidget {
  final int slotNumber;

  const _EmptySlotTile({required this.slotNumber});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person_add, color: Colors.grey[400], size: 20),
      ),
      title: Text(
        'Open Slot',
        style: TextStyle(
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '#$slotNumber',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Empty roster tile for placeholder rosters created during draft order setup.
/// Shows "Team X" where X is the league-specific roster_id.
class _EmptyRosterTile extends StatelessWidget {
  final int rosterId;

  const _EmptyRosterTile({required this.rosterId});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.people, color: Colors.grey[400], size: 20),
      ),
      title: Text(
        'Team $rosterId',
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '#$rosterId',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
