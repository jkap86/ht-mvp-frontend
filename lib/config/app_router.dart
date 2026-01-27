import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/leagues/presentation/leagues_screen.dart';
import '../features/leagues/presentation/league_detail_screen.dart';
import '../features/leagues/presentation/public_leagues_screen.dart';
import '../features/drafts/presentation/draft_room_screen.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/rosters/presentation/screens/team_screen.dart';
import '../features/rosters/presentation/screens/free_agents_screen.dart';
import '../features/rosters/presentation/screens/lineup_screen.dart';
import '../features/matchups/presentation/screens/matchup_screen.dart';
import '../features/matchups/presentation/screens/matchup_detail_screen.dart';
import '../features/matchups/presentation/screens/standings_screen.dart';
import '../features/trades/presentation/screens/trades_list_screen.dart';
import '../features/trades/presentation/screens/trade_detail_screen.dart';
import '../features/trades/presentation/screens/propose_trade_screen.dart';
import '../features/trades/presentation/screens/counter_trade_screen.dart';
import '../features/commissioner/presentation/screens/commissioner_screen.dart';
import '../features/playoffs/presentation/screens/playoff_bracket_screen.dart';

// Listenable that notifies when auth state changes
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final _authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier(ref);
});

/// Parse an integer from route parameters, returning null if invalid or <= 0
int? _parseIntParam(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

/// Safely extract int from extra, returning default if not an int
int _extractIntExtra(Object? extra, [int defaultValue = 0]) {
  if (extra is int) return extra;
  return defaultValue;
}

/// Redirect to error page if required path parameters are invalid
String? _validateParams(Map<String, String> pathParams, List<String> required) {
  for (final param in required) {
    final value = _parseIntParam(pathParams[param]);
    if (value == null) {
      final paramName = param.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => ' ${m.group(1)!.toLowerCase()}',
      ).replaceAll('Id', 'ID').trim();
      return '/error?message=Invalid $paramName';
    }
  }
  return null;
}

/// Simple error screen widget for invalid routes
class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

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
        path: '/error',
        builder: (context, state) {
          final message = state.uri.queryParameters['message'] ?? 'Page not found';
          return _ErrorScreen(message: message);
        },
      ),
      GoRoute(
        path: '/leagues',
        builder: (context, state) => const LeaguesScreen(),
      ),
      GoRoute(
        path: '/leagues/discover',
        builder: (context, state) => const PublicLeaguesScreen(),
      ),
      GoRoute(
        path: '/leagues/:leagueId',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return LeagueDetailScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/commissioner',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return CommissionerScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/playoffs',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return PlayoffBracketScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/drafts/:draftId',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'draftId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final draftId = _parseIntParam(state.pathParameters['draftId'])!;
          return DraftRoomScreen(leagueId: leagueId, draftId: draftId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/team/:rosterId',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'rosterId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final rosterId = _parseIntParam(state.pathParameters['rosterId'])!;
          return TeamScreen(leagueId: leagueId, rosterId: rosterId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/team/:rosterId/lineup',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'rosterId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final rosterId = _parseIntParam(state.pathParameters['rosterId'])!;
          return LineupScreen(leagueId: leagueId, rosterId: rosterId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/free-agents',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final rosterId = _extractIntExtra(state.extra);
          return FreeAgentsScreen(leagueId: leagueId, rosterId: rosterId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/matchups',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return MatchupScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/matchups/:matchupId',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'matchupId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final matchupId = _parseIntParam(state.pathParameters['matchupId'])!;
          return MatchupDetailScreen(leagueId: leagueId, matchupId: matchupId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/standings',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return StandingsScreen(leagueId: leagueId);
        },
      ),
      // Trades routes
      GoRoute(
        path: '/leagues/:leagueId/trades',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return TradesListScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/trades/propose',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          return ProposeTradeScreen(leagueId: leagueId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/trades/:tradeId',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'tradeId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final tradeId = _parseIntParam(state.pathParameters['tradeId'])!;
          return TradeDetailScreen(leagueId: leagueId, tradeId: tradeId);
        },
      ),
      GoRoute(
        path: '/leagues/:leagueId/trades/:tradeId/counter',
        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'tradeId']),
        builder: (context, state) {
          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
          final tradeId = _parseIntParam(state.pathParameters['tradeId'])!;
          return CounterTradeScreen(
            leagueId: leagueId,
            originalTradeId: tradeId,
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      // Use our custom error screen for unmatched routes too
      return _ErrorScreen(message: 'Page not found: ${state.uri.path}');
    },
  );
});
