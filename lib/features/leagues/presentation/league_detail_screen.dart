import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/dev_console.dart';
import '../../../core/widgets/states/states.dart';
import '../domain/league.dart';
import '../../chat/presentation/floating_chat_widget.dart';
import '../../drafts/domain/draft_type.dart';
import 'providers/league_detail_provider.dart';
import 'widgets/league_header_widget.dart';
import 'widgets/draft_status_banner.dart';
import 'widgets/league_settings_summary.dart';
import 'widgets/league_members_section.dart';
import 'widgets/league_drafts_tab.dart';
import 'widgets/create_draft_dialog.dart';

class LeagueDetailScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const LeagueDetailScreen({super.key, required this.leagueId});

  @override
  ConsumerState<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends ConsumerState<LeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateRosterSlots(League league) {
    final rosterConfig = league.settings['roster_config'];
    if (rosterConfig is Map) {
      return ((rosterConfig['QB'] as int?) ?? 0) +
          ((rosterConfig['RB'] as int?) ?? 0) +
          ((rosterConfig['WR'] as int?) ?? 0) +
          ((rosterConfig['TE'] as int?) ?? 0) +
          ((rosterConfig['FLEX'] as int?) ?? 0) +
          ((rosterConfig['K'] as int?) ?? 0) +
          ((rosterConfig['DEF'] as int?) ?? 0) +
          ((rosterConfig['BN'] as int?) ?? 0);
    }
    return 15; // fallback
  }

  void _createDraft() {
    final league = ref.read(leagueDetailProvider(widget.leagueId)).league;
    if (league == null) return;

    showCreateDraftDialog(
      context,
      leagueMode: league.mode,
      rosterSlotsCount: _calculateRosterSlots(league),
      rookieDraftRounds: league.settings['rookie_draft_rounds'] as int?,
      onCreateDraft: ({
        required DraftType draftType,
        required int rounds,
        required int pickTimeSeconds,
        Map<String, dynamic>? auctionSettings,
      }) async {
        final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
        final success = await notifier.createDraft(
          draftType: draftType.value,
          rounds: rounds,
          pickTimeSeconds: pickTimeSeconds,
          settings: auctionSettings,
        );
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error creating draft')),
          );
        }
      },
    );
  }

  Future<void> _startDraft(Draft draft) async {
    final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
    final success = await notifier.startDraft(draft.id);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting draft')),
      );
    }
  }

  Future<void> _randomizeDraftOrder(Draft draft) async {
    final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
    final success = await notifier.randomizeDraftOrder(draft.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Draft order randomized successfully'
              : 'Error randomizing draft order'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leagueDetailProvider(widget.leagueId));

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Loading...'),
        ),
        body: const AppLoadingView(),
      );
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: const Text('Error'),
        ),
        body: AppErrorView(
          message: state.error!,
          onRetry: () => ref.read(leagueDetailProvider(widget.leagueId).notifier).loadData(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
        ),
        title: Text(state.league?.name ?? 'League'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Season'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(state),
              _buildSeasonTab(state),
              LeagueDraftsTab(
                leagueId: widget.leagueId,
                drafts: state.drafts,
                isCommissioner: state.isCommissioner,
                onCreateDraft: _createDraft,
                onStartDraft: _startDraft,
                onRandomizeDraftOrder: _randomizeDraftOrder,
              ),
            ],
          ),
          FloatingChatWidget(leagueId: widget.leagueId),
          if (!kReleaseMode) DevConsole(leagueId: widget.leagueId),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(LeagueDetailState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(leagueDetailProvider(widget.leagueId).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          LeagueHeaderWidget(
            league: state.league!,
            memberCount: state.members.length,
            isCommissioner: state.isCommissioner,
            onSettingsTap: () {
              context.push('/leagues/${widget.leagueId}/commissioner');
            },
          ),
          const SizedBox(height: 16),
          if (state.activeDraft != null) ...[
            DraftStatusBanner(
              draft: state.activeDraft!,
              isCommissioner: state.isCommissioner,
              onJoinDraft: () {
                context.go('/leagues/${widget.leagueId}/drafts/${state.activeDraft!.id}');
              },
              onStartDraft: () => _startDraft(state.activeDraft!),
            ),
            const SizedBox(height: 16),
          ],
          LeagueSettingsSummary(
            league: state.league!,
            memberCount: state.members.length,
            draftType: state.draftTypeLabel,
          ),
          const SizedBox(height: 16),
          LeagueMembersSection(
            league: state.league!,
            members: state.members,
            totalSlots: state.league!.totalRosters,
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonTab(LeagueDetailState state) {
    final rosterId = state.league?.userRosterId;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
        // My Team card
        Card(
          child: ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('My Team'),
            subtitle: const Text('View roster and set lineup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: rosterId != null
                ? () => context.push('/leagues/${widget.leagueId}/team/$rosterId')
                : null,
          ),
        ),
        const SizedBox(height: 8),
        // Matchups card
        Card(
          child: ListTile(
            leading: const Icon(Icons.sports_football),
            title: const Text('Matchups'),
            subtitle: const Text('Weekly head-to-head'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/leagues/${widget.leagueId}/matchups'),
          ),
        ),
        const SizedBox(height: 8),
        // Standings card
        Card(
          child: ListTile(
            leading: const Icon(Icons.leaderboard),
            title: const Text('Standings'),
            subtitle: const Text('League rankings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/leagues/${widget.leagueId}/standings'),
          ),
        ),
        const SizedBox(height: 8),
        // Free Agents card
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Free Agents'),
            subtitle: const Text('Add players to your team'),
            trailing: const Icon(Icons.chevron_right),
            onTap: rosterId != null
                ? () => context.push('/leagues/${widget.leagueId}/free-agents', extra: rosterId)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        // Trades card
        Card(
          child: ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Trades'),
            subtitle: const Text('Propose and manage trades'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/leagues/${widget.leagueId}/trades'),
          ),
        ),
        // Commissioner Tools (only shown to commissioner)
        if (state.isCommissioner) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              title: Text(
                'Commissioner Tools',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Manage league settings and members',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              onTap: () => context.push('/leagues/${widget.leagueId}/commissioner'),
            ),
          ),
        ],
      ],
        ),
      ),
    );
  }
}
