import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../dues/presentation/widgets/dues_config_card.dart';
import '../../../dues/presentation/widgets/dues_tracker_card.dart';

class CommissionerScreen extends ConsumerWidget {
  final int leagueId;

  const CommissionerScreen({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(commissionerProvider(leagueId));

    // Show snackbar for success/error messages
    ref.listen(commissionerProvider(leagueId), (prev, next) {
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
              context.go('/leagues/$leagueId');
            }
          },
        ),
        title: const Text('Commissioner Tools'),
      ),
      body: state.isLoading
          ? const AppLoadingView()
          : Stack(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: RefreshIndicator(
                      onRefresh: () => ref.read(commissionerProvider(leagueId).notifier).loadData(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 13, // 13 cards total including Danger Zone
                        itemBuilder: (context, index) {
                          // Add spacing between cards (except first one)
                          Widget wrapWithSpacing(Widget child) {
                            if (index == 0) return child;
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                child,
                              ],
                            );
                          }

                          switch (index) {
                            case 0:
                              return LeagueInfoCard(state: state);
                            case 1:
                              return wrapWithSpacing(EditLeagueCard(
                                leagueId: leagueId,
                                state: state,
                              ));
                            case 2:
                              return wrapWithSpacing(MemberManagementCard(
                                state: state,
                                onKickMember: (rosterId, teamName, username) {
                                  ref.read(commissionerProvider(leagueId).notifier).kickMember(rosterId, teamName);
                                },
                                onReinstateMember: (rosterId, teamName) {
                                  ref.read(commissionerProvider(leagueId).notifier).reinstateMember(rosterId, teamName);
                                },
                              ));
                            case 3:
                              return wrapWithSpacing(InviteMemberCard(leagueId: leagueId));
                            case 4:
                              return wrapWithSpacing(ScheduleManagementCard(
                                onGenerateSchedule: (weeks) {
                                  ref.read(commissionerProvider(leagueId).notifier).generateSchedule(weeks);
                                },
                              ));
                            case 5:
                              return wrapWithSpacing(ScoringCard(
                                currentWeek: state.league?.currentWeek ?? 1,
                                onFinalizeWeek: (week) {
                                  ref.read(commissionerProvider(leagueId).notifier).finalizeWeek(week);
                                },
                              ));
                            case 6:
                              return wrapWithSpacing(WaiverManagementCard(
                                waiversInitialized: state.waiversInitialized,
                                onInitializeWaivers: ({int? faabBudget}) {
                                  ref.read(commissionerProvider(leagueId).notifier).initializeWaivers(faabBudget: faabBudget);
                                },
                                onProcessWaivers: () {
                                  ref.read(commissionerProvider(leagueId).notifier).processWaivers();
                                },
                              ));
                            case 7:
                              return wrapWithSpacing(DuesConfigCard(
                                leagueId: leagueId,
                                totalRosters: state.league?.totalRosters ?? 12,
                              ));
                            case 8:
                              return wrapWithSpacing(DuesTrackerCard(leagueId: leagueId));
                            case 9:
                              return wrapWithSpacing(PlayoffManagementCard(
                                state: state,
                                leagueId: leagueId,
                                onGeneratePlayoffBracket: ({
                                  required int playoffTeams,
                                  required int startWeek,
                                  bool? enableThirdPlaceGame,
                                  String? consolationType,
                                  int? consolationTeams,
                                }) {
                                  ref.read(commissionerProvider(leagueId).notifier).generatePlayoffBracket(
                                    playoffTeams: playoffTeams,
                                    startWeek: startWeek,
                                    enableThirdPlaceGame: enableThirdPlaceGame,
                                    consolationType: consolationType,
                                    consolationTeams: consolationTeams,
                                  );
                                },
                                onAdvanceWinners: (week) {
                                  ref.read(commissionerProvider(leagueId).notifier).advanceWinners(week);
                                },
                                onViewBracket: () {
                                  context.push('/leagues/$leagueId/playoffs');
                                },
                              ));
                            case 10:
                              return wrapWithSpacing(SeasonControlsCard(
                                leagueId: leagueId,
                                state: state,
                              ));
                            case 11:
                              return wrapWithSpacing(SeasonResetCard(
                                state: state,
                                onReset: ({
                                  required String newSeason,
                                  required String confirmationName,
                                  bool keepMembers = false,
                                  bool clearChat = true,
                                }) {
                                  return ref.read(commissionerProvider(leagueId).notifier).resetLeague(
                                    newSeason: newSeason,
                                    confirmationName: confirmationName,
                                    keepMembers: keepMembers,
                                    clearChat: clearChat,
                                  );
                                },
                              ));
                            case 12:
                              // Danger Zone Card
                              return wrapWithSpacing(Card(
                                color: Colors.red.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.warning, color: Colors.red.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Danger Zone',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
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
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(Icons.delete_forever),
                                          label: const Text('Delete League'),
                                          onPressed: () => _showDeleteConfirmation(context, ref, state.league?.name ?? ''),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ));
                            default:
                              return const SizedBox.shrink();
                          }
                        },
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
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: matches
                    ? () async {
                        Navigator.of(dialogContext).pop();
                        final success = await ref
                            .read(commissionerProvider(leagueId).notifier)
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
