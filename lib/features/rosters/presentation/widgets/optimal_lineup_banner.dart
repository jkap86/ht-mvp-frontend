import 'package:flutter/material.dart';

import '../providers/team_provider.dart';

/// Banner that shows when the lineup is not optimal and offers to auto-set
class OptimalLineupBanner extends StatelessWidget {
  final List<LineupIssue> issues;
  final double currentProjected;
  final double optimalProjected;
  final bool isSaving;
  final VoidCallback onSetOptimal;

  const OptimalLineupBanner({
    super.key,
    required this.issues,
    required this.currentProjected,
    required this.optimalProjected,
    required this.isSaving,
    required this.onSetOptimal,
  });

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) return const SizedBox.shrink();

    final gainedPoints = optimalProjected - currentProjected;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lineup Not Optimal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'You could gain ${gainedPoints.toStringAsFixed(1)} projected points',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: isSaving ? null : onSetOptimal,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Auto-Set'),
                ),
              ],
            ),
          ),

          // Show top suggestion
          if (issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildTopSuggestion(context, issues.first),
            ),
        ],
      ),
    );
  }

  Widget _buildTopSuggestion(BuildContext context, LineupIssue issue) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Current player (lower projection)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.currentPlayer.fullName ?? 'Unknown',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(issue.currentPlayer.projectedPoints ?? 0).toStringAsFixed(1)} pts',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Arrow with difference
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                const Icon(Icons.arrow_forward, size: 16, color: Colors.green),
                Text(
                  '+${issue.projectionDiff.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Suggested player (higher projection)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  issue.suggestedPlayer.fullName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${(issue.suggestedPlayer.projectedPoints ?? 0).toStringAsFixed(1)} pts',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
