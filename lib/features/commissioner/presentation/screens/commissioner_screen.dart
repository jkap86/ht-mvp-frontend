import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/league_context_provider.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/utils/idempotency.dart';
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

class CommissionerScreen extends ConsumerWidget {
  final int leagueId;

  const CommissionerScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Commissioner access guard
    final leagueContext = ref.watch(leagueContextProvider(leagueId));

    return leagueContext.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Commissioner Tools')),
        body: const AppLoadingView(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Commissioner Tools')),
        body: AppErrorView(
          message: 'Failed to verify access.',
          onRetry: () => ref.invalidate(leagueContextProvider(leagueId)),
        ),
      ),
      data: (ctx) {
        if (!ctx.isCommissioner) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/leagues/$leagueId');
            }
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Commissioner Tools')),
            body: const Center(child: Text('Access denied')),
          );
        }

        return _buildCommissionerContent(context, ref);
      },
    );
  }

  Widget _buildCommissionerContent(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commissionerProvider(leagueId));
    final toolsState = ref.watch(commissionerToolsProvider(leagueId));

    // Initialize trading locked state from league settings
    final tradingLocked = state.league?.leagueSettings['trading_locked'] == true;
    if (toolsState.tradingLocked != tradingLocked && !toolsState.isProcessing) {
      Future.microtask(() {
        ref.read(commissionerToolsProvider(leagueId).notifier).setTradingLocked(tradingLocked);
      });
    }

    // Show snackbar for success/error messages
    ref.listen(commissionerProvider(leagueId), (prev, next) {
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
    });

    // Show snackbar for tools provider messages
    ref.listen(commissionerToolsProvider(leagueId), (prev, next) {
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
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/leagues/$leagueId');
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
                      onRefresh: () => ref.read(commissionerProvider(leagueId).notifier).loadData(),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _buildCommissionerCards(context, ref, state),
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

  List<Widget> _buildCommissionerCards(BuildContext context, WidgetRef ref, CommissionerState state) {
    const spacing = SizedBox(height: 16);
    final toolsState = ref.watch(commissionerToolsProvider(leagueId));
    final hasFaab = (state.league?.leagueSettings['faabBudget'] as num?) != null &&
        (state.league?.leagueSettings['faabBudget'] as num) > 0;
    return [
      LeagueInfoCard(state: state),
      spacing,
      EditLeagueCard(leagueId: leagueId, state: state),
      spacing,
      MemberManagementCard(
        state: state,
        onKickMember: (rosterId, teamName, username) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).kickMember(rosterId, teamName, idempotencyKey: key);
        },
        onReinstateMember: (rosterId, teamName) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).reinstateMember(rosterId, teamName, idempotencyKey: key);
        },
      ),
      spacing,
      InviteMemberCard(leagueId: leagueId),
      spacing,
      ScheduleManagementCard(
        onGenerateSchedule: (weeks) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).generateSchedule(weeks, idempotencyKey: key);
        },
        onStartMatchupsDraft: ({
          required int weeks,
          required int pickTimeSeconds,
          required bool randomizeDraftOrder,
        }) async {
          final key = newIdempotencyKey();
          final draftId = await ref.read(commissionerProvider(leagueId).notifier).startMatchupsDraft(
            weeks: weeks,
            pickTimeSeconds: pickTimeSeconds,
            randomizeDraftOrder: randomizeDraftOrder,
            idempotencyKey: key,
          );
          if (draftId != null && context.mounted) {
            context.push('/leagues/$leagueId/drafts/$draftId');
          }
          return draftId;
        },
        seasonHasStarted: state.league?.currentWeek != null && state.league!.currentWeek > 0,
      ),
      spacing,
      ScoringCard(
        currentWeek: state.league?.currentWeek ?? 1,
        onFinalizeWeek: (week) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).finalizeWeek(week, idempotencyKey: key);
        },
      ),
      spacing,
      WaiverManagementCard(
        waiversInitialized: state.waiversInitialized,
        onInitializeWaivers: ({int? faabBudget}) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).initializeWaivers(faabBudget: faabBudget, idempotencyKey: key);
        },
        onProcessWaivers: () {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).processWaivers(idempotencyKey: key);
        },
      ),
      spacing,
      CommissionerToolsWaiversCard(
        members: state.members,
        hasFaab: hasFaab,
        onResetPriority: () {
          final key = newIdempotencyKey();
          ref.read(commissionerToolsProvider(leagueId).notifier).resetWaiverPriority(idempotencyKey: key);
        },
        onSetPriority: (rosterId, priority) {
          final key = newIdempotencyKey();
          ref.read(commissionerToolsProvider(leagueId).notifier).setWaiverPriority(rosterId, priority, idempotencyKey: key);
        },
        onSetFaabBudget: (rosterId, setTo) {
          final key = newIdempotencyKey();
          ref.read(commissionerToolsProvider(leagueId).notifier).setFaabBudget(rosterId, setTo, idempotencyKey: key);
        },
      ),
      spacing,
      CommissionerToolsTradesCard(
        tradingLocked: toolsState.tradingLocked,
        onToggleTradingLocked: (locked) {
          final key = newIdempotencyKey();
          ref.read(commissionerToolsProvider(leagueId).notifier).updateTradingLocked(locked, idempotencyKey: key);
        },
      ),
      spacing,
      DuesConfigCard(leagueId: leagueId, totalRosters: state.league?.totalRosters ?? 12),
      spacing,
      DuesTrackerCard(leagueId: leagueId),
      spacing,
      CommissionerToolsDuesCard(
        onExportCsv: () => ref.read(commissionerToolsProvider(leagueId).notifier).exportDuesCsv(),
      ),
      spacing,
      PlayoffManagementCard(
        state: state,
        leagueId: leagueId,
        onGeneratePlayoffBracket: ({
          required int playoffTeams,
          required int startWeek,
          List<int>? weeksByRound,
          bool? enableThirdPlaceGame,
          String? consolationType,
          int? consolationTeams,
        }) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).generatePlayoffBracket(
            playoffTeams: playoffTeams,
            startWeek: startWeek,
            weeksByRound: weeksByRound,
            enableThirdPlaceGame: enableThirdPlaceGame,
            consolationType: consolationType,
            consolationTeams: consolationTeams,
            idempotencyKey: key,
          );
        },
        onAdvanceWinners: (week) {
          final key = newIdempotencyKey();
          ref.read(commissionerProvider(leagueId).notifier).advanceWinners(week, idempotencyKey: key);
        },
        onViewBracket: () {
          context.push('/leagues/$leagueId/playoffs');
        },
      ),
      spacing,
      SeasonControlsCard(leagueId: leagueId, state: state),
      spacing,
      SeasonResetCard(
        leagueId: leagueId,
        state: state,
        onReset: ({
          required String newSeason,
          required String confirmationName,
          bool keepMembers = false,
          bool clearChat = true,
        }) {
          final key = newIdempotencyKey();
          return ref.read(commissionerProvider(leagueId).notifier).resetLeague(
            newSeason: newSeason,
            confirmationName: confirmationName,
            keepMembers: keepMembers,
            clearChat: clearChat,
            idempotencyKey: key,
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
                  onPressed: () => _showDeleteConfirmation(context, ref, state.league?.name ?? ''),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String leagueName) {
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
                        final key = newIdempotencyKey();
                        final success = await ref
                            .read(commissionerProvider(leagueId).notifier)
                            .deleteLeague(confirmationName: controller.text.trim(), idempotencyKey: key);
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
