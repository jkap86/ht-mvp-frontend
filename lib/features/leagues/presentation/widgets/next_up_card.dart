import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/league_dashboard_provider.dart';
import 'countdown_timer_widget.dart';

/// A card showing the most relevant upcoming action for the user.
/// Priority: Live Draft > Scheduled Draft > Active Auction > Waivers > In Season
class NextUpCard extends StatelessWidget {
  final LeagueDashboardState state;
  final VoidCallback? onTap;

  const NextUpCard({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nextUpType = state.nextUpType;
    if (nextUpType == NextUpType.none) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getHeaderColor(nextUpType, colorScheme),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIcon(nextUpType),
                    size: 18,
                    color: _getHeaderTextColor(nextUpType, colorScheme),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getHeaderText(nextUpType),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _getHeaderTextColor(nextUpType, colorScheme),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (nextUpType == NextUpType.draftLive)
                    _PulsingDot(color: AppTheme.draftUrgent),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(context, nextUpType, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NextUpType type, ColorScheme colorScheme) {
    switch (type) {
      case NextUpType.draftLive:
        return _buildDraftLiveContent(context, colorScheme);
      case NextUpType.draftPaused:
        return _buildDraftPausedContent(context, colorScheme);
      case NextUpType.draftScheduled:
        return _buildDraftScheduledContent(context, colorScheme);
      case NextUpType.auctionActive:
        return _buildAuctionContent(context, colorScheme);
      case NextUpType.waiversSoon:
        return _buildWaiversContent(context, colorScheme);
      case NextUpType.inSeason:
        return _buildInSeasonContent(context, colorScheme);
      case NextUpType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDraftLiveContent(BuildContext context, ColorScheme colorScheme) {
    final draft = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Draft is live!',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        if (draft != null && draft.progressText.isNotEmpty)
          Text(
            draft.progressText,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('View Draft'),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildDraftPausedContent(BuildContext context, ColorScheme colorScheme) {
    final draft = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pause_circle, color: AppTheme.draftWarning, size: 20),
            const SizedBox(width: 8),
            Text(
              'Draft is paused',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (draft != null && draft.progressText.isNotEmpty)
          Text(
            draft.progressText,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.visibility, size: 18),
          label: const Text('View Draft'),
        ),
      ],
    );
  }

  Widget _buildDraftScheduledContent(BuildContext context, ColorScheme colorScheme) {
    final draft = state.draft;
    final scheduledStart = draft?.scheduledStart;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Draft scheduled',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        if (scheduledStart != null)
          Row(
            children: [
              Text(
                'Starts in: ',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              CountdownTimerWidget(
                deadline: scheduledStart,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('View Draft'),
        ),
      ],
    );
  }

  Widget _buildAuctionContent(BuildContext context, ColorScheme colorScheme) {
    final auction = state.auction;
    if (auction == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auction active',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _InfoChip(
              icon: Icons.gavel,
              label: '${auction.activeLots} active lots',
              color: colorScheme.primaryContainer,
            ),
            if (auction.endingSoonCount > 0) ...[
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.timer,
                label: '${auction.endingSoonCount} ending soon',
                color: AppTheme.auctionPrimary.withValues(alpha: 0.15),
              ),
            ],
          ],
        ),
        if (auction.userOutbidCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'You\'ve been outbid on ${auction.userOutbidCount} player${auction.userOutbidCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.gavel, size: 18),
          label: const Text('View Auction'),
        ),
      ],
    );
  }

  Widget _buildWaiversContent(BuildContext context, ColorScheme colorScheme) {
    final waivers = state.waivers;
    if (waivers == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waivers processing soon',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        if (waivers.nextProcessingTime != null)
          Row(
            children: [
              Text(
                'Runs in: ',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              CountdownTimerWidget(
                deadline: waivers.nextProcessingTime!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        if (waivers.userClaimsCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            'You have ${waivers.userClaimsCount} pending claim${waivers.userClaimsCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.list, size: 18),
          label: const Text('View Waivers'),
        ),
      ],
    );
  }

  Widget _buildInSeasonContent(BuildContext context, ColorScheme colorScheme) {
    final matchup = state.matchup;
    if (matchup == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Week ${matchup.week}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your matchup vs ${matchup.opponentTeamName}',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.sports_football, size: 18),
          label: const Text('View Matchup'),
        ),
      ],
    );
  }

  Color _getHeaderColor(NextUpType type, ColorScheme colorScheme) {
    switch (type) {
      case NextUpType.draftLive:
        return colorScheme.errorContainer;
      case NextUpType.draftPaused:
        return AppTheme.draftWarning.withValues(alpha: 0.15);
      case NextUpType.draftScheduled:
        return colorScheme.primaryContainer;
      case NextUpType.auctionActive:
        return AppTheme.auctionPrimary.withValues(alpha: 0.15);
      case NextUpType.waiversSoon:
        return colorScheme.surfaceContainerHighest;
      case NextUpType.inSeason:
        return AppTheme.draftActionPrimary.withValues(alpha: 0.15);
      case NextUpType.none:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _getHeaderTextColor(NextUpType type, ColorScheme colorScheme) {
    switch (type) {
      case NextUpType.draftLive:
        return colorScheme.error;
      case NextUpType.draftPaused:
        return AppTheme.draftWarning;
      case NextUpType.draftScheduled:
        return colorScheme.onPrimaryContainer;
      case NextUpType.auctionActive:
        return AppTheme.auctionPrimary;
      case NextUpType.waiversSoon:
        return colorScheme.onSurface;
      case NextUpType.inSeason:
        return AppTheme.draftActionPrimary;
      case NextUpType.none:
        return colorScheme.onSurface;
    }
  }

  String _getHeaderText(NextUpType type) {
    switch (type) {
      case NextUpType.draftLive:
        return 'DRAFT LIVE';
      case NextUpType.draftPaused:
        return 'DRAFT PAUSED';
      case NextUpType.draftScheduled:
        return 'UPCOMING DRAFT';
      case NextUpType.auctionActive:
        return 'AUCTION ACTIVE';
      case NextUpType.waiversSoon:
        return 'WAIVERS';
      case NextUpType.inSeason:
        return 'THIS WEEK';
      case NextUpType.none:
        return '';
    }
  }

  IconData _getIcon(NextUpType type) {
    switch (type) {
      case NextUpType.draftLive:
      case NextUpType.draftPaused:
      case NextUpType.draftScheduled:
        return Icons.format_list_numbered;
      case NextUpType.auctionActive:
        return Icons.gavel;
      case NextUpType.waiversSoon:
        return Icons.schedule;
      case NextUpType.inSeason:
        return Icons.sports_football;
      case NextUpType.none:
        return Icons.info_outline;
    }
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
