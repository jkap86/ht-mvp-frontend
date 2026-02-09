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

    // Use sortedPendingClaims for pending filter, filteredClaims for others
    final claims = state.filter == 'pending' ? state.sortedPendingClaims : state.filteredClaims;

    if (claims.isEmpty) {
      return AppEmptyView(
        icon: Icons.access_time,
        title: 'No Claims',
        subtitle: state.filter == 'pending'
            ? 'You have no pending waiver claims'
            : 'No waiver claims found',
      );
    }

    // For pending claims, use ReorderableListView
    if (state.filter == 'pending' && claims.length > 1) {
      return _buildReorderablePendingList(context, ref, claims);
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
              claimOrder: claim.status.isPending ? index + 1 : null,
              onCancel: claim.status.isPending
                  ? () => _handleCancel(context, ref, claim)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReorderablePendingList(BuildContext context, WidgetRef ref, List<WaiverClaim> claims) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: claims.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final ids = claims.map((c) => c.id).toList();
        final item = ids.removeAt(oldIndex);
        ids.insert(newIndex, item);
        ref
            .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
            .reorderClaims(ids);
      },
      itemBuilder: (context, index) {
        final claim = claims[index];
        return Padding(
          key: ValueKey('claim-${claim.id}'),
          padding: const EdgeInsets.only(bottom: 12),
          child: _ReorderableClaimCard(
            claim: claim,
            claimOrder: index + 1,
            isFirst: index == 0,
            isLast: index == claims.length - 1,
            onMoveUp: index > 0
                ? () => ref
                    .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                    .moveClaimUp(claim.id)
                : null,
            onMoveDown: index < claims.length - 1
                ? () => ref
                    .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                    .moveClaimDown(claim.id)
                : null,
            onCancel: () => _handleCancel(context, ref, claim),
          ),
        );
      },
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
  final int? claimOrder;
  final VoidCallback? onCancel;

  const _ClaimCard({
    required this.claim,
    this.claimOrder,
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
            // Header with claim order (if pending) and status
            Row(
              children: [
                if (claimOrder != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$claimOrder',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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

/// Reorderable claim card with drag handle and up/down buttons
class _ReorderableClaimCard extends StatelessWidget {
  final WaiverClaim claim;
  final int claimOrder;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onCancel;

  const _ReorderableClaimCard({
    required this.claim,
    required this.claimOrder,
    required this.isFirst,
    required this.isLast,
    this.onMoveUp,
    this.onMoveDown,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: claimOrder - 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          // Claim order badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$claimOrder',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Claim content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (claim.playerPosition != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPositionColor(claim.playerPosition!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            claim.playerPosition!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          claim.playerName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (claim.playerTeam != null) ...[
                        Text(
                          claim.playerTeam!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (claim.bidAmount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '\$${claim.bidAmount}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (claim.dropPlayerName != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.swap_horiz,
                          size: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            claim.dropPlayerName!,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Up/Down buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: onMoveUp,
                visualDensity: VisualDensity.compact,
                color: onMoveUp != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: onMoveDown,
                visualDensity: VisualDensity.compact,
                color: onMoveDown != null
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            color: Colors.red,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
        ],
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
