import '../../../leagues/domain/league.dart';
import '../../domain/draft_order_entry.dart';
import '../../domain/draft_pick.dart';

/// Build a 2D grid mapping rosterId -> round -> pick
/// This allows easy lookup for the grid view: grid[rosterId][round] = pick or null
Map<int, Map<int, DraftPick?>> buildDraftGrid({
  required List<DraftPick> picks,
  required List<DraftOrderEntry> draftOrder,
  required int totalRounds,
}) {
  final grid = <int, Map<int, DraftPick?>>{};

  // Initialize grid with null values for each roster and round
  for (final entry in draftOrder) {
    grid[entry.rosterId] = {
      for (int r = 1; r <= totalRounds; r++) r: null,
    };
  }

  // Fill in picks
  for (final pick in picks) {
    if (grid.containsKey(pick.rosterId)) {
      grid[pick.rosterId]![pick.round] = pick;
    }
  }

  return grid;
}

/// Calculate which cell is the current pick in the grid
/// Returns (rosterId, round) or null if draft is not in progress
({int rosterId, int round})? getCurrentPickCell({
  required Draft? draft,
  required List<DraftOrderEntry> draftOrder,
}) {
  if (draft == null ||
      draft.currentRosterId == null ||
      draft.currentRound == null) {
    return null;
  }

  return (rosterId: draft.currentRosterId!, round: draft.currentRound!);
}

/// Get the pick number for a given position in the grid
/// This accounts for snake draft order
int getPickNumberForGridPosition({
  required int round,
  required int positionInRound, // 1-indexed position within the round
  required int totalTeams,
  required String draftType,
}) {
  final picksBeforeRound = (round - 1) * totalTeams;

  if (draftType == 'snake' && round % 2 == 0) {
    // Even rounds are reversed in snake draft
    return picksBeforeRound + (totalTeams - positionInRound + 1);
  }

  return picksBeforeRound + positionInRound;
}

/// Get the position in round (1-indexed) for a given roster in a specific round
/// This accounts for snake draft order
int getPositionInRound({
  required int draftPosition, // The roster's draft position (1-indexed)
  required int round,
  required int totalTeams,
  required String draftType,
}) {
  if (draftType == 'snake' && round % 2 == 0) {
    // Even rounds are reversed in snake draft
    return totalTeams - draftPosition + 1;
  }
  return draftPosition;
}
