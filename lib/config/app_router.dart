import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/leagues/presentation/league_detail_screen.dart';
import '../features/drafts/presentation/draft_room_screen.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/rosters/presentation/screens/team_screen.dart';
import '../features/rosters/presentation/screens/free_agents_screen.dart';
import '../features/matchups/presentation/screens/matchup_screen.dart';
import '../features/matchups/presentation/screens/standings_screen.dart';
import '../features/trades/presentation/screens/trades_list_screen.dart';
import '../features/trades/presentation/screens/trade_detail_screen.dart';
import '../features/trades/presentation/screens/propose_trade_screen.dart';

// Listenable that notifies when auth state changes
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final _authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(_authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      // Read current auth state (not watch - this is in redirect callback)
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Don't redirect while loading
      if (isLoading) return null;

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/leagues/:leagueId',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          return LeagueDetailScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/drafts/:draftId',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          final draftId = int.parse(state.pathParameters['draftId']!);
          return DraftRoomScreen(leagueId: leagueId, draftId: draftId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/team/:rosterId',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          final rosterId = int.parse(state.pathParameters['rosterId']!);
          return TeamScreen(leagueId: leagueId, rosterId: rosterId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/free-agents',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          final rosterId = state.extra as int? ?? 0;
          return FreeAgentsScreen(leagueId: leagueId, rosterId: rosterId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/matchups',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          return MatchupScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/standings',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          return StandingsScreen(leagueId: leagueId);
        },
      ),
      // Trades routes
      GoRoute(
        path: '/leagues/:leagueId/trades',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          return TradesListScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/trades/propose',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          return ProposeTradeScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/trades/:tradeId',
        builder: (context, state) {
          final leagueId = int.parse(state.pathParameters['leagueId']!);
          final tradeId = int.parse(state.pathParameters['tradeId']!);
          return TradeDetailScreen(leagueId: leagueId, tradeId: tradeId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
