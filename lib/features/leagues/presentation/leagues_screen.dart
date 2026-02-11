import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/states/states.dart';
import '../data/league_repository.dart';
import '../../home/presentation/widgets/league_card.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import 'widgets/leagues_search_bar.dart';

class LeaguesScreen extends ConsumerStatefulWidget {
  const LeaguesScreen({super.key});

  @override
  ConsumerState<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends ConsumerState<LeaguesScreen> {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Leagues'),
        actions: const [
          NotificationBell(),
        ],
        bottom: leaguesState.leagues.isNotEmpty
            ? const PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: LeaguesSearchBar(),
              )
            : null,
      ),
      body: Stack(
        children: [
          _buildBody(leaguesState),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'add-league',
              onPressed: () => context.push('/leagues/add'),
              child: const Icon(Icons.add),
            ),
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

    final filtered = leaguesState.filteredLeagues;
    final hasActiveFilters = leaguesState.filters.hasActiveFilters ||
        leaguesState.filters.searchQuery.isNotEmpty;

    if (filtered.isEmpty && hasActiveFilters) {
      return AppEmptyView(
        icon: Icons.search_off,
        title: 'No leagues match your filters',
        subtitle: 'Try adjusting your search or filters',
        action: TextButton(
          onPressed: () {
            ref.read(myLeaguesProvider.notifier).clearAllFilters();
          },
          child: const Text('Clear Filters'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myLeaguesProvider.notifier).loadLeagues(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final league = filtered[index];
              return LeagueCard(
                league: league,
                onNavigate: () => ref.read(myLeaguesProvider.notifier).loadLeagues(),
              );
            },
          ),
        ),
      ),
    );
  }
}
