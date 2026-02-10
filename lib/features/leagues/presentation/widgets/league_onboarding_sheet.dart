import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Shows a one-time onboarding bottom sheet after a user joins or creates a league.
///
/// [leagueName] - The name of the league the user joined/created.
/// [leagueId] - The league ID (used for tracking).
/// [teamName] - The user's team name, if already assigned.
/// [hasDraftScheduled] - Whether a draft has been scheduled for this league.
/// [onViewMyTeam] - Callback invoked when the user taps "View My Team".
void showLeagueOnboardingSheet(
  BuildContext context, {
  required String leagueName,
  required int leagueId,
  String? teamName,
  required bool hasDraftScheduled,
  VoidCallback? onViewMyTeam,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _LeagueOnboardingSheet(
      leagueName: leagueName,
      leagueId: leagueId,
      teamName: teamName,
      hasDraftScheduled: hasDraftScheduled,
      onViewMyTeam: onViewMyTeam,
    ),
  );
}

class _LeagueOnboardingSheet extends StatelessWidget {
  final String leagueName;
  final int leagueId;
  final String? teamName;
  final bool hasDraftScheduled;
  final VoidCallback? onViewMyTeam;

  const _LeagueOnboardingSheet({
    required this.leagueName,
    required this.leagueId,
    this.teamName,
    required this.hasDraftScheduled,
    this.onViewMyTeam,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration,
              size: 32,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            'Welcome to $leagueName!',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),

          // Team name (if provided)
          if (teamName != null) ...[
            Text(
              'Your team: $teamName',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // "What's next" section
          Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(
                color: colorScheme.outlineVariant.withAlpha(128),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "What's next",
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hasDraftScheduled
                          ? Icons.event_available
                          : Icons.schedule,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        hasDraftScheduled
                            ? 'A draft has been scheduled! Check the league overview for details.'
                            : 'The commissioner will schedule a draft soon. Keep an eye on the league overview.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('Go to League'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onViewMyTeam?.call();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text('View My Team'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
