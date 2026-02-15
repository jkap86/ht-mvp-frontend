import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/utils/error_display.dart';
import '../../../core/widgets/app_filter_chip.dart';
import '../../../core/widgets/states/app_loading_view.dart';
import '../../../core/widgets/states/app_error_view.dart';
import '../../../core/widgets/states/app_empty_view.dart';
import '../../home/presentation/providers/home_dashboard_provider.dart';
import '../../home/presentation/widgets/home_pending_trades_card.dart';
import '../domain/activity_item.dart';
import 'providers/transactions_provider.dart';

/// Screen showing the league transaction/activity log.
///
/// When [leagueId] is provided, shows the full activity feed for that league.
/// When [leagueId] is null, falls back to the global pending trades view.
class TransactionsScreen extends ConsumerWidget {
  final int? leagueId;

  const TransactionsScreen({
    super.key,
    this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (leagueId != null) {
      return _LeagueActivityFeed(leagueId: leagueId!);
    }
    return const _PendingTradesView();
  }
}

/// Fallback view: shows pending trades across all leagues (original behavior)
class _PendingTradesView extends ConsumerWidget {
  const _PendingTradesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Transactions'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeDashboardProvider.notifier).loadDashboard(),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeDashboardState state) {
    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading transactions...');
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
      );
    }

    if (state.pendingTrades.isEmpty) {
      return const AppEmptyView(
        icon: Icons.swap_horiz_outlined,
        title: 'No Pending Trades',
        subtitle: 'Trades requiring your action will appear here',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: HomePendingTradesCard(trades: state.pendingTrades),
        ),
      ),
    );
  }
}

/// League-specific activity feed view
class _LeagueActivityFeed extends ConsumerStatefulWidget {
  final int leagueId;

  const _LeagueActivityFeed({required this.leagueId});

  @override
  ConsumerState<_LeagueActivityFeed> createState() => _LeagueActivityFeedState();
}

class _LeagueActivityFeedState extends ConsumerState<_LeagueActivityFeed> {
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        transactionsProvider(widget.leagueId),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsProvider(widget.leagueId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Transaction Log'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTypeFilters(context, ref, state),
        ),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildTypeFilters(BuildContext context, WidgetRef ref, TransactionsState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AppFilterChip(
            label: 'All',
            selected: state.typeFilter == 'all',
            onSelected: () => ref.read(transactionsProvider(widget.leagueId).notifier).setTypeFilter('all'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Trades',
            selected: state.typeFilter == 'trade',
            onSelected: () => ref.read(transactionsProvider(widget.leagueId).notifier).setTypeFilter('trade'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Waivers',
            selected: state.typeFilter == 'waiver',
            onSelected: () => ref.read(transactionsProvider(widget.leagueId).notifier).setTypeFilter('waiver'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Adds',
            selected: state.typeFilter == 'add',
            onSelected: () => ref.read(transactionsProvider(widget.leagueId).notifier).setTypeFilter('add'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Drops',
            selected: state.typeFilter == 'drop',
            onSelected: () => ref.read(transactionsProvider(widget.leagueId).notifier).setTypeFilter('drop'),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Draft',
            selected: state.typeFilter == 'draft',
            onSelected: () => ref.read(transactionsProvider(widget.leagueId).notifier).setTypeFilter('draft'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, TransactionsState state) {
    if (state.isLoading) {
      return const AppLoadingView(message: 'Loading transactions...');
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(transactionsProvider(widget.leagueId).notifier).loadActivities(),
      );
    }

    if (state.activities.isEmpty) {
      return AppEmptyView(
        icon: Icons.receipt_long,
        title: 'No Transactions Yet',
        subtitle: _getEmptySubtitle(state.typeFilter),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(transactionsProvider(widget.leagueId).notifier).loadActivities(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              state.hasMore &&
              !state.isLoadingMore) {
            ref.read(transactionsProvider(widget.leagueId).notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.activities.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.activities.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final activity = state.activities[index];
            final showDateSeparator = _shouldShowDateSeparator(state.activities, index);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDateSeparator)
                  _DateSeparator(date: activity.timestamp),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActivityCard(activity: activity),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getEmptySubtitle(String typeFilter) {
    switch (typeFilter) {
      case 'trade':
        return 'No completed trades in this league yet';
      case 'waiver':
        return 'No processed waiver claims yet';
      case 'add':
        return 'No free agent pickups yet';
      case 'drop':
        return 'No player drops yet';
      case 'draft':
        return 'No draft picks yet';
      default:
        return 'Transaction history will appear here as league activity occurs';
    }
  }

  bool _shouldShowDateSeparator(List<ActivityItem> activities, int index) {
    if (index == 0) return true;

    final currentDate = _dateOnly(activities[index].timestamp);
    final previousDate = _dateOnly(activities[index - 1].timestamp);

    return currentDate != previousDate;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

/// Date separator widget between activity groups
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String label;
    if (dateOnly == today) {
      label = 'Today';
    } else if (dateOnly == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat.MMMEd().format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Divider(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual activity card
class _ActivityCard extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            _buildTypeIcon(colorScheme),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source type badge and timestamp
                  Row(
                    children: [
                      _buildSourceBadge(context, colorScheme),
                      const Spacer(),
                      Text(
                        DateFormat.jm().format(activity.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Activity content based on type
                  _buildContent(context, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ColorScheme colorScheme) {
    final (IconData icon, Color color) = _getTypeStyle(colorScheme);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  (IconData, Color) _getTypeStyle(ColorScheme colorScheme) {
    switch (activity.type) {
      case ActivityType.trade:
        return (Icons.swap_horiz, colorScheme.secondary);
      case ActivityType.waiver:
        return (Icons.access_time, colorScheme.tertiary);
      case ActivityType.add:
        return (Icons.add_circle_outline, colorScheme.primary);
      case ActivityType.drop:
        return (Icons.remove_circle_outline, colorScheme.error);
      case ActivityType.draft:
        return (Icons.sports_football, colorScheme.primary);
    }
  }

  Widget _buildSourceBadge(BuildContext context, ColorScheme colorScheme) {
    final (Color bgColor, Color textColor) = _getSourceBadgeColors(colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppSpacing.badgeRadius,
      ),
      child: Text(
        activity.type.label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _getSourceBadgeColors(ColorScheme colorScheme) {
    switch (activity.type) {
      case ActivityType.trade:
        return (
          colorScheme.secondary.withValues(alpha: 0.1),
          colorScheme.secondary
        );
      case ActivityType.waiver:
        return (
          colorScheme.tertiary.withValues(alpha: 0.1),
          colorScheme.tertiary
        );
      case ActivityType.add:
        return (
          colorScheme.primary.withValues(alpha: 0.1),
          colorScheme.primary
        );
      case ActivityType.drop:
        return (
          colorScheme.error.withValues(alpha: 0.1),
          colorScheme.error
        );
      case ActivityType.draft:
        return (
          colorScheme.primary.withValues(alpha: 0.1),
          colorScheme.primary
        );
    }
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    switch (activity.type) {
      case ActivityType.trade:
        return _buildTradeContent(context, colorScheme);
      case ActivityType.waiver:
        return _buildWaiverContent(context, colorScheme);
      case ActivityType.add:
      case ActivityType.drop:
        return _buildAddDropContent(context, colorScheme);
      case ActivityType.draft:
        return _buildDraftContent(context, colorScheme);
    }
  }

  Widget _buildTradeContent(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team names
        RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: activity.tradeProposerTeamName ?? 'Team',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(text: ' traded with '),
              TextSpan(
                text: activity.tradeRecipientTeamName ?? 'Team',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Item counts
        Row(
          children: [
            Icon(Icons.people_outline, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${activity.tradePlayerCount} player(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (activity.tradePickCount > 0) ...[
              const SizedBox(width: 12),
              Icon(Icons.confirmation_number_outlined, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${activity.tradePickCount} pick(s)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWaiverContent(BuildContext context, ColorScheme colorScheme) {
    final added = activity.waiverPlayerAdded;
    final dropped = activity.waiverPlayerDropped;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team name
        Text(
          activity.waiverTeamName ?? 'Unknown',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        // Player added (green arrow up)
        if (added != null)
          _PlayerMoveRow(
            icon: Icons.arrow_upward,
            iconColor: colorScheme.primary,
            label: 'Added',
            playerName: added['name'] as String? ?? '?',
            position: added['position'] as String?,
            team: added['team'] as String?,
          ),
        // Player dropped (red arrow down)
        if (dropped != null) ...[
          const SizedBox(height: 4),
          _PlayerMoveRow(
            icon: Icons.arrow_downward,
            iconColor: colorScheme.error,
            label: 'Dropped',
            playerName: dropped['name'] as String? ?? '?',
            position: dropped['position'] as String?,
            team: dropped['team'] as String?,
          ),
        ],
        // FAAB bid info
        if (activity.waiverBidAmount != null && activity.waiverBidAmount! > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.attach_money, size: 14, color: colorScheme.tertiary),
              const SizedBox(width: 4),
              Text(
                'Bid: \$${activity.waiverBidAmount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddDropContent(BuildContext context, ColorScheme colorScheme) {
    final player = activity.addDropPlayer;
    final isAdd = activity.isAdd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team name
        Text(
          activity.addDropTeamName ?? 'Unknown',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        if (player != null)
          _PlayerMoveRow(
            icon: isAdd ? Icons.arrow_upward : Icons.arrow_downward,
            iconColor: isAdd ? colorScheme.primary : colorScheme.error,
            label: isAdd ? 'Added' : 'Dropped',
            playerName: player['name'] as String? ?? '?',
            position: player['position'] as String?,
            team: player['team'] as String?,
          ),
      ],
    );
  }

  Widget _buildDraftContent(BuildContext context, ColorScheme colorScheme) {
    final player = activity.draftPlayer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team name
        Text(
          activity.draftTeamName ?? 'Unknown',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        if (player != null)
          _PlayerMoveRow(
            icon: Icons.sports_football,
            iconColor: colorScheme.primary,
            label: 'Rd ${activity.draftRound}, Pick ${activity.draftPickNumber}',
            playerName: player['name'] as String? ?? '?',
            position: player['position'] as String?,
            team: player['team'] as String?,
          ),
        if (activity.draftIsAutoPick) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.smart_toy, size: 14, color: colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                'Auto-pick',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A row showing player movement (add/drop/draft)
class _PlayerMoveRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String playerName;
  final String? position;
  final String? team;

  const _PlayerMoveRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.playerName,
    this.position,
    this.team,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        if (position != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: getPositionColor(position!),
              borderRadius: AppSpacing.badgeRadius,
            ),
            child: Text(
              position!,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            playerName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (team != null)
          Text(
            team!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
      ],
    );
  }
}
