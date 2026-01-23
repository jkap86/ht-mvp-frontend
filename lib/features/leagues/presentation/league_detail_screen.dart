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
    _tabController = TabController(length: 3, vsync: this);
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
}
