import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/draft_room_provider.dart';
import 'available_matchups_widget.dart';
import 'my_schedule_widget.dart';

/// Content for matchups drafts in the bottom drawer.
/// Shows available matchup options and the user's drafted schedule.
class MatchupsDrawerContent extends ConsumerWidget {
  final DraftRoomKey providerKey;
  final int leagueId;
  final int draftId;
  final ScrollController scrollController;
  final Future<void> Function(int week, int opponentRosterId) onPickMatchup;
  final bool isPickSubmitting;

  const MatchupsDrawerContent({
    super.key,
    required this.providerKey,
    required this.leagueId,
    required this.draftId,
    required this.scrollController,
    required this.onPickMatchup,
    this.isPickSubmitting = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableMatchups = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.availableMatchups),
    );
    final myPicks = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.myPicks),
    );
    final username = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.currentPicker?.username ?? 'My Team'),
    );
    final isMyTurn = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.isMyTurn),
    );
    final totalWeeks = ref.watch(
      draftRoomProvider(providerKey).select((s) => s.draft?.rounds ?? 0),
    );

    return Row(
      children: [
        // Left side: Available matchups (player pool equivalent)
        Expanded(
          flex: 3,
          child: AvailableMatchupsWidget(
            matchups: availableMatchups,
            isMyTurn: isMyTurn,
            isSubmitting: isPickSubmitting,
            onDraft: onPickMatchup,
          ),
        ),

        // Divider
        const VerticalDivider(width: 1),

        // Right side: My schedule (roster equivalent)
        Expanded(
          flex: 2,
          child: MyScheduleWidget(
            myPicks: myPicks,
            username: username,
            totalWeeks: totalWeeks,
          ),
        ),
      ],
    );
  }
}
