import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_filter_chip.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../../core/widgets/states/app_empty_view.dart';
import '../../domain/waiver_claim.dart';
import '../../domain/waiver_claim_status.dart';
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
    ref.listen(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)), (prev, next) {
      if (next.isForbidden && prev?.isForbidden != true) {
        handleForbiddenNavigation(context, ref);
      }
    });

    final state = ref.watch(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Waiver Claims'),
        actions: [
          if (userRosterId != null) _buildBudgetChip(context, state),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildFilterChips(context, ref, state),
        ),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBudgetChip(BuildContext context, WaiversState state) {
    final budget = state.getBudgetForRoster(userRosterId!);
    if (budget == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Chip(
        avatar: Icon(Icons.account_balance_wallet, size: 16, color: colorScheme.primary),
        label: Text(
          '\$${budget.remainingBudget} / \$${budget.initialBudget}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, WaiversState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AppFilterChip(
            label: 'Pending${state.pendingCount > 0 ? ' (${state.pendingCount})' : ''}',
            selected: state.filter == 'pending',
            onSelected: () => ref
                .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                .setFilter('pending'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'All',
            selected: state.filter == 'all',
            onSelected: () => ref
                .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                .setFilter('all'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
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
        icon: state.filter == 'pending' ? Icons.hourglass_empty : Icons.receipt_long,
        title: state.filter == 'pending' ? 'No Pending Claims' : 'No Claims Found',
        subtitle: state.filter == 'pending'
            ? 'Submit waiver claims from the player list to add players to your roster'
            : 'No waiver claims match this filter',
      );
    }

    // For pending claims, show info header + reorderable list
    if (state.filter == 'pending') {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
            .loadWaiverData(),
        child: CustomScrollView(
          slivers: [
            // Info header with priority/schedule
            SliverToBoxAdapter(
              child: _WaiverInfoHeader(
                state: state,
                userRosterId: userRosterId,
              ),
            ),
            // Reorder explanation (only when multiple pending)
            if (claims.length > 1)
              const SliverToBoxAdapter(
                child: _ReorderExplanation(),
              ),
            // Claims list
            if (claims.length > 1)
              _buildReorderableSliverList(context, ref, claims, state)
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final claim = claims[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ClaimCard(
                          claim: claim,
                          claimOrder: index + 1,
                          onCancel: () => _handleCancel(context, ref, claim),
                        ),
                      );
                    },
                    childCount: claims.length,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Non-pending views: simple list
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

  Widget _buildReorderableSliverList(BuildContext context, WidgetRef ref, List<WaiverClaim> claims, WaiversState state) {
    // SliverReorderableList is not available, so we wrap ReorderableListView in a SliverFillRemaining
    return SliverFillRemaining(
      child: ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: claims.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex--;
          final ids = claims.map((c) => c.id).toList();
          final item = ids.removeAt(oldIndex);
          ids.insert(newIndex, item);
          final success = await ref
              .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
              .reorderClaims(ids);
          if (!success && context.mounted) {
            'Failed to reorder claims. Please try again.'.showAsError(ref);
          }
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
              isReordering: state.isReordering,
              onMoveUp: index > 0
                  ? () async {
                      final success = await ref
                          .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                          .moveClaimUp(claim.id);
                      if (!success && context.mounted) {
                        'Failed to reorder claims. Please try again.'.showAsError(ref);
                      }
                    }
                  : null,
              onMoveDown: index < claims.length - 1
                  ? () async {
                      final success = await ref
                          .read(waiversProvider((leagueId: leagueId, userRosterId: userRosterId)).notifier)
                          .moveClaimDown(claim.id);
                      if (!success && context.mounted) {
                        'Failed to reorder claims. Please try again.'.showAsError(ref);
                      }
                    }
                  : null,
              onCancel: () => _handleCancel(context, ref, claim),
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
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
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
        showSuccess(ref, 'Claim cancelled');
      }
    }
  }
}

/// Header showing waiver priority or FAAB budget info and schedule
class _WaiverInfoHeader extends StatelessWidget {
  final WaiversState state;
  final int? userRosterId;

  const _WaiverInfoHeader({
    required this.state,
    this.userRosterId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Processing schedule info
          _buildScheduleInfo(context, colorScheme),
          const SizedBox(height: 8),
          // Priority or FAAB info
          if (userRosterId != null) _buildPriorityOrBudgetInfo(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppSpacing.buttonRadius,
        border: Border.all(color: colorScheme.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Processing Schedule',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Schedule set by commissioner. Claims are processed in priority order.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOrBudgetInfo(BuildContext context, ColorScheme colorScheme) {
    if (state.isFaabLeague) {
      return _buildFaabInfo(context, colorScheme);
    }
    return _buildPriorityInfo(context, colorScheme);
  }

  Widget _buildFaabInfo(BuildContext context, ColorScheme colorScheme) {
    final budget = state.getBudgetForRoster(userRosterId!);
    if (budget == null) return const SizedBox.shrink();

    final percent = budget.remainingPercent;
    final budgetColor = percent > 50
        ? colorScheme.primary
        : percent > 20
            ? colorScheme.tertiary
            : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 18, color: budgetColor),
              const SizedBox(width: 8),
              Text(
                'FAAB Budget',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Text(
                '\$${budget.remainingBudget} remaining',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: budgetColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Budget progress bar
          ClipRRect(
            borderRadius: AppSpacing.badgeRadius,
            child: LinearProgressIndicator(
              value: budget.remainingBudget / (budget.initialBudget > 0 ? budget.initialBudget : 1),
              backgroundColor: colorScheme.surfaceContainerLow,
              color: budgetColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Highest bid wins. Claims are ordered by bid amount, then submission time.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityInfo(BuildContext context, ColorScheme colorScheme) {
    final priority = state.getPriorityForRoster(userRosterId!);
    if (priority == null) return const SizedBox.shrink();

    final totalTeams = state.totalTeams;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Row(
        children: [
          // Priority number badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${priority.priority}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Waiver Priority: #${priority.priority} of $totalTeams',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  priority.priority <= 3
                      ? 'High priority -- your claims are processed first.'
                      : 'Lower priority teams pick after higher ones. Priority resets after a successful claim.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Explanation banner for claim reordering
class _ReorderExplanation extends StatelessWidget {
  const _ReorderExplanation();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: AppSpacing.badgeRadius,
          border: Border.all(color: colorScheme.tertiaryContainer),
        ),
        child: Row(
          children: [
            Icon(Icons.drag_handle, size: 18, color: colorScheme.tertiary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Drag to reorder your claims. Claim #1 is processed first.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
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
    final colorScheme = Theme.of(context).colorScheme;

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
                      color: colorScheme.primary,
                      borderRadius: AppSpacing.badgeRadius,
                    ),
                    child: Text(
                      '#$claimOrder',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _ClaimStatusBadge(status: claim.status),
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
                      color: getPositionColor(claim.playerPosition!),
                      borderRadius: AppSpacing.badgeRadius,
                    ),
                    child: Text(
                      claim.playerPosition!,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
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
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.badgeRadius,
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Bid: \$${claim.bidAmount}',
                  style: TextStyle(
                    color: colorScheme.primary,
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
                  color: colorScheme.errorContainer,
                  borderRadius: AppSpacing.badgeRadius,
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        claim.failureReason!,
                        style: TextStyle(
                          color: colorScheme.error,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Submitted ${DateFormat.MMMd().add_jm().format(claim.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                if (claim.processedAt != null)
                  Text(
                    'Processed ${DateFormat.MMMd().add_jm().format(claim.processedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
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
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Unified status badge widget with consistent styling and icons
class _ClaimStatusBadge extends StatelessWidget {
  final WaiverClaimStatus status;

  const _ClaimStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (Color color, IconData icon) = _getStatusStyle(colorScheme);

    return Tooltip(
      message: status.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppSpacing.badgeRadius,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _getStatusStyle(ColorScheme colorScheme) {
    switch (status) {
      case WaiverClaimStatus.pending:
        return (colorScheme.tertiary, Icons.hourglass_empty);
      case WaiverClaimStatus.processing:
        return (colorScheme.tertiary, Icons.sync);
      case WaiverClaimStatus.successful:
        return (colorScheme.primary, Icons.check_circle_outline);
      case WaiverClaimStatus.failed:
        return (colorScheme.error, Icons.cancel_outlined);
      case WaiverClaimStatus.cancelled:
        return (colorScheme.outline, Icons.block);
      case WaiverClaimStatus.invalid:
        return (colorScheme.outline, Icons.warning_amber);
    }
  }
}

/// Reorderable claim card with drag handle and up/down buttons
class _ReorderableClaimCard extends StatelessWidget {
  final WaiverClaim claim;
  final int claimOrder;
  final bool isFirst;
  final bool isLast;
  final bool isReordering;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onCancel;

  const _ReorderableClaimCard({
    required this.claim,
    required this.claimOrder,
    required this.isFirst,
    required this.isLast,
    this.isReordering = false,
    this.onMoveUp,
    this.onMoveDown,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                color: colorScheme.outline,
              ),
            ),
          ),
          // Claim order badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$claimOrder',
                style: TextStyle(
                  color: colorScheme.onPrimary,
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
                            color: getPositionColor(claim.playerPosition!),
                            borderRadius: AppSpacing.badgeRadius,
                          ),
                          child: Text(
                            claim.playerPosition!,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
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
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: AppSpacing.badgeRadius,
                          ),
                          child: Text(
                            '\$${claim.bidAmount}',
                            style: TextStyle(
                              color: colorScheme.primary,
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
                          color: colorScheme.secondary,
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
          // Up/Down buttons (disabled while reordering)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 18),
                onPressed: isReordering ? null : onMoveUp,
                visualDensity: VisualDensity.compact,
                color: onMoveUp != null && !isReordering
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 18),
                onPressed: isReordering ? null : onMoveDown,
                visualDensity: VisualDensity.compact,
                color: onMoveDown != null && !isReordering
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
          // Cancel button
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            color: colorScheme.error,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
