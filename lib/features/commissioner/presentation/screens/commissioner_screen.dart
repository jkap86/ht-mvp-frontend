import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/league_context_provider.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/widgets/skeletons/skeletons.dart';
import '../../../../core/widgets/states/states.dart';
import '../providers/commissioner_provider.dart';
import '../widgets/edit_league_card.dart';
import '../widgets/league_info_card.dart';
import '../widgets/invite_member_card.dart';
import '../widgets/member_management_card.dart';
import '../widgets/playoff_management_card.dart';
import '../widgets/schedule_management_card.dart';
import '../widgets/scoring_card.dart';
import '../widgets/season_controls_card.dart';
import '../widgets/season_reset_card.dart';
import '../widgets/waiver_management_card.dart';
import '../widgets/commissioner_tools_waivers_card.dart';
import '../widgets/commissioner_tools_trades_card.dart';
import '../widgets/commissioner_tools_dues_card.dart';
import '../providers/commissioner_tools_provider.dart';
import '../../../dues/presentation/widgets/dues_config_card.dart';
import '../../../dues/presentation/widgets/dues_tracker_card.dart';

class CommissionerScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const CommissionerScreen({super.key, required this.leagueId});

  @override
  ConsumerState<CommissionerScreen> createState() => _CommissionerScreenState();
}

class _CommissionerScreenState extends ConsumerState<CommissionerScreen> {
  final List<ProviderSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscriptions.add(ref.listenManual(
        commissionerProvider(widget.leagueId),
        (prev, next) {
          if (next.successMessage != null && prev?.successMessage != next.successMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.successMessage!),
                backgroundColor: Theme.of(context).colorScheme.primary,
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
      ));
      _subscriptions.add(ref.listenManual(
        commissionerToolsProvider(widget.leagueId),
        (prev, next) {
          if (next.successMessage != null && prev?.successMessage != next.successMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.successMessage!),
                backgroundColor: Theme.of(context).colorScheme.primary,
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
      ));
      // Sync trading_locked state from league settings into tools provider
      _subscriptions.add(ref.listenManual(
        commissionerProvider(widget.leagueId),
        (prev, next) {
          final tradingLocked = next.league?.leagueSettings['trading_locked'] == true;
          final toolsState = ref.read(commissionerToolsProvider(widget.leagueId));
          if (toolsState.tradingLocked != tradingLocked && !toolsState.isProcessing) {
            ref.read(commissionerToolsProvider(widget.leagueId).notifier).setTradingLocked(tradingLocked);
          }
        },
        fireImmediately: true,
      ));
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.close();
    }
    _subscriptions.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Commissioner access guard
    final leagueContext = ref.watch(leagueContextProvider(widget.leagueId));

    return leagueContext.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Commissioner Tools')),
        body: const AppLoadingView(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Commissioner Tools')),
        body: AppErrorView(
          message: 'Failed to verify access.',
          onRetry: () => ref.invalidate(leagueContextProvider(widget.leagueId)),
        ),
      ),
      data: (ctx) {
        if (!ctx.isCommissioner) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/leagues/${widget.leagueId}');
            }
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Commissioner Tools')),
            body: const Center(child: Text('Access denied')),
          );
        }

        return _buildCommissionerContent();
      },
    );
  }

  Widget _buildCommissionerContent() {
    final state = ref.watch(commissionerProvider(widget.leagueId));
    final toolsState = ref.watch(commissionerToolsProvider(widget.leagueId));

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
          ? const SkeletonList(itemCount: 5)
          : Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: AppLayout.contentConstraints(context),
                    child: RefreshIndicator(
                      onRefresh: () => ref.read(commissionerProvider(widget.leagueId).notifier).loadData(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _buildCommissionerCards(state),
                      ),
                    ),
                  ),
                ),
                if (state.isProcessing || toolsState.isProcessing)
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

  List<Widget> _buildCommissionerCards(CommissionerState state) {
    const spacing = SizedBox(height: 16);
    final toolsState = ref.watch(commissionerToolsProvider(widget.leagueId));
    final hasFaab = (state.league?.leagueSettings['faabBudget'] as num?) != null &&
        (state.league?.leagueSettings['faabBudget'] as num) > 0;
    return [
      LeagueInfoCard(state: state),
      spacing,
      EditLeagueCard(leagueId: widget.leagueId, state: state),
      spacing,
      MemberManagementCard(
        state: state,
        onKickMember: (rosterId, teamName, username) {
          ref.read(commissionerProvider(widget.leagueId).notifier).kickMember(rosterId, teamName);
        },
        onReinstateMember: (rosterId, teamName) {
          ref.read(commissionerProvider(widget.leagueId).notifier).reinstateMember(rosterId, teamName);
        },
      ),
      spacing,
      InviteMemberCard(leagueId: widget.leagueId),
      spacing,
      ScheduleManagementCard(
        onGenerateSchedule: (weeks) {
          ref.read(commissionerProvider(widget.leagueId).notifier).generateSchedule(weeks);
        },
        onStartMatchupsDraft: ({
          required int weeks,
          required int pickTimeSeconds,
          required bool randomizeDraftOrder,
        }) async {
          final draftId = await ref.read(commissionerProvider(widget.leagueId).notifier).startMatchupsDraft(
            weeks: weeks,
            pickTimeSeconds: pickTimeSeconds,
            randomizeDraftOrder: randomizeDraftOrder,
          );
          if (draftId != null && mounted) {
            context.push('/leagues/${widget.leagueId}/drafts/$draftId');
          }
          return draftId;
        },
        seasonHasStarted: state.league?.currentWeek != null && state.league!.currentWeek > 0,
      ),
      spacing,
      ScoringCard(
        currentWeek: state.league?.currentWeek ?? 1,
        onFinalizeWeek: (week) {
          ref.read(commissionerProvider(widget.leagueId).notifier).finalizeWeek(week);
        },
      ),
      spacing,
      WaiverManagementCard(
        waiversInitialized: state.waiversInitialized,
        onInitializeWaivers: ({int? faabBudget}) {
          ref.read(commissionerProvider(widget.leagueId).notifier).initializeWaivers(faabBudget: faabBudget);
        },
        onProcessWaivers: () {
          ref.read(commissionerProvider(widget.leagueId).notifier).processWaivers();
        },
      ),
      spacing,
      CommissionerToolsWaiversCard(
        members: state.members,
        hasFaab: hasFaab,
        onResetPriority: () {
          ref.read(commissionerToolsProvider(widget.leagueId).notifier).resetWaiverPriority();
        },
        onSetPriority: (rosterId, priority) {
          ref.read(commissionerToolsProvider(widget.leagueId).notifier).setWaiverPriority(rosterId, priority);
        },
        onSetFaabBudget: (rosterId, setTo) {
          ref.read(commissionerToolsProvider(widget.leagueId).notifier).setFaabBudget(rosterId, setTo);
        },
      ),
      spacing,
      CommissionerToolsTradesCard(
        tradingLocked: toolsState.tradingLocked,
        onToggleTradingLocked: (locked) {
          ref.read(commissionerToolsProvider(widget.leagueId).notifier).updateTradingLocked(locked);
        },
      ),
      spacing,
      DuesConfigCard(leagueId: widget.leagueId, totalRosters: state.league?.totalRosters ?? 12),
      spacing,
      DuesTrackerCard(leagueId: widget.leagueId),
      spacing,
      CommissionerToolsDuesCard(
        onExportCsv: () => ref.read(commissionerToolsProvider(widget.leagueId).notifier).exportDuesCsv(),
      ),
      spacing,
      PlayoffManagementCard(
        state: state,
        leagueId: widget.leagueId,
        onGeneratePlayoffBracket: ({
          required int playoffTeams,
          required int startWeek,
          List<int>? weeksByRound,
          bool? enableThirdPlaceGame,
          String? consolationType,
          int? consolationTeams,
        }) {
          ref.read(commissionerProvider(widget.leagueId).notifier).generatePlayoffBracket(
            playoffTeams: playoffTeams,
            startWeek: startWeek,
            weeksByRound: weeksByRound,
            enableThirdPlaceGame: enableThirdPlaceGame,
            consolationType: consolationType,
            consolationTeams: consolationTeams,
          );
        },
        onAdvanceWinners: (week) {
          ref.read(commissionerProvider(widget.leagueId).notifier).advanceWinners(week);
        },
        onViewBracket: () {
          context.push('/leagues/${widget.leagueId}/playoffs');
        },
      ),
      spacing,
      SeasonControlsCard(leagueId: widget.leagueId, state: state),
      spacing,
      SeasonResetCard(
        leagueId: widget.leagueId,
        state: state,
        onReset: ({
          required String newSeason,
          required String confirmationName,
          bool keepMembers = false,
          bool clearChat = true,
        }) {
          return ref.read(commissionerProvider(widget.leagueId).notifier).resetLeague(
            newSeason: newSeason,
            confirmationName: confirmationName,
            keepMembers: keepMembers,
            clearChat: clearChat,
          );
        },
      ),
      spacing,
      // Danger Zone
      Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text(
                    'Danger Zone',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Deleting the league will permanently remove all data including rosters, drafts, matchups, and transactions. This action cannot be undone.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete League'),
                  onPressed: () => _showDeleteConfirmation(state.league?.name ?? ''),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _showDeleteConfirmation(String leagueName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final matches = controller.text.trim().toLowerCase() == leagueName.trim().toLowerCase();
          return AlertDialog(
            title: const Text('Delete League?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will permanently delete the league and all associated data. This action cannot be undone.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Type "$leagueName" to confirm',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: matches
                    ? () async {
                        Navigator.of(dialogContext).pop();
                        final success = await ref
                            .read(commissionerProvider(widget.leagueId).notifier)
                            .deleteLeague(confirmationName: controller.text.trim());
                        if (success && context.mounted) {
                          context.go('/');
                        }
                      }
                    : null,
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );
  }
}
