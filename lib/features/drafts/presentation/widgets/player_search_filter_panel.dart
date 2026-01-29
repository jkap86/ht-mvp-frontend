import 'package:flutter/material.dart';

import '../utils/player_filtering.dart';

/// Combined search bar and position filter chips panel.
///
/// Used in both snake/linear and auction drawer content to provide
/// consistent player filtering UI. Eliminates code duplication between
/// the two draft mode content widgets.
class PlayerSearchFilterPanel extends StatelessWidget {
  /// Current search query text.
  final String searchQuery;

  /// Currently selected position filter, or null for 'All'.
  final String? selectedPosition;

  /// Called when the search text changes.
  final ValueChanged<String> onSearchChanged;

  /// Called when a position filter chip is selected/deselected.
  final ValueChanged<String?> onPositionChanged;

  /// Hint text to display in the search field.
  final String hintText;

  const PlayerSearchFilterPanel({
    super.key,
    required this.searchQuery,
    required this.selectedPosition,
    required this.onSearchChanged,
    required this.onPositionChanged,
    this.hintText = 'Search players...',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          // Position filter chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(context, 'All', null),
                ...standardPositions
                    .map((pos) => _buildFilterChip(context, pos, pos)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
      BuildContext context, String label, String? position) {
    final isSelected = selectedPosition == position;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => onPositionChanged(isSelected ? null : position),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
