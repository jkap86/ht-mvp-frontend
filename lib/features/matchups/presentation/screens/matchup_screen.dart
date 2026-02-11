import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../../../../core/widgets/week_selector_strip.dart';
import '../../../leagues/domain/league.dart';
import '../../domain/matchup.dart';
import '../providers/matchup_provider.dart';

class MatchupScreen extends ConsumerWidget {
  final int leagueId;

  const MatchupScreen({
    super.key,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(matchupProvider(leagueId), (prev, next) {
      if (next.isForbidden && prev?.isForbidden != true) {
        handleForbiddenNavigation(context, ref);
      }
    });

    final state = ref.watch(matchupProvider(leagueId));

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
          onRetry: () => ref.read(matchupProvider(leagueId).notifier).loadData(),
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
              ref.read(matchupProvider(leagueId).notifier).changeWeek(week);
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(matchupProvider(leagueId).notifier).loadData(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
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
              return const _ByeWeekCard();
            }
            return _MatchupCard(
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
          padding: const EdgeInsets.only(bottom: 8),
          child: _MatchupCard(
            matchup: matchup,
            myRosterId: state.myRosterId,
            onTap: () => _openMatchupDetails(context, matchup),
          ),
        );
      },
    );
  }


  void _openMatchupDetails(BuildContext context, Matchup matchup) {
    context.push('/leagues/$leagueId/matchups/${matchup.id}');
  }
}

class _MatchupCard extends StatelessWidget {
  final Matchup matchup;
  final int? myRosterId;
  final bool isFeatured;
  final VoidCallback? onTap;

  const _MatchupCard({
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

    // Use live scores for non-final matchups, otherwise use final scores
    final team1Points = matchup.isFinal
        ? matchup.roster1Points
        : (matchup.roster1PointsActual ?? matchup.roster1Points);
    final team2Points = matchup.isFinal
        ? matchup.roster2Points
        : (matchup.roster2PointsActual ?? matchup.roster2Points);

    return Card(
      elevation: isFeatured ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.buttonRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Team 1
              _TeamRow(
                teamName: matchup.roster1TeamName ?? 'Team 1',
                points: team1Points,
                projectedPoints: matchup.isFinal ? null : matchup.roster1PointsProjected,
                isWinner: matchup.isFinal && matchup.winnerId == matchup.roster1Id,
                isMyTeam: isMyTeam1,
                showProjection: !matchup.isFinal,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'vs',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Team 2
              _TeamRow(
                teamName: matchup.roster2TeamName ?? 'Team 2',
                points: team2Points,
                projectedPoints: matchup.isFinal ? null : matchup.roster2PointsProjected,
                isWinner: matchup.isFinal && matchup.winnerId == matchup.roster2Id,
                isMyTeam: isMyTeam2,
                showProjection: !matchup.isFinal,
              ),
              // Status badges
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (matchup.isFinal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.draftActionPrimary.withAlpha(30),
                        borderRadius: AppSpacing.badgeRadius,
                      ),
                      child: Text(
                        'Final',
                        style: TextStyle(
                          color: AppTheme.draftActionPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (matchup.hasLiveData)
                    const LiveBadge(),
                  if (matchup.isPlayoff && !matchup.isFinal) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiary.withAlpha(30),
                        borderRadius: AppSpacing.badgeRadius,
                      ),
                      child: Text(
                        'Playoff',
                        style: TextStyle(
                          color: colorScheme.tertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String teamName;
  final double? points;
  final double? projectedPoints;
  final bool isWinner;
  final bool isMyTeam;
  final bool showProjection;

  const _TeamRow({
    required this.teamName,
    this.points,
    this.projectedPoints,
    this.isWinner = false,
    this.isMyTeam = false,
    this.showProjection = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (isWinner)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 20),
                ),
              Expanded(
                child: Text(
                  teamName,
                  style: TextStyle(
                    fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                    color: isMyTeam ? Theme.of(context).primaryColor : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Actual points (prominent)
            Text(
              points?.toStringAsFixed(2) ?? '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isWinner ? AppTheme.draftActionPrimary : null,
              ),
            ),
            // Projected points (smaller, secondary)
            if (showProjection && projectedPoints != null)
              Text(
                'Proj: ${projectedPoints!.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ByeWeekCard extends StatelessWidget {
  const _ByeWeekCard();

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
