import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../data/invitations_provider.dart';
import '../../data/league_repository.dart';
import '../../domain/invitation.dart';
import 'invitation_card.dart';

class InvitesTab extends ConsumerStatefulWidget {
  const InvitesTab({super.key});

  @override
  ConsumerState<InvitesTab> createState() => _InvitesTabState();
}

class _InvitesTabState extends ConsumerState<InvitesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(invitationsProvider);

    if (state.isLoading && state.invitations.isEmpty) {
      return const AppLoadingView();
    }

    if (state.error != null && state.invitations.isEmpty) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(invitationsProvider.notifier).loadInvitations(),
      );
    }

    if (state.invitations.isEmpty) {
      return const AppEmptyView(
        icon: Icons.mail_outline,
        title: 'No pending invites',
        subtitle: 'When someone invites you to a league, it will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(invitationsProvider.notifier).loadInvitations(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.invitations.length,
            itemBuilder: (context, index) {
              final invitation = state.invitations[index];
              return InvitationCard(
                invitation: invitation,
                isProcessing: state.processingId == invitation.id,
                onAccept: () => _acceptInvitation(invitation),
                onDecline: () => _declineInvitation(invitation),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(LeagueInvitation invitation) async {
    final league = await ref.read(invitationsProvider.notifier).acceptInvitation(invitation.id);

    if (!mounted) return;

    if (league != null) {
      // Refresh my leagues list
      ref.read(myLeaguesProvider.notifier).loadLeagues();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${invitation.leagueName}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigate to the league
      context.push('/leagues/${league.id}');
    } else {
      final error = ref.read(invitationsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to accept invitation'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _declineInvitation(LeagueInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Invitation'),
        content: Text('Are you sure you want to decline the invitation to ${invitation.leagueName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref.read(invitationsProvider.notifier).declineInvitation(invitation.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation declined'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = ref.read(invitationsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to decline invitation'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
