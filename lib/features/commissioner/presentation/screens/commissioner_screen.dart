import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/states/states.dart';
import '../providers/commissioner_provider.dart';
import '../widgets/league_info_card.dart';
import '../widgets/member_management_card.dart';
import '../widgets/playoff_management_card.dart';
import '../widgets/schedule_management_card.dart';
import '../widgets/scoring_card.dart';

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
                RefreshIndicator(
                  onRefresh: () => ref.read(commissionerProvider(leagueId).notifier).loadData(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // League Status Card
                      LeagueInfoCard(state: state),
                      const SizedBox(height: 16),

                      // Member Management Card
                      MemberManagementCard(
                        state: state,
                        onKickMember: (rosterId, teamName, username) {
                          ref.read(commissionerProvider(leagueId).notifier).kickMember(rosterId, teamName);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Schedule Management Card
                      ScheduleManagementCard(
                        onGenerateSchedule: (weeks) {
                          ref.read(commissionerProvider(leagueId).notifier).generateSchedule(weeks);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Scoring Card
                      ScoringCard(
                        currentWeek: state.league?.currentWeek ?? 1,
                        onFinalizeWeek: (week) {
                          ref.read(commissionerProvider(leagueId).notifier).finalizeWeek(week);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Playoff Management Card
                      PlayoffManagementCard(
                        state: state,
                        leagueId: leagueId,
                        onGeneratePlayoffBracket: ({required int playoffTeams, required int startWeek}) {
                          ref.read(commissionerProvider(leagueId).notifier).generatePlayoffBracket(
                            playoffTeams: playoffTeams,
                            startWeek: startWeek,
                          );
                        },
                        onAdvanceWinners: (week) {
                          ref.read(commissionerProvider(leagueId).notifier).advanceWinners(week);
                        },
                        onViewBracket: () {
                          context.push('/leagues/$leagueId/playoffs');
                        },
                      ),
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
}
