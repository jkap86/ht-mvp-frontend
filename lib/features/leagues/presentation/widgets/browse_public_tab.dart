import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/idempotency.dart';
import '../../../../core/widgets/states/states.dart';
import '../../data/public_leagues_provider.dart';
import '../../domain/league.dart';
import '../providers/league_detail_provider.dart';

class BrowsePublicTab extends ConsumerStatefulWidget {
  const BrowsePublicTab({super.key});

  @override
  ConsumerState<BrowsePublicTab> createState() => _BrowsePublicTabState();
}

class _BrowsePublicTabState extends ConsumerState<BrowsePublicTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(publicLeaguesProvider.notifier).loadPublicLeagues());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(publicLeaguesProvider);

    if (state.isLoading && state.leagues.isEmpty) {
      return const AppLoadingView();
    }

    if (state.error != null && state.leagues.isEmpty) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(publicLeaguesProvider.notifier).loadPublicLeagues(),
      );
    }

    if (state.leagues.isEmpty) {
      return const AppEmptyView(
        icon: Icons.search_off,
        title: 'No public leagues available',
        subtitle: 'Check back later or create your own public league',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(publicLeaguesProvider.notifier).loadPublicLeagues(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.leagues.length,
            itemBuilder: (context, index) {
              final league = state.leagues[index];
              return _PublicLeagueCard(
                league: league,
                isJoining: state.joiningLeagueId == league.id,
                onJoin: () => _joinLeague(league),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _joinLeague(PublicLeague league) async {
    // Show confirmation dialog for bench joining
    if (league.canJoinAsBench) {
      final confirmed = await _showBenchJoinDialog(league);
      if (confirmed != true) return;
    }

    final key = newIdempotencyKey();
    final joinedLeague = await ref.read(publicLeaguesProvider.notifier).joinLeague(league.id, idempotencyKey: key);

    if (!mounted) return;

    if (joinedLeague != null) {
      final message = league.canJoinAsBench
          ? 'Joined ${league.name} as bench member'
          : 'Successfully joined ${league.name}!';
      showSuccess(ref, message);
      // Invalidate cached provider to prevent stale "not member" errors
      ref.invalidate(leagueDetailProvider(joinedLeague.id));
      // Navigate to the league
      context.push('/leagues/${joinedLeague.id}');
    } else {
      final error = ref.read(publicLeaguesProvider).error;
      (error ?? 'Failed to join league').showAsError(ref);
    }
  }

  Future<bool?> _showBenchJoinDialog(PublicLeague league) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join as Bench Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This league is at capacity but not all members have paid their dues.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'You can join as a bench member. You\'ll be able to participate once a spot opens up or the commissioner reinstates you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (league.hasDues && league.buyInAmount != null) ...[
              const SizedBox(height: 12),
              Text(
                'Buy-in: ${league.buyInDisplay}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Join as Bench'),
          ),
        ],
      ),
    );
  }
}

class _PublicLeagueCard extends StatelessWidget {
  final PublicLeague league;
  final bool isJoining;
  final VoidCallback onJoin;

  const _PublicLeagueCard({
    required this.league,
    required this.isJoining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    league.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!league.isPublic) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: AppSpacing.cardRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: colorScheme.onTertiaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          'Invite Only',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (league.isFull) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: AppSpacing.cardRadius,
                    ),
                    child: Text(
                      'Full',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: AppSpacing.cardRadius,
                  ),
                  child: Text(
                    league.season,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(
                  context,
                  _getStatusIcon(league.fillStatus),
                  league.memberCountDisplay,
                  _getStatusColor(league.fillStatus, colorScheme),
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  context,
                  Icons.sports_football,
                  _formatMode(league.mode),
                  colorScheme.secondary,
                ),
                if (league.hasDues) ...[
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    context,
                    Icons.attach_money,
                    league.buyInDisplay,
                    colorScheme.tertiary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _buildJoinButton(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(FillStatus status) {
    switch (status) {
      case FillStatus.open:
        return Icons.group;
      case FillStatus.waitingPayment:
        return Icons.hourglass_empty;
      case FillStatus.filled:
        return Icons.block;
    }
  }

  Color _getStatusColor(FillStatus status, ColorScheme colorScheme) {
    switch (status) {
      case FillStatus.open:
        return colorScheme.primary;
      case FillStatus.waitingPayment:
        return colorScheme.tertiary;
      case FillStatus.filled:
        return colorScheme.error;
    }
  }

  Widget _buildJoinButton(ColorScheme colorScheme) {
    if (isJoining) {
      return FilledButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Joining...'),
      );
    }

    switch (league.fillStatus) {
      case FillStatus.open:
        return FilledButton.icon(
          onPressed: onJoin,
          icon: const Icon(Icons.login),
          label: const Text('Join League'),
        );
      case FillStatus.waitingPayment:
        return FilledButton.tonalIcon(
          onPressed: onJoin,
          icon: const Icon(Icons.person_add),
          label: const Text('Join as Bench'),
        );
      case FillStatus.filled:
        return FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.block),
          label: const Text('League Full'),
        );
    }
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  String _formatMode(String mode) {
    switch (mode) {
      case 'redraft':
        return 'Redraft';
      case 'dynasty':
        return 'Dynasty';
      case 'keeper':
        return 'Keeper';
      default:
        return mode;
    }
  }
}
