import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../../matchups/data/matchup_repository.dart';
import '../../../playoffs/data/playoff_repository.dart';
import '../../../playoffs/domain/playoff.dart';

/// Commissioner dashboard state
class CommissionerState {
  final League? league;
  final List<Map<String, dynamic>> members;
  final PlayoffBracketView? bracketView;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String? successMessage;

  CommissionerState({
    this.league,
    this.members = const [],
    this.bracketView,
    this.isLoading = true,
    this.isProcessing = false,
    this.error,
    this.successMessage,
  });

  bool get hasPlayoffs => bracketView?.hasPlayoffs ?? false;

  CommissionerState copyWith({
    League? league,
    List<Map<String, dynamic>>? members,
    PlayoffBracketView? bracketView,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearBracket = false,
  }) {
    return CommissionerState(
      league: league ?? this.league,
      members: members ?? this.members,
      bracketView: clearBracket ? null : (bracketView ?? this.bracketView),
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Commissioner dashboard notifier
class CommissionerNotifier extends StateNotifier<CommissionerState> {
  final LeagueRepository _leagueRepo;
  final MatchupRepository _matchupRepo;
  final PlayoffRepository _playoffRepo;
  final int leagueId;

  CommissionerNotifier(
    this._leagueRepo,
    this._matchupRepo,
    this._playoffRepo,
    this.leagueId,
  ) : super(CommissionerState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _leagueRepo.getLeague(leagueId),
        _leagueRepo.getMembers(leagueId),
        _playoffRepo.getBracket(leagueId),
      ]);

      state = state.copyWith(
        league: results[0] as League,
        members: results[1] as List<Map<String, dynamic>>,
        bracketView: results[2] as PlayoffBracketView?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> kickMember(int rosterId, String teamName) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _leagueRepo.kickMember(leagueId, rosterId);
      // Reload members
      final members = await _leagueRepo.getMembers(leagueId);
      state = state.copyWith(
        members: members,
        isProcessing: false,
        successMessage: '$teamName has been removed from the league',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> generateSchedule(int weeks) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _matchupRepo.generateSchedule(leagueId, weeks: weeks);
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Schedule generated for $weeks weeks',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> finalizeWeek(int week) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      await _matchupRepo.finalizeMatchups(leagueId, week);
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Week $week has been finalized',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> generatePlayoffBracket({
    required int playoffTeams,
    required int startWeek,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _playoffRepo.generateBracket(
        leagueId,
        playoffTeams: playoffTeams,
        startWeek: startWeek,
      );
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Playoff bracket generated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> advanceWinners(int week) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _playoffRepo.advanceWinners(leagueId, week);
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Winners advanced to next round',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

/// Provider for commissioner screen
final commissionerProvider = StateNotifierProvider.family<CommissionerNotifier, CommissionerState, int>(
  (ref, leagueId) => CommissionerNotifier(
    ref.watch(leagueRepositoryProvider),
    ref.watch(matchupRepositoryProvider),
    ref.watch(playoffRepositoryProvider),
    leagueId,
  ),
);

class CommissionerScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const CommissionerScreen({super.key, required this.leagueId});

  @override
  ConsumerState<CommissionerScreen> createState() => _CommissionerScreenState();
}

class _CommissionerScreenState extends ConsumerState<CommissionerScreen> {
  final _weeksController = TextEditingController(text: '14');
  int _selectedWeek = 1;
  int _playoffTeams = 6;
  int _playoffStartWeek = 15;

  @override
  void dispose() {
    _weeksController.dispose();
    super.dispose();
  }

  void _showKickConfirmation(int rosterId, String teamName, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick Member'),
        content: Text(
          'Are you sure you want to remove $teamName ($username) from the league?\n\n'
          'This will:\n'
          '• Release all their players\n'
          '• Cancel their pending trades\n'
          '• Cancel their waiver claims\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(commissionerProvider(widget.leagueId).notifier).kickMember(rosterId, teamName);
            },
            child: const Text('Kick Member'),
          ),
        ],
      ),
    );
  }

  void _showGenerateScheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Schedule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will create a new round-robin schedule. Any existing schedule will be replaced.'),
            const SizedBox(height: 16),
            TextField(
              controller: _weeksController,
              decoration: const InputDecoration(
                labelText: 'Number of weeks',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final weeks = int.tryParse(_weeksController.text) ?? 14;
              ref.read(commissionerProvider(widget.leagueId).notifier).generateSchedule(weeks);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showFinalizeWeekDialog(int currentWeek) {
    setState(() => _selectedWeek = currentWeek);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Finalize Week'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will lock in all scores for the selected week and update standings.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedWeek,
                decoration: const InputDecoration(
                  labelText: 'Week',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(18, (i) => i + 1)
                    .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _selectedWeek = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(commissionerProvider(widget.leagueId).notifier).finalizeWeek(_selectedWeek);
              },
              child: const Text('Finalize'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneratePlayoffBracketDialog(int currentWeek) {
    setState(() {
      _playoffTeams = 6;
      _playoffStartWeek = currentWeek + 1;
    });
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Playoff Bracket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create a playoff bracket based on current standings.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _playoffTeams,
                decoration: const InputDecoration(
                  labelText: 'Playoff Teams',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 teams (2 rounds)')),
                  DropdownMenuItem(value: 6, child: Text('6 teams (3 rounds, top 2 get bye)')),
                  DropdownMenuItem(value: 8, child: Text('8 teams (3 rounds)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _playoffTeams = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _playoffStartWeek,
                decoration: const InputDecoration(
                  labelText: 'Start Week',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(18, (i) => i + 1)
                    .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _playoffStartWeek = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(commissionerProvider(widget.leagueId).notifier).generatePlayoffBracket(
                  playoffTeams: _playoffTeams,
                  startWeek: _playoffStartWeek,
                );
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdvanceWinnersDialog(int currentWeek) {
    setState(() => _selectedWeek = currentWeek);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Advance Winners'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Advance playoff winners from the selected week to the next round.'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedWeek,
                decoration: const InputDecoration(
                  labelText: 'Week',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(18, (i) => i + 1)
                    .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => _selectedWeek = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(commissionerProvider(widget.leagueId).notifier).advanceWinners(_selectedWeek);
              },
              child: const Text('Advance'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commissionerProvider(widget.leagueId));

    // Show snackbar for success/error messages
    ref.listen(commissionerProvider(widget.leagueId), (prev, next) {
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
    });

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
        title: const Text('Commissioner Tools'),
      ),
      body: state.isLoading
          ? const AppLoadingView()
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.read(commissionerProvider(widget.leagueId).notifier).loadData(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // League Status Card
                      _buildLeagueStatusCard(state),
                      const SizedBox(height: 16),

                      // Member Management Card
                      _buildMemberManagementCard(state),
                      const SizedBox(height: 16),

                      // Schedule Management Card
                      _buildScheduleManagementCard(state),
                      const SizedBox(height: 16),

                      // Scoring Card
                      _buildScoringCard(state),
                      const SizedBox(height: 16),

                      // Playoff Management Card
                      _buildPlayoffManagementCard(state),
                    ],
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

  Widget _buildLeagueStatusCard(CommissionerState state) {
    final league = state.league;
    if (league == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Text(
                  'League Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Season', league.season.toString()),
            _buildInfoRow('Current Week', league.currentWeek.toString()),
            _buildInfoRow('Status', league.status.toUpperCase()),
            _buildInfoRow('Members', '${state.members.length}/${league.totalRosters}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMemberManagementCard(CommissionerState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Text(
                  'Member Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (state.members.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No members found'),
              )
            else
              ...state.members.map((member) {
                final rosterId = member['roster_id'] as int?;
                final memberId = member['id'] as int?;
                final isCommissioner = rosterId != null && rosterId == state.league?.commissionerRosterId;
                final teamName = (member['team_name'] as String?) ?? 'Team $rosterId';
                final username = (member['username'] as String?) ?? 'Unknown';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isCommissioner
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.grey.shade200,
                    child: Icon(
                      isCommissioner ? Icons.star : Icons.person,
                      color: isCommissioner
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(teamName),
                  subtitle: Text(username),
                  trailing: isCommissioner
                      ? Chip(
                          label: const Text('Commissioner'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : memberId != null
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _showKickConfirmation(
                                memberId,
                                teamName,
                                username,
                              ),
                              tooltip: 'Kick member',
                            )
                          : null,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleManagementCard(CommissionerState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month),
                const SizedBox(width: 8),
                Text(
                  'Schedule Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showGenerateScheduleDialog,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Generate Schedule'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creates a round-robin schedule for all teams. Existing schedule will be replaced.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringCard(CommissionerState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.scoreboard),
                const SizedBox(width: 8),
                Text(
                  'Scoring',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showFinalizeWeekDialog(state.league?.currentWeek ?? 1),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Finalize Week'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lock in scores and update standings for a completed week.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayoffManagementCard(CommissionerState state) {
    final hasPlayoffs = state.hasPlayoffs;
    final bracket = state.bracketView?.bracket;
    final isCompleted = bracket?.status == PlayoffStatus.completed;

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
                  'Playoff Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasPlayoffs) ...[
                  const Spacer(),
                  _buildPlayoffStatusChip(bracket!.status),
                ],
              ],
            ),
            const Divider(),
            if (hasPlayoffs) ...[
              // Show bracket info
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPlayoffInfoItem(
                        'Teams',
                        '${bracket!.playoffTeams}',
                      ),
                    ),
                    Expanded(
                      child: _buildPlayoffInfoItem(
                        'Rounds',
                        '${bracket.totalRounds}',
                      ),
                    ),
                    Expanded(
                      child: _buildPlayoffInfoItem(
                        'Weeks',
                        '${bracket.startWeek}-${bracket.championshipWeek}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // View bracket button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/leagues/${widget.leagueId}/playoffs'),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Bracket'),
                ),
              ),
              if (!isCompleted) ...[
                const SizedBox(height: 8),
                // Advance winners button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAdvanceWinnersDialog(state.league?.currentWeek ?? 1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Advance Winners'),
                  ),
                ),
                const SizedBox(height: 8),
                // Regenerate bracket button
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () => _showGeneratePlayoffBracketDialog(state.league?.currentWeek ?? 14),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate Bracket'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                isCompleted
                    ? 'Playoffs are complete!'
                    : 'Advance winners after finalizing each playoff week.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showGeneratePlayoffBracketDialog(state.league?.currentWeek ?? 14),
                  icon: const Icon(Icons.add),
                  label: const Text('Generate Playoff Bracket'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a playoff bracket based on current standings. Top seeds are determined by win-loss record.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayoffStatusChip(PlayoffStatus status) {
    Color color;
    String label;

    switch (status) {
      case PlayoffStatus.active:
        color = Colors.green;
        label = 'Active';
        break;
      case PlayoffStatus.completed:
        color = Colors.blue;
        label = 'Completed';
        break;
      case PlayoffStatus.pending:
        color = Colors.orange;
        label = 'Pending';
        break;
    }

    return Chip(
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPlayoffInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
