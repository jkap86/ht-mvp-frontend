import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/league.dart';
import '../../../dues/presentation/providers/dues_provider.dart';

class LeagueMembersSection extends ConsumerStatefulWidget {
  final League league;
  final List<Roster> members;
  final int totalSlots;

  const LeagueMembersSection({
    super.key,
    required this.league,
    required this.members,
    required this.totalSlots,
  });

  @override
  ConsumerState<LeagueMembersSection> createState() =>
      _LeagueMembersSectionState();
}

class _LeagueMembersSectionState extends ConsumerState<LeagueMembersSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(duesProvider(widget.league.id).notifier).loadDues(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duesState = ref.watch(duesProvider(widget.league.id));
    final colorScheme = Theme.of(context).colorScheme;
    final hasDues = duesState.isEnabled && duesState.config != null;

    // Build a map of rosterId -> payment status for quick lookup
    final paymentMap = <int, bool>{};
    if (hasDues) {
      for (final payment in duesState.payments) {
        paymentMap[payment.rosterId] = payment.isPaid;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasDues ? 'Dues' : 'Teams',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            // Dues summary header (for paid leagues only)
            if (hasDues) ...[
              const SizedBox(height: 12),
              _DuesSummaryHeader(
                config: duesState.config!,
                summary: duesState.summary,
                payouts: duesState.payouts,
                colorScheme: colorScheme,
              ),
            ],
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.totalSlots,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index < widget.members.length) {
                  final member = widget.members[index];
                  if (member.userId != null) {
                    // Real member with user
                    final isPaid = hasDues ? paymentMap[member.rosterId] : null;
                    return _MemberTile(
                      member: member,
                      isCommissioner:
                          member.rosterId == widget.league.commissionerRosterId,
                      isCurrentUser:
                          member.rosterId == widget.league.userRosterId,
                      isPaid: isPaid,
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

/// Header showing dues summary for paid leagues
class _DuesSummaryHeader extends StatelessWidget {
  final dynamic config;
  final dynamic summary;
  final List<dynamic> payouts;
  final ColorScheme colorScheme;

  const _DuesSummaryHeader({
    required this.config,
    required this.summary,
    required this.payouts,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Buy-in and Total Pot row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Buy-in: \$${config.buyInAmount.toStringAsFixed(2)} ${config.currency}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (summary != null)
                Text(
                  'Total Pot: \$${summary.totalPot.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
            ],
          ),
          // Payouts
          if (payouts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: payouts.map((p) {
                return Chip(
                  label: Text('${p.place}: \$${p.amount.toStringAsFixed(0)}'),
                  backgroundColor: colorScheme.surface,
                  labelStyle: const TextStyle(fontSize: 12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Roster member;
  final bool isCommissioner;
  final bool isCurrentUser;
  final bool? isPaid;

  const _MemberTile({
    required this.member,
    required this.isCommissioner,
    required this.isCurrentUser,
    this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: isCurrentUser ? colorScheme.primary.withValues(alpha: 0.12) : null,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: UserAvatar(
          name: member.username,
          isHighlighted: isCurrentUser,
          showCommissionerBadge: isCommissioner,
        ),
        title: Text(
          member.teamName ?? member.username,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          member.username,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: isPaid != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid!
                      ? AppTheme.draftActionPrimary.withValues(alpha: 0.1)
                      : AppTheme.draftWarning.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.badgeRadius,
                ),
                child: Text(
                  isPaid! ? 'PAID' : 'UNPAID',
                  style: TextStyle(
                    fontSize: 11,
                    color: isPaid! ? AppTheme.draftActionPrimary : AppTheme.draftWarning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _EmptySlotTile extends StatelessWidget {
  final int slotNumber;

  const _EmptySlotTile({required this.slotNumber});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.person_add, color: colorScheme.outlineVariant, size: 20),
      ),
      title: Text(
        'Open Slot',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.badgeRadius,
        ),
        child: Text(
          '#$slotNumber',
          style: TextStyle(
            color: colorScheme.outlineVariant,
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
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.people, color: colorScheme.outlineVariant, size: 20),
      ),
      title: Text(
        'Team $rosterId',
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.badgeRadius,
        ),
        child: Text(
          '#$rosterId',
          style: TextStyle(
            color: colorScheme.outlineVariant,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
