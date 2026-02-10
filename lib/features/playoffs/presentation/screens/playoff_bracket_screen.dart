import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
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
                backgroundColor: AppTheme.draftSuccess,
              ),
            );
          }
          if (next.error != null && prev?.error != next.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                backgroundColor: Theme.of(context).colorScheme.error,
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
                    color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.26),
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    final settings = state.bracketView!.settings;
    final hasThirdPlaceGame = settings?.enableThirdPlaceGame ?? false;
    final hasConsolation = state.bracketView!.hasConsolation;
    final consolationTeams = settings?.consolationTeams;

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
            // Show enabled features as chips
            if (hasThirdPlaceGame || hasConsolation) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasThirdPlaceGame)
                    Chip(
                      avatar: Icon(Icons.looks_3, size: 18, color: Theme.of(context).colorScheme.tertiary),
                      label: const Text('3rd Place Game'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  if (hasConsolation)
                    Chip(
                      avatar: Icon(Icons.sports_handball, size: 18, color: Theme.of(context).colorScheme.tertiary),
                      label: Text(consolationTeams != null
                          ? 'Consolation ($consolationTeams teams)'
                          : 'Consolation'),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(status) {
    Color color;
    String label;
    final colorScheme = Theme.of(context).colorScheme;

    switch (status.toString()) {
      case 'PlayoffStatus.active':
        color = AppTheme.draftSuccess;
        label = 'Active';
        break;
      case 'PlayoffStatus.completed':
        color = colorScheme.primary;
        label = 'Completed';
        break;
      default:
        color = colorScheme.tertiary;
        label = 'Pending';
    }

    final isActive = status.toString() == 'PlayoffStatus.active';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.error.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        Chip(
          label: Text(label),
          backgroundColor: color.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
