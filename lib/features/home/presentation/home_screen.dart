import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme_provider.dart';
import '../../../core/widgets/states/states.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../leagues/data/league_repository.dart';
import 'widgets/create_league_dialog.dart';
import 'widgets/join_league_dialog.dart';
import 'widgets/league_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(myLeaguesProvider.notifier).loadLeagues());
  }

  @override
  Widget build(BuildContext context) {
    final leaguesState = ref.watch(myLeaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leagues'),
        actions: [
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
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _buildBody(leaguesState),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: () => showJoinLeagueDialog(
              context,
              onJoinLeague: (code) =>
                  ref.read(myLeaguesProvider.notifier).joinLeague(code),
            ),
            icon: const Icon(Icons.group_add),
            label: const Text('Join'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => showCreateLeagueDialog(
              context,
              onCreateLeague: ({
                required name,
                required season,
                required totalRosters,
                required scoringSettings,
                required mode,
                required settings,
              }) =>
                  ref.read(myLeaguesProvider.notifier).createLeague(
                        name: name,
                        season: season,
                        totalRosters: totalRosters,
                        scoringSettings: scoringSettings,
                        mode: mode,
                        settings: settings,
                      ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LeaguesState leaguesState) {
    if (leaguesState.isLoading) {
      return const AppLoadingView();
    }

    if (leaguesState.error != null) {
      return AppErrorView(
        message: leaguesState.error!,
        onRetry: () => ref.read(myLeaguesProvider.notifier).loadLeagues(),
      );
    }

    if (leaguesState.leagues.isEmpty) {
      return const AppEmptyView(
        icon: Icons.sports_football,
        title: 'No leagues yet',
        subtitle: 'Create or join a league to get started',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myLeaguesProvider.notifier).loadLeagues(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaguesState.leagues.length,
        itemBuilder: (context, index) {
          final league = leaguesState.leagues[index];
          return LeagueCard(league: league);
        },
      ),
    );
  }
}
