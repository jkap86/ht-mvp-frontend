import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/leagues/presentation/leagues_screen.dart';
import '../features/leagues/presentation/league_detail_screen.dart';
import '../features/leagues/presentation/public_leagues_screen.dart';
import '../features/leagues/presentation/add_league_screen.dart';
import '../features/leagues/presentation/screens/league_shell_screen.dart';
import '../features/drafts/presentation/draft_room_screen.dart';
import '../features/drafts/presentation/drafts_list_screen.dart';
import '../features/auth/presentation/auth_provider.dart';
import '../features/rosters/presentation/screens/team_screen.dart';
import '../features/rosters/presentation/screens/free_agents_screen.dart';
import '../features/matchups/presentation/screens/matchup_screen.dart';
import '../features/matchups/presentation/screens/matchup_detail_screen.dart';
import '../features/matchups/presentation/screens/standings_screen.dart';
import '../features/trades/presentation/screens/trades_list_screen.dart';
import '../features/trades/presentation/screens/trade_detail_screen.dart';
import '../features/trades/presentation/screens/propose_trade_screen.dart';
import '../features/trades/presentation/screens/counter_trade_screen.dart';
import '../features/commissioner/presentation/screens/commissioner_screen.dart';
import '../features/commissioner/presentation/screens/season_summary_screen.dart';
import '../features/playoffs/presentation/screens/playoff_bracket_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/transactions/presentation/transactions_screen.dart';
import '../features/dm/presentation/dm_inbox_screen.dart';
import '../features/dm/presentation/dm_conversation_screen.dart';
import '../core/providers/league_context_provider.dart';

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

/// Slide-from-right transition for push navigation (detail screens).
Page<T> _slideTransition<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// Slide-from-bottom transition for modal-style routes.
Page<T> _modalTransition<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(0, 1), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// Fade transition for top-level tab-like navigation.
Page<T> _fadeTransition<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
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

/// Widget that redirects to the user's team after fetching league context
class _LeagueTeamRedirect extends ConsumerWidget {
  final int leagueId;

  const _LeagueTeamRedirect({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Don't redirect if we're already navigating to a specific team
    final currentPath = GoRouterState.of(context).uri.path;
    if (RegExp(r'/leagues/\d+/team/\d+').hasMatch(currentPath)) {
      // Already on a specific team route - just show loading while the real route renders
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final contextAsync = ref.watch(leagueContextProvider(leagueId));

    return contextAsync.when(
      data: (leagueContext) {
        final rosterId = leagueContext.userRosterId;
        if (rosterId != null) {
          // Redirect to the user's team
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/leagues/$leagueId/team/$rosterId');
          });
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorScreen(message: 'Failed to load team: $error'),
    );
  }
}

/// Widget that redirects to players screen with user's roster ID
class _LeaguePlayersRedirect extends ConsumerWidget {
  final int leagueId;

  const _LeaguePlayersRedirect({required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(leagueContextProvider(leagueId));

    return contextAsync.when(
      data: (leagueContext) {
        final rosterId = leagueContext.userRosterId;
        if (rosterId != null) {
          return FreeAgentsScreen(leagueId: leagueId, rosterId: rosterId);
        }
        return const _ErrorScreen(message: 'No roster found');
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _ErrorScreen(message: 'Failed to load players: $error'),
    );
  }
}

/// Provider that tracks the current leagueId from the route.
/// Returns null when not in a league context.
final currentLeagueIdProvider = StateProvider<int?>((ref) => null);

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

      // Update current league ID based on route
      final leagueMatch = RegExp(r'/leagues/(\d+)').firstMatch(state.matchedLocation);
      final leagueId = leagueMatch != null ? int.tryParse(leagueMatch.group(1) ?? '') : null;
      Future.microtask(() {
        ref.read(currentLeagueIdProvider.notifier).state = leagueId;
      });

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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeTransition(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) {
          final message = state.uri.queryParameters['message'] ?? 'Page not found';
          return _ErrorScreen(message: message);
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _slideTransition(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/transactions',
        pageBuilder: (context, state) => _slideTransition(state, const TransactionsScreen()),
      ),
      GoRoute(
        path: '/drafts',
        pageBuilder: (context, state) => _fadeTransition(state, const DraftsListScreen()),
      ),
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) => _fadeTransition(state, const DmInboxScreen()),
      ),
      GoRoute(
        path: '/messages/:conversationId',
        redirect: (context, state) => _validateParams(state.pathParameters, ['conversationId']),
        pageBuilder: (context, state) {
          final conversationId = _parseIntParam(state.pathParameters['conversationId'])!;
          return _slideTransition(state, DmConversationScreen(conversationId: conversationId));
        },
      ),
      GoRoute(
        path: '/leagues',
        pageBuilder: (context, state) => _fadeTransition(state, const LeaguesScreen()),
      ),
      GoRoute(
        path: '/leagues/add',
        pageBuilder: (context, state) => _modalTransition(state, const AddLeagueScreen()),
      ),
      GoRoute(
        path: '/leagues/discover',
        pageBuilder: (context, state) => _slideTransition(state, const PublicLeaguesScreen()),
      ),
      // League shell with bottom navigation - parent route captures :leagueId
      GoRoute(
        path: '/leagues/:leagueId',
        redirect: (context, state) {
          // Validate leagueId parameter
          final error = _validateParams(state.pathParameters, ['leagueId']);
          if (error != null) return error;
          // Redirect bare /leagues/:leagueId to the overview tab
          final leagueId = state.pathParameters['leagueId'];
          if (state.uri.path == '/leagues/$leagueId') {
            return '/leagues/$leagueId/overview';
          }
          return null;
        },
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId']);
              if (leagueId == null) {
                return const _ErrorScreen(message: 'Invalid league ID');
              }
              return LeagueShellScreen(
                leagueId: leagueId,
                navigationShell: navigationShell,
              );
            },
            branches: [
              // Team tab (index 0)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'team',
                    builder: (context, state) {
                      final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                      // Get rosterId from query params or context
                      final rosterIdParam = state.uri.queryParameters['rosterId'];
                      final rosterId = _parseIntParam(rosterIdParam);
                      if (rosterId != null) {
                        return TeamScreen(leagueId: leagueId, rosterId: rosterId);
                      }
                      // Show loading and fetch user's roster
                      return _LeagueTeamRedirect(leagueId: leagueId);
                    },
                    routes: [
                      GoRoute(
                        path: ':rosterId',
                        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'rosterId']),
                        pageBuilder: (context, state) {
                          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                          final rosterId = _parseIntParam(state.pathParameters['rosterId'])!;
                          return _slideTransition(
                            state,
                            TeamScreen(
                              key: ValueKey('team-$leagueId-$rosterId'),
                              leagueId: leagueId,
                              rosterId: rosterId,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Matchups tab (index 1)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'matchups',
                    builder: (context, state) {
                      final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                      return MatchupScreen(leagueId: leagueId);
                    },
                    routes: [
                      GoRoute(
                        path: ':matchupId',
                        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'matchupId']),
                        pageBuilder: (context, state) {
                          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                          final matchupId = _parseIntParam(state.pathParameters['matchupId'])!;
                          return _slideTransition(state, MatchupDetailScreen(leagueId: leagueId, matchupId: matchupId));
                        },
                      ),
                    ],
                  ),
                ],
              ),
              // Trades tab (index 2)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'trades',
                    builder: (context, state) {
                      final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                      return TradesListScreen(leagueId: leagueId);
                    },
                    routes: [
                      GoRoute(
                        path: 'propose',
                        pageBuilder: (context, state) {
                          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                          return _modalTransition(state, ProposeTradeScreen(leagueId: leagueId));
                        },
                      ),
                      GoRoute(
                        path: ':tradeId',
                        redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'tradeId']),
                        pageBuilder: (context, state) {
                          final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                          final tradeId = _parseIntParam(state.pathParameters['tradeId'])!;
                          return _slideTransition(state, TradeDetailScreen(leagueId: leagueId, tradeId: tradeId));
                        },
                        routes: [
                          GoRoute(
                            path: 'counter',
                            redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'tradeId']),
                            pageBuilder: (context, state) {
                              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                              final tradeId = _parseIntParam(state.pathParameters['tradeId'])!;
                              return _modalTransition(
                                state,
                                CounterTradeScreen(
                                  leagueId: leagueId,
                                  originalTradeId: tradeId,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Players tab (index 3)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'players',
                    builder: (context, state) {
                      final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                      // Get rosterId from query params or redirect to fetch it
                      final rosterIdParam = state.uri.queryParameters['rosterId'];
                      final rosterId = _parseIntParam(rosterIdParam);
                      if (rosterId != null) {
                        return FreeAgentsScreen(leagueId: leagueId, rosterId: rosterId);
                      }
                      // Use redirect to fetch user's roster
                      return _LeaguePlayersRedirect(leagueId: leagueId);
                    },
                  ),
                ],
              ),
              // League/Overview tab (index 4)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: 'overview',
                    builder: (context, state) {
                      final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
                      return LeagueDetailScreen(leagueId: leagueId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Sub-routes at same level as shell (NOT under overview)
          // These preserve existing navigation paths like /leagues/:leagueId/commissioner
          GoRoute(
            path: 'commissioner',
            pageBuilder: (context, state) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
              return _slideTransition(state, CommissionerScreen(leagueId: leagueId));
            },
          ),
          GoRoute(
            path: 'playoffs',
            pageBuilder: (context, state) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
              return _slideTransition(state, PlayoffBracketScreen(leagueId: leagueId));
            },
          ),
          GoRoute(
            path: 'standings',
            pageBuilder: (context, state) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
              return _slideTransition(state, StandingsScreen(leagueId: leagueId));
            },
          ),
          GoRoute(
            path: 'season-summary',
            pageBuilder: (context, state) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
              return _slideTransition(state, SeasonSummaryScreen(leagueId: leagueId));
            },
          ),
          GoRoute(
            path: 'free-agents',
            pageBuilder: (context, state) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
              final rosterId = _extractIntExtra(state.extra);
              return _slideTransition(state, FreeAgentsScreen(leagueId: leagueId, rosterId: rosterId));
            },
          ),
          GoRoute(
            path: 'drafts/:draftId',
            redirect: (context, state) => _validateParams(state.pathParameters, ['leagueId', 'draftId']),
            pageBuilder: (context, state) {
              final leagueId = _parseIntParam(state.pathParameters['leagueId'])!;
              final draftId = _parseIntParam(state.pathParameters['draftId'])!;
              return _slideTransition(state, DraftRoomScreen(leagueId: leagueId, draftId: draftId));
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      // Use our custom error screen for unmatched routes too
      return _ErrorScreen(message: 'Page not found: ${state.uri.path}');
    },
  );
});
