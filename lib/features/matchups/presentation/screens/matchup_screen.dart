import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/week_selector_strip.dart';
import '../../../leagues/domain/league.dart';
import '../../domain/matchup.dart';
import '../providers/matchup_provider.dart';

class MatchupScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const MatchupScreen({
    super.key,
    required this.leagueId,
  });

  @override
  ConsumerState<MatchupScreen> createState() => _MatchupScreenState();
}

class _MatchupScreenState extends ConsumerState<MatchupScreen> {
  Timer? _refreshTimer;
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    // Tick every 30s to update the "last updated" relative time text
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        matchupProvider(widget.leagueId),
        (prev, next) {
          if (next.isForbidden && prev?.isForbidden != true) {
            handleForbiddenNavigation(context, ref);
          }
        },
      ));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) sub.close();
    _subscriptions.clear();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchupProvider(widget.leagueId));

    if (state.isLoading && state.matchups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => navigateBack(context),
          ),
          title: const Text('Matchups'),
        ),
        body: const SkeletonMatchupList(itemCount: 4),
      );
    }

    if (state.error != null && state.matchups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => navigateBack(context),
          ),
          title: const Text('Matchups'),
        ),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(matchupProvider(widget.leagueId).notifier).loadData(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateBack(context),
        ),
        title: Text(state.league?.name ?? 'Matchups'),
      ),
      body: Column(
        children: [
          WeekSelectorStrip(
            currentWeek: state.currentWeek,
            totalWeeks: () {
              final maxWeek = state.maxScheduledWeek;
              return (maxWeek != null && maxWeek > 0)
                  ? maxWeek
                  : (state.league?.totalWeeks ?? 14);
            }(),
            onWeekSelected: (week) {
              ref.read(matchupProvider(widget.leagueId).notifier).changeWeek(week);
            },
          ),
          // Freshness indicator and context bar
          _FreshnessBar(state: state),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(matchupProvider(widget.leagueId).notifier).loadData(),
              child: Center(
                child: ConstrainedBox(
                  constraints: AppLayout.contentConstraints(context),
                  child: _buildMatchupsList(context, state),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchupsList(BuildContext context, MatchupState state) {
    // Filter other matchups (excluding user's matchup)
    final otherMatchups = state.weekMatchups.where((matchup) {
      final isMyMatchup = state.myRosterId != null &&
          (matchup.roster1Id == state.myRosterId ||
              matchup.roster2Id == state.myRosterId);
      return !isMyMatchup;
    }).toList();

    // Calculate item count:
    // - If has my matchup OR on BYE: header + spacing + card + spacing = 4 items
    // - All matchups header + spacing = 2 items
    // - Other matchups or empty view = otherMatchups.length or 1
    final hasMyMatchup = state.myMatchup != null;
    final isOnBye = state.isOnBye;
    final showMySection = hasMyMatchup || isOnBye;
    final myMatchupItems = showMySection ? 4 : 0;
    final headerItems = 2; // "All Matchups" header + spacing
    // Show empty view if no matchups at all OR if there are matchups but none are "other" matchups
    final showEmptyView = state.weekMatchups.isEmpty || otherMatchups.isEmpty;
    final matchupItems = showEmptyView ? 1 : otherMatchups.length;
    final itemCount = myMatchupItems + headerItems + matchupItems;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // My matchup section (or BYE week)
        if (showMySection) {
          if (index == 0) {
            return Text(
              isOnBye ? 'My Week' : 'My Matchup',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            );
          }
          if (index == 1) {
            return const SizedBox(height: 8);
          }
          if (index == 2) {
            // Show BYE card if user is on bye, otherwise show matchup card
            if (isOnBye) {
              return const _ByeWeekCard(key: ValueKey('bye-week-card'));
            }
            return _MatchupCard(
              key: ValueKey('matchup-card-featured-${state.myMatchup!.id}'),
              matchup: state.myMatchup!,
              myRosterId: state.myRosterId,
              isFeatured: true,
              onTap: () => _openMatchupDetails(context, state.myMatchup!),
            );
          }
          if (index == 3) {
            return const SizedBox(height: 24);
          }
        }

        // Adjust index for "All Matchups" section
        final adjustedIndex = index - myMatchupItems;

        // All matchups header
        if (adjustedIndex == 0) {
          return const Text(
            'All Matchups',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          );
        }
        if (adjustedIndex == 1) {
          return const SizedBox(height: 8);
        }

        // Empty state or matchup cards
        if (state.weekMatchups.isEmpty) {
          final seasonStatus = state.league?.seasonStatus;
          if (seasonStatus == SeasonStatus.offseason) {
            return const AppEmptyView(
              icon: Icons.beach_access,
              title: 'Offseason',
              subtitle: 'The season has ended. Check back when the new season begins!',
            );
          }
          if (seasonStatus == SeasonStatus.preSeason) {
            return const AppEmptyView(
              icon: Icons.calendar_today,
              title: 'Pre-Season',
              subtitle: 'The schedule hasn\'t been generated yet. Matchups will appear once the season starts.',
            );
          }
          return const AppEmptyView(
            icon: Icons.sports_football,
            title: 'No Matchups',
            subtitle: 'No matchups scheduled for this week.',
          );
        }

        // Show empty view when there are no other matchups (e.g., 2-team league)
        if (otherMatchups.isEmpty) {
          return const AppEmptyView(
            icon: Icons.sports_football,
            title: 'No Other Matchups',
            subtitle: 'No other matchups this week.',
          );
        }

        // Other matchup cards
        final matchupIndex = adjustedIndex - headerItems;
        final matchup = otherMatchups[matchupIndex];
        return Padding(
          key: ValueKey('matchup-${matchup.id}'),
          padding: const EdgeInsets.only(bottom: 8),
          child: _MatchupCard(
            key: ValueKey('matchup-card-${matchup.id}'),
            matchup: matchup,
            myRosterId: state.myRosterId,
            onTap: () => _openMatchupDetails(context, matchup),
          ),
        );
      },
    );
  }


  void _openMatchupDetails(BuildContext context, Matchup matchup) {
    context.push('/leagues/${widget.leagueId}/matchups/${matchup.id}');
  }
}

/// Bar showing freshness timestamp and playoff/season context.
class _FreshnessBar extends StatelessWidget {
  final MatchupState state;

  const _FreshnessBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lastUpdatedText = state.lastUpdatedDisplay;
    final isPlayoff = state.isPlayoffWeek;
    final seasonStatus = state.league?.seasonStatus;

    // Don't show bar if we have no data yet
    if (lastUpdatedText.isEmpty && !isPlayoff) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isPlayoff
          ? colorScheme.tertiary.withAlpha(15)
          : colorScheme.surfaceContainerHighest.withAlpha(80),
      child: Row(
        children: [
          // Playoff / season context label
          if (isPlayoff) ...[
            Icon(
              Icons.emoji_events,
              size: 14,
              color: colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'Playoffs',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.tertiary,
              ),
            ),
            // Note: median scoring does not apply to playoffs
            Text(
              ' - H2H only',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ] else if (seasonStatus == SeasonStatus.regularSeason) ...[
            Text(
              'Regular Season',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          // Last updated timestamp
          if (lastUpdatedText.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isStale)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: colorScheme.error,
                    ),
                  ),
                Text(
                  lastUpdatedText,
                  style: TextStyle(
                    fontSize: 11,
                    color: state.isStale
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MatchupCard extends StatelessWidget {
  final Matchup matchup;
  final int? myRosterId;
  final bool isFeatured;
  final VoidCallback? onTap;

  const _MatchupCard({
    super.key,
    required this.matchup,
    this.myRosterId,
    this.isFeatured = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMyTeam1 = myRosterId == matchup.roster1Id;
    final isMyTeam2 = myRosterId == matchup.roster2Id;
    final isTeam1Winner = matchup.isFinal && matchup.winnerId == matchup.roster1Id;
    final isTeam2Winner = matchup.isFinal && matchup.winnerId == matchup.roster2Id;

    // Use live scores for non-final matchups, otherwise use final scores
    final team1Points = matchup.isFinal
        ? matchup.roster1Points
        : (matchup.roster1PointsActual ?? matchup.roster1Points);
    final team2Points = matchup.isFinal
        ? matchup.roster2Points
        : (matchup.roster2PointsActual ?? matchup.roster2Points);

    final hasScores = team1Points != null || team2Points != null;
    final showProjections = !matchup.isFinal;

    return Card(
      elevation: isFeatured ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status row: badges above the scoreboard
              if (matchup.isFinal || matchup.hasLiveData || matchup.isPlayoff)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (matchup.isFinal)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.htColors.draftAction.withAlpha(30),
                            borderRadius: AppSpacing.badgeRadius,
                          ),
                          child: Text(
                            'FINAL',
                            style: TextStyle(
                              color: context.htColors.draftAction,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (matchup.hasLiveData)
                        const LiveBadge(),
                      if (matchup.isPlayoff) ...[
                        if (matchup.isFinal || matchup.hasLiveData)
                          const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary.withAlpha(30),
                            borderRadius: AppSpacing.badgeRadius,
                          ),
                          child: Text(
                            'PLAYOFF',
                            style: TextStyle(
                              color: colorScheme.tertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              // Main scoreboard row
              Row(
                children: [
                  // Team 1 (left-aligned)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isTeam1Winner)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: colorScheme.tertiary,
                                  size: 16,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                matchup.roster1TeamName ?? 'Team 1',
                                style: TextStyle(
                                  fontWeight: isMyTeam1 ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                  color: isMyTeam1 ? Theme.of(context).primaryColor : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        if (showProjections && matchup.roster1PointsProjected != null)
                          Padding(
                            padding: EdgeInsets.only(left: isTeam1Winner ? 20 : 0),
                            child: Text(
                              'Proj: ${matchup.roster1PointsProjected!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Center score area
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: hasScores
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  team1Points?.toStringAsFixed(1) ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isTeam1Winner
                                        ? context.htColors.draftAction
                                        : null,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '-',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text(
                                  team2Points?.toStringAsFixed(1) ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isTeam2Winner
                                        ? context.htColors.draftAction
                                        : null,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'vs',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  // Team 2 (right-aligned)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                matchup.roster2TeamName ?? 'Team 2',
                                style: TextStyle(
                                  fontWeight: isMyTeam2 ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                  color: isMyTeam2 ? Theme.of(context).primaryColor : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                textAlign: TextAlign.end,
                              ),
                            ),
                            if (isTeam2Winner)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.emoji_events,
                                  color: colorScheme.tertiary,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        if (showProjections && matchup.roster2PointsProjected != null)
                          Padding(
                            padding: EdgeInsets.only(right: isTeam2Winner ? 20 : 0),
                            child: Text(
                              'Proj: ${matchup.roster2PointsProjected!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ByeWeekCard extends StatelessWidget {
  const _ByeWeekCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.beach_access,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'BYE Week',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No matchup scheduled this week. Take a break!',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
