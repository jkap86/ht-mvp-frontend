import '../../../players/domain/player.dart';

/// Standard fantasy football positions for filtering (without PICK).
/// PICK is added dynamically by PlayerSearchFilterPanel when showPickFilter is true.
const List<String> standardPositions = ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'];

/// Filters players by drafted status, position, and search query.
///
/// Shared between snake/linear and auction drawer content to eliminate
/// code duplication.
///
/// - [players]: The full list of players to filter
/// - [draftedIds]: Set of player IDs that have already been drafted
/// - [selectedPosition]: Optional position filter (e.g., 'QB', 'RB')
/// - [searchQuery]: Optional search text to match against name, team, or position
///
/// Returns a filtered list of available players.
List<Player> filterAvailablePlayers(
  List<Player> players, {
  required Set<int> draftedIds,
  String? selectedPosition,
  String searchQuery = '',
}) {
  final query = searchQuery.toLowerCase();
  return players.where((p) {
    // Exclude already drafted players
    if (draftedIds.contains(p.id)) return false;

    // Filter by position if selected (ignore 'PLAYERS' as it means all positions)
    if (selectedPosition != null &&
        selectedPosition != 'PLAYERS' &&
        p.primaryPosition != selectedPosition) {
      return false;
    }

    // Filter by search query if provided
    if (query.isNotEmpty) {
      return p.fullName.toLowerCase().contains(query) ||
          p.primaryPosition.toLowerCase().contains(query) ||
          (p.team?.toLowerCase().contains(query) ?? false);
    }

    return true;
  }).toList();
}
