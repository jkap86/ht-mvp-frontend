import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme_provider.dart';
import '../../../core/providers/league_context_provider.dart';
import '../../../core/widgets/skeletons/skeletons.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../commissioner/presentation/providers/commissioner_provider.dart';
import '../../commissioner/presentation/providers/league_invitations_provider.dart';
import '../../leagues/data/invitations_provider.dart';
import '../../leagues/data/league_repository.dart';
import '../../leagues/data/public_leagues_provider.dart';
import '../../leagues/presentation/providers/league_detail_provider.dart';
import '../../notifications/presentation/providers/notifications_provider.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import 'providers/home_dashboard_provider.dart';
import 'widgets/home_draft_alert_card.dart';
import 'widgets/home_leagues_card.dart';
import 'widgets/home_matchups_card.dart';
import 'widgets/home_pending_trades_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final dashboardState = ref.watch(homeDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user?.username ?? 'Home'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();

              // Invalidate global user-specific providers
              ref.invalidate(myLeaguesProvider);
              ref.invalidate(invitationsProvider);
              ref.invalidate(publicLeaguesProvider);
              ref.invalidate(homeDashboardProvider);
              ref.invalidate(notificationsProvider);

              // Invalidate family providers (clears ALL cached instances)
              ref.invalidate(leagueDetailProvider);
              ref.invalidate(leagueContextProvider);
              ref.invalidate(commissionerProvider);
              ref.invalidate(leagueInvitationsProvider);

              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeDashboardProvider.notifier).loadDashboard(),
        child: _buildBody(context, dashboardState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeDashboardState state) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active drafts (highest priority - shown first if any)
              HomeDraftAlertCard(drafts: state.upcomingDrafts),
              if (state.upcomingDrafts.isNotEmpty) const SizedBox(height: 12),

              // Pending trades requiring action
              HomePendingTradesCard(trades: state.pendingTrades),
              if (state.pendingTrades.isNotEmpty) const SizedBox(height: 12),

              // This week's matchups
              HomeMatchupsCard(matchups: state.matchups),
              if (state.matchups.isNotEmpty) const SizedBox(height: 12),

              // Leagues card (always shown)
              HomeLeaguesCard(leagues: state.leagues),

              // Empty state for new users
              if (state.leagues.isEmpty) ...[
                const SizedBox(height: 24),
                _buildEmptyState(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Leagues card skeleton
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SkeletonShimmer(
                    child: Row(
                      children: [
                        const SkeletonBox(width: 48, height: 48, borderRadius: 12),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SkeletonBox(height: 16, width: 100),
                              SizedBox(height: 8),
                              SkeletonBox(height: 12, width: 140),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Matchups skeleton
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SkeletonShimmer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            SkeletonCircle(size: 20),
                            SizedBox(width: 8),
                            SkeletonBox(height: 16, width: 160),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const SkeletonBox(height: 50),
                        const SizedBox(height: 8),
                        const SkeletonBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.sports_football_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to HypeTrainFF!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started by creating or joining a league.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push('/leagues/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/leagues/discover'),
                  icon: const Icon(Icons.search),
                  label: const Text('Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
