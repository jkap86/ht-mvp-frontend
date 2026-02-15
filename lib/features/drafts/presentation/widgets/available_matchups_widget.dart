import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/matchup_draft_option.dart';
import 'matchup_tile.dart';

/// Widget displaying available matchup options in a matchups draft.
///
/// Replaces the player pool for matchups drafts, showing week/opponent combinations
/// with filtering and search capabilities.
class AvailableMatchupsWidget extends StatefulWidget {
  final List<MatchupDraftOption> matchups;
  final bool isMyTurn;
  final bool isSubmitting;
  final Function(int week, int opponentRosterId)? onDraft;

  const AvailableMatchupsWidget({
    super.key,
    required this.matchups,
    this.isMyTurn = false,
    this.isSubmitting = false,
    this.onDraft,
  });

  @override
  State<AvailableMatchupsWidget> createState() => _AvailableMatchupsWidgetState();
}

class _AvailableMatchupsWidgetState extends State<AvailableMatchupsWidget> {
  int? _selectedWeek;
  int? _selectedOpponent;
  String _searchQuery = '';

  List<MatchupDraftOption> get _filteredMatchups {
    var filtered = widget.matchups;

    // Filter by week
    if (_selectedWeek != null) {
      filtered = filtered.where((m) => m.week == _selectedWeek).toList();
    }

    // Filter by opponent
    if (_selectedOpponent != null) {
      filtered = filtered.where((m) => m.opponentRosterId == _selectedOpponent).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((m) => m.opponentTeamName.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  Set<int> get _availableWeeks {
    return widget.matchups.map((m) => m.week).toSet();
  }

  List<({int rosterId, String teamName})> get _availableOpponents {
    final opponents = <int, String>{};
    for (final matchup in widget.matchups) {
      opponents[matchup.opponentRosterId] = matchup.opponentTeamName;
    }
    return opponents.entries
        .map((e) => (rosterId: e.key, teamName: e.value))
        .toList()
      ..sort((a, b) => a.teamName.compareTo(b.teamName));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredMatchups = _filteredMatchups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(theme),
        const Divider(height: 1),

        // Filters
        _buildFilters(theme),

        // Matchup count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '${filteredMatchups.length} matchup${filteredMatchups.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Matchup list
        Expanded(
          child: filteredMatchups.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filteredMatchups.length,
                  itemBuilder: (context, index) {
                    final matchup = filteredMatchups[index];
                    return MatchupTile(
                      matchup: matchup,
                      canDraft: widget.isMyTurn,
                      showDraftButton: true,
                      isSubmitting: widget.isSubmitting,
                      onDraft: widget.onDraft != null
                          ? () => widget.onDraft!(matchup.week, matchup.opponentRosterId)
                          : null,
                      onTap: widget.onDraft != null && widget.isMyTurn && matchup.isAvailable
                          ? () => widget.onDraft!(matchup.week, matchup.opponentRosterId)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Available Matchups',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search opponent...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: AppSpacing.cardRadius,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 12),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Week filter
              PopupMenuButton<int?>(
                initialValue: _selectedWeek,
                onSelected: (week) {
                  setState(() => _selectedWeek = week);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Weeks'),
                  ),
                  const PopupMenuDivider(),
                  ..._availableWeeks.map(
                    (week) => PopupMenuItem(
                      value: week,
                      child: Text('Week $week'),
                    ),
                  ),
                ],
                child: Chip(
                  label: Text(_selectedWeek == null ? 'Week: All' : 'Week: $_selectedWeek'),
                  deleteIcon: _selectedWeek != null ? const Icon(Icons.close, size: 16) : null,
                  onDeleted: _selectedWeek != null
                      ? () => setState(() => _selectedWeek = null)
                      : null,
                ),
              ),

              // Opponent filter
              if (_availableOpponents.isNotEmpty)
                PopupMenuButton<int?>(
                  initialValue: _selectedOpponent,
                  onSelected: (rosterId) {
                    setState(() => _selectedOpponent = rosterId);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: null,
                      child: Text('All Opponents'),
                    ),
                    const PopupMenuDivider(),
                    ..._availableOpponents.map(
                      (opp) => PopupMenuItem(
                        value: opp.rosterId,
                        child: Text(opp.teamName),
                      ),
                    ),
                  ],
                  child: Chip(
                    label: Text(
                      _selectedOpponent == null
                          ? 'Opponent: All'
                          : 'Opponent: ${_availableOpponents.where((o) => o.rosterId == _selectedOpponent).firstOrNull?.teamName ?? 'Unknown'}',
                    ),
                    deleteIcon: _selectedOpponent != null ? const Icon(Icons.close, size: 16) : null,
                    onDeleted: _selectedOpponent != null
                        ? () => setState(() => _selectedOpponent = null)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No matchups found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedWeek != null || _selectedOpponent != null
                  ? 'Try adjusting your filters'
                  : 'All matchups have been drafted',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
