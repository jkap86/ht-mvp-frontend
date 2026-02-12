import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../domain/matchup_draft_option.dart';

/// Individual matchup display tile for matchups drafts.
///
/// Shows week number + opponent information with tap-to-select functionality.
class MatchupTile extends StatelessWidget {
  final MatchupDraftOption matchup;
  final bool canDraft;
  final bool showDraftButton;
  final bool isSubmitting;
  final VoidCallback? onDraft;
  final VoidCallback? onTap;

  const MatchupTile({
    super.key,
    required this.matchup,
    this.canDraft = false,
    this.showDraftButton = true,
    this.isSubmitting = false,
    this.onDraft,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnavailable = !matchup.isAvailable;

    return Opacity(
      opacity: isUnavailable ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: isUnavailable ? null : onTap,
          borderRadius: AppSpacing.cardRadius,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Week badge
                _buildWeekBadge(theme),
                const SizedBox(width: 12),

                // Opponent info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              matchup.opponentTeamName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnavailable)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Tooltip(
                                message: 'Max opponent frequency reached (${matchup.frequencyLabel})',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: AppSpacing.cardRadius,
                                  ),
                                  child: Text(
                                    'FULL',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Matchup frequency: ${matchup.frequencyLabel}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Draft button
                if (!isUnavailable && showDraftButton && canDraft && onDraft != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : onDraft,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.htColors.draftAction,
                        foregroundColor: theme.colorScheme.onPrimary,
                        disabledBackgroundColor: context.htColors.draftAction.withAlpha(153),
                        disabledForegroundColor: theme.colorScheme.onPrimary.withAlpha(178),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSpacing.pillRadius,
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                              ),
                            )
                          : const Text(
                              'DRAFT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekBadge(ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'WK',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            '${matchup.week}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
