import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/draft_order_entry.dart';
import '../../domain/draft_pick.dart';
import '../../domain/draft_pick_asset.dart';
import '../../../leagues/domain/league.dart';
import '../providers/draft_room_provider.dart';
import '../utils/draft_board_helpers.dart';
import 'draft_grid_cell.dart';

class DraftBoardGridView extends ConsumerWidget {
  final int leagueId;
  final int draftId;

  const DraftBoardGridView({
    super.key,
    required this.leagueId,
    required this.draftId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(draftRoomProvider((leagueId: leagueId, draftId: draftId)));
    final draft = state.draft;

    if (draft == null || state.draftOrder.isEmpty) {
      return const Center(child: Text('Loading draft board...'));
    }

    final grid = buildDraftGrid(
      picks: state.picks,
      draftOrder: state.draftOrder,
      totalRounds: draft.rounds,
    );

    final currentCell = getCurrentPickCell(
      draft: draft,
      draftOrder: state.draftOrder,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with round numbers
              _buildHeaderRow(draft.rounds),
              const SizedBox(height: 4),
              // Team rows
              ...state.draftOrder.map((entry) => _buildTeamRow(
                entry: entry,
                roundPicks: grid[entry.rosterId] ?? {},
                draft: draft,
                draftOrder: state.draftOrder,
                currentCell: currentCell,
                pickAssets: state.pickAssets,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(int totalRounds) {
    return Row(
      children: [
        // Empty cell for team name column
        Container(
          width: 100,
          height: 28,
          alignment: Alignment.center,
          child: const Text(
            'Team',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        // Round number headers
        for (int round = 1; round <= totalRounds; round++)
          Container(
            width: 82,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              'R$round',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamRow({
    required DraftOrderEntry entry,
    required Map<int, DraftPick?> roundPicks,
    required Draft draft,
    required List<DraftOrderEntry> draftOrder,
    required ({int rosterId, int round})? currentCell,
    required List<DraftPickAsset> pickAssets,
  }) {
    final isCurrentTeam = currentCell?.rosterId == entry.rosterId;

    return Row(
      children: [
        // Team name cell
        Container(
          width: 100,
          height: 54,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isCurrentTeam ? Colors.amber.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrentTeam ? Colors.amber : Colors.transparent,
              width: isCurrentTeam ? 2 : 0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.username,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrentTeam ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Pick ${entry.draftPosition}',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // Pick cells for each round
        for (int round = 1; round <= draft.rounds; round++)
          _buildPickCell(
            pick: roundPicks[round],
            isCurrentPick: currentCell?.rosterId == entry.rosterId &&
                currentCell?.round == round,
            entry: entry,
            round: round,
            draft: draft,
            draftOrder: draftOrder,
            pickAssets: pickAssets,
          ),
      ],
    );
  }

  Widget _buildPickCell({
    required DraftPick? pick,
    required bool isCurrentPick,
    required DraftOrderEntry entry,
    required int round,
    required Draft draft,
    required List<DraftOrderEntry> draftOrder,
    required List<DraftPickAsset> pickAssets,
  }) {
    // Calculate the pick number for this cell
    final pickNumber = getPickNumberForGridPosition(
      round: round,
      positionInRound: getPositionInRound(
        draftPosition: entry.draftPosition,
        round: round,
        totalTeams: draftOrder.length,
        draftType: draft.draftType,
      ),
      totalTeams: draftOrder.length,
      draftType: draft.draftType,
    );

    // Find the pick asset for this slot (if any)
    final pickAsset = pickAssets
        .where((asset) =>
            asset.round == round && asset.originalRosterId == entry.rosterId)
        .firstOrNull;

    return DraftGridCell(
      pick: pick,
      isCurrentPick: isCurrentPick,
      pickNumber: pickNumber,
      pickAsset: pickAsset,
    );
  }
}
