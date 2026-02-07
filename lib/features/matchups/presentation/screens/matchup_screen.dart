import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
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
    final state = ref.watch(matchupProvider(leagueId));

    if (state.isLoading && state.matchups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
          ),
          title: const Text('Matchups'),
        ),
        body: const AppLoadingView(),
      );
    }

    if (state.error != null && state.matchups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(context),
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
          onPressed: () => _navigateBack(context),
        ),
        title: Text(state.league?.name ?? 'Matchups'),
        actions: [
          PopupMenuButton<int>(
            initialValue: state.currentWeek,
            onSelected: (week) {
              ref.read(matchupProvider(leagueId).notifier).changeWeek(week);
            },
            itemBuilder: (context) {
              // Use maxScheduledWeek if available, otherwise fall back to totalWeeks
              final totalWeeks = state.maxScheduledWeek ?? state.league?.totalWeeks ?? 14;
              return List.generate(
                totalWeeks,
                (index) => PopupMenuItem(
                  value: index + 1,
                  child: Text('Week ${index + 1}'),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Week ${state.currentWeek}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchupProvider(leagueId).notifier).loadData(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _buildMatchupsList(context, state),
          ),
        ),
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
    final matchupItems = state.weekMatchups.isEmpty ? 1 : otherMatchups.length;
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
          return const AppEmptyView(
            icon: Icons.sports_football,
            title: 'No Matchups',
            subtitle: 'No matchups scheduled for this week.',
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

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // At root of Matchups tab, go to home
      context.go('/');
    }
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
    final isMyTeam1 = myRosterId == matchup.roster1Id;
    final isMyTeam2 = myRosterId == matchup.roster2Id;

    return Card(
      elevation: isFeatured ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Team 1
              _TeamRow(
                teamName: matchup.roster1TeamName ?? 'Team 1',
                points: matchup.roster1Points,
                isWinner: matchup.isFinal && matchup.winnerId == matchup.roster1Id,
                isMyTeam: isMyTeam1,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'vs',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Team 2
              _TeamRow(
                teamName: matchup.roster2TeamName ?? 'Team 2',
                points: matchup.roster2Points,
                isWinner: matchup.isFinal && matchup.winnerId == matchup.roster2Id,
                isMyTeam: isMyTeam2,
              ),
              if (matchup.isFinal) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Final',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              if (matchup.isPlayoff && !matchup.isFinal) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Playoff',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
  final bool isWinner;
  final bool isMyTeam;

  const _TeamRow({
    required this.teamName,
    this.points,
    this.isWinner = false,
    this.isMyTeam = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (isWinner)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.emoji_events, color: Colors.amber, size: 20),
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
        Text(
          points?.toStringAsFixed(2) ?? '-',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isWinner ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}

class _ByeWeekCard extends StatelessWidget {
  const _ByeWeekCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.beach_access,
              size: 48,
              color: Colors.blue.shade300,
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
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
