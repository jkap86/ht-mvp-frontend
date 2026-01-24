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
          // Week selector
          PopupMenuButton<int>(
            initialValue: state.currentWeek,
            onSelected: (week) {
              ref.read(matchupProvider(leagueId).notifier).changeWeek(week);
            },
            itemBuilder: (context) {
              return List.generate(
                18,
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // My matchup (featured)
            if (state.myMatchup != null) ...[
              const Text(
                'My Matchup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _MatchupCard(
                matchup: state.myMatchup!,
                myRosterId: state.myRosterId,
                isFeatured: true,
                onTap: () => _openMatchupDetails(context, state.myMatchup!),
              ),
              const SizedBox(height: 24),
            ],

            // All matchups
            const Text(
              'All Matchups',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...state.weekMatchups.map((matchup) {
              final isMyMatchup = state.myRosterId != null &&
                  (matchup.roster1Id == state.myRosterId ||
                      matchup.roster2Id == state.myRosterId);
              if (isMyMatchup) return const SizedBox.shrink(); // Already shown above
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MatchupCard(
                  matchup: matchup,
                  myRosterId: state.myRosterId,
                  onTap: () => _openMatchupDetails(context, matchup),
                ),
              );
            }),

            if (state.weekMatchups.isEmpty)
              const AppEmptyView(
                icon: Icons.sports_football,
                title: 'No Matchups',
                subtitle: 'No matchups scheduled for this week.',
              ),
          ],
        ),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/leagues/$leagueId');
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
