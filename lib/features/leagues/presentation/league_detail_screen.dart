import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/dev_console.dart';
import '../../../core/widgets/states/states.dart';
import '../domain/league.dart';
import '../../chat/presentation/chat_widget.dart';
import 'providers/league_detail_provider.dart';
import 'widgets/league_header_widget.dart';
import 'widgets/draft_status_banner.dart';
import 'widgets/league_settings_summary.dart';
import 'widgets/league_members_section.dart';
import 'widgets/league_drafts_tab.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _createDraft() async {
    final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
    final success = await notifier.createDraft();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating draft')),
      );
    }
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
            Tab(text: 'Chat'),
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
                onCreateDraft: _createDraft,
                onStartDraft: _startDraft,
              ),
              ChatWidget(leagueId: widget.leagueId),
            ],
          ),
          if (!kReleaseMode) DevConsole(leagueId: widget.leagueId),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(LeagueDetailState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(leagueDetailProvider(widget.leagueId).notifier).loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LeagueHeaderWidget(
            league: state.league!,
            memberCount: state.members.length,
            isCommissioner: state.isCommissioner,
            onSettingsTap: () {
              // TODO: Navigate to league settings
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
    );
  }

  Widget _buildSeasonTab(LeagueDetailState state) {
    final rosterId = state.league?.userRosterId;

    return ListView(
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
    );
  }
}
