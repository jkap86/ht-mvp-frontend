import 'package:flutter/material.dart';

import '../../../../core/theme/hype_train_colors.dart';
import '../../domain/league.dart';
import '../../domain/league_lifecycle.dart';

class LeagueLifecycleProgressBar extends StatelessWidget {
  final League league;
  final List<Roster> members;
  final List<Draft> drafts;
  final bool hasSchedule;

  const LeagueLifecycleProgressBar({
    super.key,
    required this.league,
    required this.members,
    required this.drafts,
    required this.hasSchedule,
  });

  @override
  Widget build(BuildContext context) {
    final steps = LeagueLifecycleCalculator.calculateSteps(
      league: league,
      members: members,
      drafts: drafts,
      hasSchedule: hasSchedule,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProgressBarRow(steps: steps),
        const SizedBox(height: 4),
        _StepLabelsRow(steps: steps),
      ],
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final List<LifecycleStep> steps;

  const _ProgressBarRow({required this.steps});

  @override
  Widget build(BuildContext context) {
    final colors = context.htColors;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: _buildSegment(colors, steps[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildSegment(HypeTrainColors colors, LifecycleStep step) {
    final color = switch (step.status) {
      StepStatus.completed => colors.draftAction.withValues(alpha: 0.5),
      StepStatus.current => colors.draftAction,
      StepStatus.upcoming => colors.divider,
    };

    final bar = Container(
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );

    if (step.status == StepStatus.current) {
      return _PulseAnimation(child: bar);
    }
    return bar;
  }
}

class _StepLabelsRow extends StatelessWidget {
  final List<LifecycleStep> steps;

  const _StepLabelsRow({required this.steps});

  @override
  Widget build(BuildContext context) {
    final colors = context.htColors;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Text(
              steps[i].label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: steps[i].status == StepStatus.current
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: switch (steps[i].status) {
                  StepStatus.completed => colors.textSecondary,
                  StepStatus.current => colors.draftAction,
                  StepStatus.upcoming => colors.textMuted,
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;

  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
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
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
