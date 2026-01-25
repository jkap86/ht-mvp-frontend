import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../../core/widgets/states/app_empty_view.dart';
import '../../domain/waiver_claim.dart';
import '../providers/waiver_provider.dart';

class MyClaimsScreen extends ConsumerWidget {
  final int leagueId;
  final int? userRosterId;

  const MyClaimsScreen({
    super.key,
    required this.leagueId,
    this.userRosterId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Waiver Claims'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterChips(context, ref, state),
        ),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, WaiversState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'Pending',
            selected: state.filter == 'pending',
            onSelected: () => ref
                .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                .setFilter('pending'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'All',
            selected: state.filter == 'all',
            onSelected: () => ref
                .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                .setFilter('all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Completed',
            selected: state.filter == 'completed',
            onSelected: () => ref
                .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                .setFilter('completed'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, WaiversState state) {
    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading claims...');
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref
            .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
            .loadWaiverData(),
      );
    }

    final claims = state.filteredClaims;

    if (claims.isEmpty) {
      return AppEmptyView(
        icon: Icons.access_time,
        title: 'No Claims',
        subtitle: state.filter == 'pending'
            ? 'You have no pending waiver claims'
            : 'No waiver claims found',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
          .loadWaiverData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: claims.length,
        itemBuilder: (context, index) {
          final claim = claims[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ClaimCard(
              claim: claim,
              onCancel: claim.status.isPending
                  ? () => _handleCancel(context, ref, claim)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref, WaiverClaim claim) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Claim?'),
        content: Text('Are you sure you want to cancel your claim for ${claim.playerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Claim'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
          .cancelClaim(claim.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claim cancelled')),
        );
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final WaiverClaim claim;
  final VoidCallback? onCancel;

  const _ClaimCard({
    required this.claim,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                _buildStatusBadge(context),
                const Spacer(),
                Text(
                  'Week ${claim.week}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Player being claimed
            Row(
              children: [
                if (claim.playerPosition != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPositionColor(claim.playerPosition!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      claim.playerPosition!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.playerName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (claim.playerTeam != null)
                        Text(
                          claim.playerTeam!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Bid amount (if any)
            if (claim.bidAmount > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Bid: \$${claim.bidAmount}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            // Drop player (if any)
            if (claim.dropPlayerId != null && claim.dropPlayerName != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dropping: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${claim.dropPlayerPosition ?? ''} ${claim.dropPlayerName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],

            // Failure reason (if failed)
            if (claim.status.isFailed && claim.failureReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        claim.failureReason!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Timestamps
            const SizedBox(height: 8),
            Text(
              'Created ${DateFormat.MMMd().add_jm().format(claim.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),

            // Cancel button for pending claims
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Cancel Claim'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    switch (claim.status.value) {
      case 'pending':
        color = Colors.orange;
        break;
      case 'successful':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        claim.status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      case 'K':
        return Colors.purple;
      case 'DEF':
      case 'DST':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
