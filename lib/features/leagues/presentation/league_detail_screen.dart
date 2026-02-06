import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/dev_console.dart';
import '../../../core/widgets/states/states.dart';
import '../domain/league.dart';
import '../../drafts/domain/draft_order_entry.dart';
import '../../drafts/domain/draft_type.dart';
import '../../notifications/presentation/widgets/notification_bell.dart';
import 'providers/league_detail_provider.dart';
import 'widgets/league_header_widget.dart';
import 'widgets/league_members_section.dart';
import 'widgets/league_drafts_section.dart';
import 'widgets/create_draft_dialog.dart';
import 'widgets/invite_member_sheet.dart';
import 'widgets/matchup_preview_card.dart';
import 'widgets/action_alerts_banner.dart';
import '../../drafts/presentation/widgets/edit_draft_settings_dialog.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      // At root of League tab, go to home
      context.go('/');
    }
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
        List<String>? playerPool,
        DateTime? scheduledStart,
      }) async {
        final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
        final success = await notifier.createDraft(
          draftType: draftType.value,
          rounds: rounds,
          pickTimeSeconds: pickTimeSeconds,
          settings: auctionSettings,
          playerPool: playerPool,
          scheduledStart: scheduledStart,
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

  Future<List<DraftOrderEntry>?> _randomizeDraftOrder(Draft draft) async {
    final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
    final order = await notifier.randomizeDraftOrder(draft.id);
    if (order == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error randomizing draft order'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return order;
  }

  Future<List<DraftOrderEntry>?> _setOrderFromVetDraft(Draft draft) async {
    final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
    final order = await notifier.setOrderFromPickOwnership(draft.id);
    if (order == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error setting order from vet draft results'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return order;
  }

  Future<void> _editDraftSettings(Draft draft) async {
    final league = ref.read(leagueDetailProvider(widget.leagueId)).league;
    if (league == null) return;

    await EditDraftSettingsDialog.show(
      context,
      draft: draft,
      leagueMode: league.mode,
      onSave: ({
        String? draftType,
        int? rounds,
        int? pickTimeSeconds,
        Map<String, dynamic>? auctionSettings,
        List<String>? playerPool,
        bool? includeRookiePicks,
        int? rookiePicksSeason,
        int? rookiePicksRounds,
      }) async {
        final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);
        await notifier.updateDraftSettings(
          draft.id,
          draftType: draftType,
          rounds: rounds,
          pickTimeSeconds: pickTimeSeconds,
          auctionSettings: auctionSettings,
          playerPool: playerPool,
          includeRookiePicks: includeRookiePicks,
          rookiePicksSeason: rookiePicksSeason,
          rookiePicksRounds: rookiePicksRounds,
        );
      },
    );
  }

  Future<void> _editDraftSchedule(Draft draft, DateTime? scheduledStart) async {
    final notifier = ref.read(leagueDetailProvider(widget.leagueId).notifier);

    // Extract existing player pool settings to preserve them
    final rawSettings = draft.rawSettings;
    final playerPoolRaw = rawSettings?['playerPool'];
    final playerPool = playerPoolRaw is List
        ? playerPoolRaw.map((e) => e.toString()).toList()
        : null;
    final includeRookiePicks = rawSettings?['includeRookiePicks'] as bool?;
    final rookiePicksSeason = rawSettings?['rookiePicksSeason'] as int?;

    final success = await notifier.updateDraftSettings(
      draft.id,
      scheduledStart: scheduledStart,
      playerPool: playerPool,
      includeRookiePicks: includeRookiePicks,
      rookiePicksSeason: rookiePicksSeason,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating draft schedule')),
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
            onPressed: () => _navigateBack(context),
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
            onPressed: () => _navigateBack(context),
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
          onPressed: () => _navigateBack(context),
        ),
        title: Text(state.league?.name ?? 'League'),
        actions: const [
          NotificationBell(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Season'),
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
            ],
          ),
          if (!kReleaseMode) DevConsole(leagueId: widget.leagueId),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(LeagueDetailState state) {
    // Build items list for ListView.builder
    final items = <Widget>[
      LeagueHeaderWidget(
        league: state.league!,
        memberCount: state.members.where((m) => m.userId != null).length,
        isCommissioner: state.isCommissioner,
        onSettingsTap: () {
          context.push('/leagues/${widget.leagueId}/commissioner');
        },
      ),
      const SizedBox(height: 16),
    ];

    // Matchup Preview Card (in-season only)
    if (state.isInSeason && state.currentMatchup != null) {
      items.add(MatchupPreviewCard(
        currentWeek: state.league!.currentWeek,
        matchup: state.currentMatchup!,
        userStanding: state.userStanding,
        opponentStanding: state.opponentStanding,
        userProjectedPoints: _calculateProjectedPoints(state, isUser: true),
        opponentProjectedPoints: _calculateProjectedPoints(state, isUser: false),
        lineupLockTime: _getLineupLockTime(state),
        onViewMatchup: () {
          context.push('/leagues/${widget.leagueId}/matchups/${state.currentMatchup!.id}');
        },
        onSetLineup: state.league!.userRosterId != null
            ? () => context.go('/leagues/${widget.leagueId}/team/${state.league!.userRosterId}')
            : null,
      ));
      items.add(const SizedBox(height: 16));
    }

    // Action Alerts Banner (in-season only, when alerts exist)
    if (state.isInSeason) {
      items.add(_buildActionAlertsBanner(state));
    }

    items.add(LeagueMembersSection(
      league: state.league!,
      members: state.members,
      totalSlots: state.league!.totalRosters,
    ));
    items.add(const SizedBox(height: 16));
    items.add(LeagueDraftsSection(
      key: ValueKey(state.drafts.map((d) => d.id).join(',')),
      leagueId: widget.leagueId,
      drafts: state.drafts,
      members: state.members,
      isCommissioner: state.isCommissioner,
      onCreateDraft: _createDraft,
      onStartDraft: _startDraft,
      onRandomizeDraftOrder: _randomizeDraftOrder,
      onSetOrderFromVetDraft: _setOrderFromVetDraft,
      onEditSettings: _editDraftSettings,
      onEditSchedule: _editDraftSchedule,
    ));

    return RefreshIndicator(
      onRefresh: () => ref.read(leagueDetailProvider(widget.leagueId).notifier).loadData(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        ),
      ),
    );
  }

  Widget _buildActionAlertsBanner(LeagueDetailState state) {
    final alerts = ActionAlertsBuilder.buildAlerts(
      starters: state.starters,
      currentWeek: state.league!.currentWeek,
      pendingTradeCount: state.pendingTradesCount,
      lineupSet: state.currentLineup != null,
      lineupLockingSoon: _isLineupLockingSoon(state),
      onInjuredPlayerTap: state.league!.userRosterId != null
          ? () => context.go('/leagues/${widget.leagueId}/team/${state.league!.userRosterId}')
          : null,
      onByePlayerTap: state.league!.userRosterId != null
          ? () => context.go('/leagues/${widget.leagueId}/team/${state.league!.userRosterId}')
          : null,
      onPendingTradeTap: () => context.go('/leagues/${widget.leagueId}/trades'),
      onSetLineupTap: state.league!.userRosterId != null
          ? () => context.go('/leagues/${widget.leagueId}/team/${state.league!.userRosterId}')
          : null,
    );

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ActionAlertsBanner(
        alerts: alerts,
        onViewAll: state.league!.userRosterId != null
            ? () => context.go('/leagues/${widget.leagueId}/team/${state.league!.userRosterId}')
            : null,
      ),
    );
  }

  double? _calculateProjectedPoints(LeagueDetailState state, {required bool isUser}) {
    // For now, return null as we don't have projection data readily available
    // This would need to be enhanced with actual projection data from the API
    return null;
  }

  DateTime? _getLineupLockTime(LeagueDetailState state) {
    // Default to Sunday 1pm ET for NFL games
    // This would ideally come from league settings or game schedule
    final now = DateTime.now();
    // Find next Sunday at 1pm ET (approximate - would need proper timezone handling)
    var lockTime = DateTime(now.year, now.month, now.day, 13, 0);
    while (lockTime.weekday != DateTime.sunday || lockTime.isBefore(now)) {
      lockTime = lockTime.add(const Duration(days: 1));
    }
    return lockTime;
  }

  bool _isLineupLockingSoon(LeagueDetailState state) {
    final lockTime = _getLineupLockTime(state);
    if (lockTime == null) return false;
    final hoursUntilLock = lockTime.difference(DateTime.now()).inHours;
    return hoursUntilLock < 24;
  }

  Widget _buildSeasonTab(LeagueDetailState state) {
    final rosterId = state.league?.userRosterId;

    // Build items list for ListView.builder
    final items = <Widget>[
      // My Team card - navigates to Team tab
      Card(
        child: ListTile(
          leading: const Icon(Icons.groups),
          title: const Text('My Team'),
          subtitle: const Text('View roster and set lineup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: rosterId != null
              ? () => context.go('/leagues/${widget.leagueId}/team/$rosterId')
              : null,
        ),
      ),
      const SizedBox(height: 8),
      // Matchups card - navigates to Matchups tab
      Card(
        child: ListTile(
          leading: const Icon(Icons.sports_football),
          title: const Text('Matchups'),
          subtitle: const Text('Weekly head-to-head'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/leagues/${widget.leagueId}/matchups'),
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
      // Trades card - navigates to Trades tab
      Card(
        child: ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: const Text('Trades'),
          subtitle: const Text('Propose and manage trades'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/leagues/${widget.leagueId}/trades'),
        ),
      ),
    ];

    // Invite Members card - visible to all members when league not full
    if (state.members.length < state.league!.totalRosters) {
      items.add(const SizedBox(height: 8));
      items.add(Card(
        child: ListTile(
          leading: const Icon(Icons.person_add_alt),
          title: const Text('Invite Members'),
          subtitle: Text('${state.league!.totalRosters - state.members.length} spots available'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showInviteMemberSheet(context, widget.leagueId),
        ),
      ));
    }

    // Commissioner Tools (only shown to commissioner)
    if (state.isCommissioner) {
      items.add(const SizedBox(height: 16));
      items.add(const Divider());
      items.add(const SizedBox(height: 8));
      items.add(Card(
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
      ));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        ),
      ),
    );
  }
}
