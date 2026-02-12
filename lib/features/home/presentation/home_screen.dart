import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/providers/league_context_provider.dart';
import '../../../core/widgets/skeletons/skeletons.dart';
import '../../../core/widgets/states/app_error_view.dart';
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
        title: const Text('HypeTrain'),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => _SettingsSheet(
                  username: user?.username,
                  onLogout: () async {
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
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeDashboardProvider.notifier).loadDashboard(),
        child: _buildBody(context, ref, dashboardState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, HomeDashboardState state) {
    if (state.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (state.error != null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () => ref.read(homeDashboardProvider.notifier).loadDashboard(),
      );
    }

    // Get active drafts and pending trades for urgency banners
    final activeDrafts = state.upcomingDrafts.where((d) => d.isInProgress).toList();
    final pendingTrades = state.pendingTrades;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // URGENCY BANNERS (time-sensitive actions first)
              if (pendingTrades.isNotEmpty)
                _buildUrgencyBanner(
                  context,
                  icon: Icons.swap_horiz,
                  color: Theme.of(context).colorScheme.tertiary,
                  title: 'Trade Pending',
                  subtitle: '${pendingTrades.length} trade${pendingTrades.length > 1 ? 's' : ''} awaiting response',
                  onTap: () => context.push(
                    '/leagues/${pendingTrades.first.leagueId}/trades/${pendingTrades.first.trade.id}',
                  ),
                ),
              if (pendingTrades.isNotEmpty)
                const SizedBox(height: 12),

              // Lineup check reminder when matchups are active
              if (state.matchups.isNotEmpty)
                _buildLineupCheckBanner(context, state),
              if (state.matchups.isNotEmpty)
                const SizedBox(height: 12),

              // 1. DRAFTS
              HomeDraftsCard(activeCount: activeDrafts.length),
              const SizedBox(height: 12),

              // 3. MATCHUPS (what users want to see)
              if (state.matchups.isNotEmpty) ...[
                HomeMatchupsCard(matchups: state.matchups),
                const SizedBox(height: 12),
              ],

              // 4. TRANSACTIONS (actionable items)
              HomeTransactionsCard(tradeCount: state.pendingTrades.length),
              const SizedBox(height: 12),

              // 5. LEAGUES (navigation)
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
          constraints: const BoxConstraints(maxWidth: 600),
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

  Widget _buildUrgencyBanner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineupCheckBanner(BuildContext context, HomeDashboardState state) {
    // Count leagues with matchups where user has a roster
    final leaguesWithMatchups = state.matchups
        .map((m) => (leagueId: m.leagueId, rosterId: m.userRosterId))
        .where((e) => e.rosterId != null)
        .toSet();

    if (leaguesWithMatchups.isEmpty) return const SizedBox.shrink();

    final count = leaguesWithMatchups.length;
    final first = leaguesWithMatchups.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          onTap: () => context.push(
            '/leagues/${first.leagueId}/team/${first.rosterId}',
          ),
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set Your Lineups',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        count == 1
                            ? 'You have an active matchup'
                            : 'You have matchups in $count leagues',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  final String? username;
  final VoidCallback onLogout;

  const _SettingsSheet({
    required this.username,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Username header
            if (username != null) ...[
              Icon(
                Icons.account_circle,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                username!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              const Divider(),
            ],
            // Theme toggle
            ListTile(
              leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: isDark,
                onChanged: (_) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
              ),
            ),
            // Logout
            ListTile(
              leading: Icon(Icons.logout, color: colorScheme.error),
              title: Text(
                'Logout',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
