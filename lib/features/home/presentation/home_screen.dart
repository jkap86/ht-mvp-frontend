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
import 'widgets/home_drafts_card.dart';
import 'widgets/home_leagues_card.dart';
import 'widgets/home_matchups_card.dart';
import 'widgets/home_transactions_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider.select((s) => s.user));
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
              // 1. DRAFTS (always shown, highlights active drafts)
              HomeDraftsCard(
                activeCount: state.upcomingDrafts.where((d) => d.isInProgress).length,
              ),
              const SizedBox(height: 12),

              // 2. MATCHUPS (what users want to see)
              if (state.matchups.isNotEmpty) ...[
                HomeMatchupsCard(matchups: state.matchups),
                const SizedBox(height: 12),
              ],

              // 3. TRANSACTIONS (actionable items)
              HomeTransactionsCard(tradeCount: state.pendingTrades.length),
              const SizedBox(height: 12),

              // 4. LEAGUES (navigation)
              HomeLeaguesCard(leagueCount: state.leagues.length),
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
          child: SkeletonShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardSkeleton(),
                const SizedBox(height: 12),
                _buildCardSkeleton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSkeleton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
    );
  }

}
