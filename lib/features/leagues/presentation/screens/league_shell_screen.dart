import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/league_dashboard_provider.dart';

/// Shell screen that provides bottom navigation for league sub-screens.
/// Uses StatefulShellRoute to preserve state across tab navigation.
class LeagueShellScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final StatefulNavigationShell navigationShell;

  const LeagueShellScreen({
    super.key,
    required this.leagueId,
    required this.navigationShell,
  });

  @override
  ConsumerState<LeagueShellScreen> createState() => _LeagueShellScreenState();
}

class _LeagueShellScreenState extends ConsumerState<LeagueShellScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(leagueDashboardProvider(widget.leagueId));

    // Calculate badge counts from dashboard data
    final pendingTradesCount = dashboardState.pendingTrades;
    final unreadMessagesCount = dashboardState.unreadChatMessages;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Team',
          ),
          const NavigationDestination(
            icon: Icon(Icons.sports_football_outlined),
            selectedIcon: Icon(Icons.sports_football),
            label: 'Matchups',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingTradesCount > 0,
              label: Text('$pendingTradesCount'),
              child: const Icon(Icons.swap_horiz_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: pendingTradesCount > 0,
              label: Text('$pendingTradesCount'),
              child: const Icon(Icons.swap_horiz),
            ),
            label: 'Trades',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: 'Players',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadMessagesCount > 0,
              label: Text('$unreadMessagesCount'),
              child: const Icon(Icons.emoji_events_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadMessagesCount > 0,
              label: Text('$unreadMessagesCount'),
              child: const Icon(Icons.emoji_events),
            ),
            label: 'League',
          ),
        ],
      ),
    );
  }
}
