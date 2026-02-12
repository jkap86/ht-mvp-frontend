import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../providers/league_dashboard_provider.dart';

/// Status variants for the league status pill
enum LeagueStatusType {
  draftLive,
  draftScheduled,
  draftPaused,
  auctionActive,
  waiversSoon,
  inSeason,
  playoffs,
  offseason,
  complete,
  preSeason,
}

/// A compact status indicator pill shown in league headers and cards.
class LeagueStatusPill extends StatelessWidget {
  final LeagueStatusType type;
  final String? customText;
  final int? week;
  final DateTime? scheduledTime;

  const LeagueStatusPill({
    super.key,
    required this.type,
    this.customText,
    this.week,
    this.scheduledTime,
  });

  /// Create a status pill from dashboard state
  factory LeagueStatusPill.fromDashboardState(LeagueDashboardState state) {
    final nextUpType = state.nextUpType;
    final draft = state.draft;
    final matchup = state.matchup;

    switch (nextUpType) {
      case NextUpType.draftLive:
        return const LeagueStatusPill(type: LeagueStatusType.draftLive);
      case NextUpType.draftPaused:
        return const LeagueStatusPill(type: LeagueStatusType.draftPaused);
      case NextUpType.draftScheduled:
        return LeagueStatusPill(
          type: LeagueStatusType.draftScheduled,
          scheduledTime: draft?.scheduledStart,
        );
      case NextUpType.auctionActive:
        return const LeagueStatusPill(type: LeagueStatusType.auctionActive);
      case NextUpType.waiversSoon:
        return const LeagueStatusPill(type: LeagueStatusType.waiversSoon);
      case NextUpType.inSeason:
        return LeagueStatusPill(
          type: LeagueStatusType.inSeason,
          week: matchup?.week,
        );
      case NextUpType.none:
        return const LeagueStatusPill(type: LeagueStatusType.preSeason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.showPulse)
            _PulsingIndicator(color: config.textColor)
          else if (config.icon != null)
            Icon(
              config.icon,
              size: 12,
              color: config.textColor,
            ),
          if (config.showPulse || config.icon != null)
            const SizedBox(width: 4),
          Text(
            customText ?? _getText(),
            style: TextStyle(
              color: config.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getText() {
    switch (type) {
      case LeagueStatusType.draftLive:
        return 'Draft live';
      case LeagueStatusType.draftPaused:
        return 'Draft paused';
      case LeagueStatusType.draftScheduled:
        if (scheduledTime != null) {
          return 'Draft ${_formatTimeAgo(scheduledTime!)}';
        }
        return 'Draft scheduled';
      case LeagueStatusType.auctionActive:
        return 'Auction active';
      case LeagueStatusType.waiversSoon:
        return 'Waivers soon';
      case LeagueStatusType.inSeason:
        return week != null ? 'Week $week' : 'In season';
      case LeagueStatusType.playoffs:
        return week != null ? 'Playoffs Wk $week' : 'Playoffs';
      case LeagueStatusType.offseason:
        return 'Offseason';
      case LeagueStatusType.complete:
        return 'Complete';
      case LeagueStatusType.preSeason:
        return 'Pre-season';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'starting...';
    }

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    } else {
      return 'in ${difference.inDays}d';
    }
  }

  _PillConfig _getConfig(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case LeagueStatusType.draftLive:
        return _PillConfig(
          backgroundColor: colorScheme.errorContainer,
          textColor: colorScheme.error,
          showPulse: true,
        );
      case LeagueStatusType.draftPaused:
        return _PillConfig(
          backgroundColor: AppTheme.draftWarning.withValues(alpha: 0.15),
          textColor: AppTheme.draftWarning,
          icon: Icons.pause,
        );
      case LeagueStatusType.draftScheduled:
        return _PillConfig(
          backgroundColor: colorScheme.primaryContainer,
          textColor: colorScheme.onPrimaryContainer,
          icon: Icons.schedule,
        );
      case LeagueStatusType.auctionActive:
        return _PillConfig(
          backgroundColor: context.htColors.auctionAccent.withValues(alpha: 0.15),
          textColor: context.htColors.auctionAccent,
          icon: Icons.gavel,
        );
      case LeagueStatusType.waiversSoon:
        return _PillConfig(
          backgroundColor: colorScheme.surfaceContainerHighest,
          textColor: colorScheme.onSurfaceVariant,
          icon: Icons.schedule,
        );
      case LeagueStatusType.inSeason:
        return _PillConfig(
          backgroundColor: context.htColors.draftAction.withValues(alpha: 0.15),
          textColor: context.htColors.draftAction,
          icon: Icons.sports_football,
        );
      case LeagueStatusType.playoffs:
        return _PillConfig(
          backgroundColor: AppTheme.brandPink.withValues(alpha: 0.15),
          textColor: AppTheme.brandPink,
          icon: Icons.emoji_events,
        );
      case LeagueStatusType.offseason:
        return _PillConfig(
          backgroundColor: colorScheme.surfaceContainerHighest,
          textColor: colorScheme.onSurfaceVariant,
          icon: Icons.bedtime,
        );
      case LeagueStatusType.complete:
        return _PillConfig(
          backgroundColor: AppTheme.draftSuccess.withValues(alpha: 0.15),
          textColor: AppTheme.draftSuccess,
          icon: Icons.check_circle,
        );
      case LeagueStatusType.preSeason:
        return _PillConfig(
          backgroundColor: colorScheme.surfaceContainerHighest,
          textColor: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _PillConfig {
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool showPulse;

  const _PillConfig({
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.showPulse = false,
  });
}

class _PulsingIndicator extends StatefulWidget {
  final Color color;

  const _PulsingIndicator({required this.color});

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: _animation.value),
          ),
        );
      },
    );
  }
}
