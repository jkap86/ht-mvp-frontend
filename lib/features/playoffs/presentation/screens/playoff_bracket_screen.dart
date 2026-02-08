import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../providers/playoff_bracket_provider.dart';
import '../widgets/bracket_visualization.dart';

class PlayoffBracketScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const PlayoffBracketScreen({super.key, required this.leagueId});

  @override
  ConsumerState<PlayoffBracketScreen> createState() => _PlayoffBracketScreenState();
}

class _PlayoffBracketScreenState extends ConsumerState<PlayoffBracketScreen> {
  ProviderSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // Schedule listener setup for after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscription = ref.listenManual(
        playoffBracketProvider(widget.leagueId),
        (prev, next) {
          if (next.successMessage != null && prev?.successMessage != next.successMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.successMessage!),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (next.error != null && prev?.error != next.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playoffBracketProvider(widget.leagueId));
    final leagueState = ref.watch(leagueDetailProvider(widget.leagueId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/leagues/${widget.leagueId}');
            }
          },
        ),
        title: const Text('Playoff Bracket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(playoffBracketProvider(widget.leagueId).notifier).loadBracket(),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingView()
          : Stack(
              children: [
                if (!state.hasPlayoffs)
                  _buildNoPlayoffsView(context, leagueState.isCommissioner)
                else
                  RefreshIndicator(
                    onRefresh: () => ref
                        .read(playoffBracketProvider(widget.leagueId).notifier)
                        .loadBracket(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bracket info card
                                if (state.bracketView?.bracket != null)
                                  _buildBracketInfoCard(context, state),
                                const SizedBox(height: 16),
                                // Bracket visualization
                                BracketVisualization(
                                  bracketView: state.bracketView!,
                                  userRosterId: leagueState.league?.userRosterId,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (state.isProcessing)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildNoPlayoffsView(BuildContext context, bool isCommissioner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Playoffs Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isCommissioner
                  ? 'Generate a playoff bracket from the Commissioner Tools.'
                  : 'The commissioner has not generated the playoff bracket yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (isCommissioner) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/leagues/${widget.leagueId}/commissioner'),
                icon: const Icon(Icons.settings),
                label: const Text('Commissioner Tools'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBracketInfoCard(BuildContext context, PlayoffBracketState state) {
    final bracket = state.bracketView!.bracket!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events),
                const SizedBox(width: 8),
                Text(
                  'Playoff Bracket',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _buildStatusChip(bracket.status),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Teams',
                    '${bracket.playoffTeams}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Rounds',
                    '${bracket.totalRounds}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    context,
                    'Weeks',
                    '${bracket.startWeek}-${bracket.championshipWeek}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(status) {
    Color color;
    String label;

    switch (status.toString()) {
      case 'PlayoffStatus.active':
        color = Colors.green;
        label = 'Active';
        break;
      case 'PlayoffStatus.completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }
}
