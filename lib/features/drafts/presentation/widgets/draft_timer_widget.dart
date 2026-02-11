import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';

class DraftTimerWidget extends StatefulWidget {
  final DateTime? pickDeadline;
  final VoidCallback? onTimeExpired;

  const DraftTimerWidget({
    super.key,
    this.pickDeadline,
    this.onTimeExpired,
  });

  @override
  State<DraftTimerWidget> createState() => _DraftTimerWidgetState();
}

class _DraftTimerWidgetState extends State<DraftTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _hasExpired = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startTimer();
  }

  @override
  void didUpdateWidget(DraftTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickDeadline != widget.pickDeadline) {
      _hasExpired = false;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateSecondsRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateSecondsRemaining();
    });
  }

  void _updateSecondsRemaining() {
    if (widget.pickDeadline == null) {
      setState(() => _secondsRemaining = 0);
      return;
    }

    // Use UTC for both to ensure correct countdown regardless of user's timezone
    final now = DateTime.now().toUtc();
    final deadline = widget.pickDeadline!.toUtc();
    final remaining = deadline.difference(now).inSeconds;

    setState(() {
      _secondsRemaining = remaining > 0 ? remaining : 0;
    });

    // Handle pulse animation for urgent time
    if (_secondsRemaining <= 10 && _secondsRemaining > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Handle expiry
    if (_secondsRemaining <= 0 && !_hasExpired) {
      _hasExpired = true;
      widget.onTimeExpired?.call();
    }
  }

  Color _getTimerColor(BuildContext context) {
    if (_secondsRemaining <= 0) {
      return context.htColors.textMuted;
    }
    if (_secondsRemaining <= 10) {
      return AppTheme.draftUrgent; // Red - urgent
    }
    if (_secondsRemaining <= 30) {
      return AppTheme.draftWarning; // Amber - warning
    }
    if (_secondsRemaining <= 60) {
      return AppTheme.draftNormal; // Blue - normal
    }
    return AppTheme.draftSuccess; // Green - plenty of time
  }

  String _formatTime() {
    if (_secondsRemaining <= 0) return 'AUTO';

    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pickDeadline == null) {
      return const SizedBox.shrink();
    }

    final color = _getTimerColor(context);
    final timeText = _formatTime();

    Widget timerContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(35),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _secondsRemaining <= 0 ? Icons.smart_toy : Icons.timer,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    // Apply pulse animation when urgent
    if (_secondsRemaining <= 10 && _secondsRemaining > 0) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: timerContent,
      );
    }

    return timerContent;
  }
}
