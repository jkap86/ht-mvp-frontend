import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/hype_train_colors.dart';
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
    final notifier = ref.read(draftRoomProvider((leagueId: leagueId, draftId: draftId)).notifier);
    final draft = state.draft;

    if (draft == null || state.draftOrder.isEmpty) {
      return const Center(child: Text('Loading draft board...'));
    }

    return Column(
      children: [
        // Axis toggle row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Teams: ',
                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Columns')),
                  ButtonSegment(value: false, label: Text('Rows')),
                ],
                selected: {state.teamsOnXAxis},
                onSelectionChanged: (_) => notifier.toggleGridAxis(),
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        // Grid content
        Expanded(
          child: state.teamsOnXAxis
              ? _buildTeamsOnXAxis(context, state, draft)
              : _buildTeamsOnYAxis(context, state, draft),
        ),
      ],
    );
  }

  /// Teams on X-axis (columns), Rounds on Y-axis (rows) - NEW DEFAULT
  Widget _buildTeamsOnXAxis(BuildContext context, DraftRoomState state, Draft draft) {
    final grid = buildDraftGrid(
      picks: state.picks,
      draftOrder: state.draftOrder,
      totalRounds: draft.rounds,
    );
    final currentCell = getCurrentPickCell(draft: draft, draftOrder: state.draftOrder);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 54 + (92 + 2) * state.draftOrder.length + 16, // Round label + cells + padding
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with team names
              _buildTeamHeaderRow(context, state.draftOrder, currentCell),
              const SizedBox(height: 4),
              // Round rows - use ListView.builder for lazy rendering
              Expanded(
                child: ListView.builder(
                  itemCount: draft.rounds,
                  itemBuilder: (context, index) {
                    final round = index + 1;
                    return _buildRoundRow(
                      context: context,
                      round: round,
                      draftOrder: state.draftOrder,
                      grid: grid,
                      draft: draft,
                      currentCell: currentCell,
                      pickAssets: state.pickAssets,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Teams on Y-axis (rows), Rounds on X-axis (columns) - ORIGINAL
  Widget _buildTeamsOnYAxis(BuildContext context, DraftRoomState state, Draft draft) {
    final grid = buildDraftGrid(
      picks: state.picks,
      draftOrder: state.draftOrder,
      totalRounds: draft.rounds,
    );
    final currentCell = getCurrentPickCell(draft: draft, draftOrder: state.draftOrder);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 100 + (92 + 2) * draft.rounds + 16, // Team label + cells + padding
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with round numbers
              _buildRoundHeaderRow(context, draft.rounds),
              const SizedBox(height: 4),
              // Team rows - use ListView.builder for lazy rendering
              Expanded(
                child: ListView.builder(
                  itemCount: state.draftOrder.length,
                  itemBuilder: (context, index) {
                    final entry = state.draftOrder[index];
                    return _buildTeamRow(
                      context: context,
                      entry: entry,
                      roundPicks: grid[entry.rosterId] ?? {},
                      draft: draft,
                      draftOrder: state.draftOrder,
                      currentCell: currentCell,
                      pickAssets: state.pickAssets,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundHeaderRow(BuildContext context, int totalRounds) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Empty cell for team name column
        Container(
          width: 100,
          height: 32,
          alignment: Alignment.center,
          child: Text(
            'Team',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // Round number headers
        for (int round = 1; round <= totalRounds; round++)
          Container(
            width: 92,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              'R$round',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }

  /// Header row with team names (for teams-on-X-axis layout)
  Widget _buildTeamHeaderRow(
    BuildContext context,
    List<DraftOrderEntry> draftOrder,
    ({int rosterId, int round})? currentCell,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Empty cell for round label column
        Container(
          width: 54,
          height: 58,
          alignment: Alignment.center,
          child: Text(
            'Round',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // Team headers
        for (final entry in draftOrder)
          _buildTeamHeaderCell(context, entry, currentCell?.rosterId == entry.rosterId),
      ],
    );
  }

  Widget _buildTeamHeaderCell(BuildContext context, DraftOrderEntry entry, bool isCurrentTeam) {
    final theme = Theme.of(context);

    return Container(
      width: 92,
      height: 58,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: isCurrentTeam
            ? context.htColors.draftAction.withAlpha(30)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCurrentTeam ? context.htColors.draftAction : Colors.transparent,
          width: isCurrentTeam ? 2 : 0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  entry.username,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrentTeam ? FontWeight.w600 : FontWeight.w500,
                    color: isCurrentTeam
                        ? context.htColors.draftAction
                        : theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (entry.isAutodraftEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Tooltip(
                    message: 'Autodraft enabled',
                    child: Icon(
                      Icons.flash_auto,
                      size: 12,
                      color: AppTheme.draftWarning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '#${entry.draftPosition}',
            style: TextStyle(
              fontSize: 9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Row of picks for a single round (for teams-on-X-axis layout)
  Widget _buildRoundRow({
    required BuildContext context,
    required int round,
    required List<DraftOrderEntry> draftOrder,
    required Map<int, Map<int, DraftPick?>> grid,
    required Draft draft,
    required ({int rosterId, int round})? currentCell,
    required List<DraftPickAsset> pickAssets,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Round label
        Container(
          width: 54,
          height: 58,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'R$round',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        // Pick cells for each team
        for (final entry in draftOrder)
          _buildPickCell(
            pick: grid[entry.rosterId]?[round],
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

  Widget _buildTeamRow({
    required BuildContext context,
    required DraftOrderEntry entry,
    required Map<int, DraftPick?> roundPicks,
    required Draft draft,
    required List<DraftOrderEntry> draftOrder,
    required ({int rosterId, int round})? currentCell,
    required List<DraftPickAsset> pickAssets,
  }) {
    final theme = Theme.of(context);
    final isCurrentTeam = currentCell?.rosterId == entry.rosterId;

    return Row(
      children: [
        // Team name cell
        Container(
          width: 100,
          height: 58,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isCurrentTeam
                ? context.htColors.draftAction.withAlpha(30)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCurrentTeam ? context.htColors.draftAction : Colors.transparent,
              width: isCurrentTeam ? 2 : 0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.username,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrentTeam ? FontWeight.w600 : FontWeight.w500,
                        color: isCurrentTeam
                            ? context.htColors.draftAction
                            : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Autodraft indicator
                  if (entry.isAutodraftEnabled)
                    Tooltip(
                      message: 'Autodraft enabled',
                      child: Icon(
                        Icons.flash_auto,
                        size: 14,
                        color: AppTheme.draftWarning,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Pick ${entry.draftPosition}',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
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
    // Filter by draftId to ensure we only match assets for this specific draft
    final pickAsset = pickAssets
        .where((asset) =>
            asset.draftId == draftId &&
            asset.round == round &&
            asset.originalRosterId == entry.rosterId)
        .firstOrNull;

    return DraftGridCell(
      pick: pick,
      isCurrentPick: isCurrentPick,
      pickNumber: pickNumber,
      pickAsset: pickAsset,
    );
  }
}
