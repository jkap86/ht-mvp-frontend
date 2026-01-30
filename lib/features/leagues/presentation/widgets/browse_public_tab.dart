import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final joinedLeague = await ref.read(publicLeaguesProvider.notifier).joinLeague(league.id);

    if (!mounted) return;

    if (joinedLeague != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully joined ${league.name}!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Invalidate cached provider to prevent stale "not member" errors
      ref.invalidate(leagueDetailProvider(joinedLeague.id));
      // Navigate to the league
      context.push('/leagues/${joinedLeague.id}');
    } else {
      final error = ref.read(publicLeaguesProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to join league'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
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
                  Icons.people,
                  league.memberCountDisplay,
                  league.isFull ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  context,
                  Icons.sports_football,
                  _formatMode(league.mode),
                  colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: league.isFull || isJoining ? null : onJoin,
                icon: isJoining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(league.isFull ? Icons.block : Icons.login),
                label: Text(
                  isJoining
                      ? 'Joining...'
                      : league.isFull
                          ? 'League Full'
                          : 'Join League',
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
