import 'dart:async';
import 'package:flutter/material.dart';

/// A countdown timer widget that displays time remaining until a deadline.
/// Changes color based on urgency: red <24h, yellow/orange <3 days.
class CountdownTimerWidget extends StatefulWidget {
  final DateTime deadline;
  final TextStyle? style;
  final bool showIcon;
  final String? prefix;

  const CountdownTimerWidget({
    super.key,
    required this.deadline,
    this.style,
    this.showIcon = true,
    this.prefix,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void didUpdateWidget(CountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.deadline.difference(now);
    if (mounted) {
      setState(() {
        _remaining = remaining.isNegative ? Duration.zero : remaining;
      });
    }
  }

  Color _getUrgencyColor() {
    if (_remaining.inHours < 24) {
      return Colors.red.shade600;
    } else if (_remaining.inHours < 72) {
      return Colors.orange.shade600;
    }
    return Colors.grey.shade600;
  }

  String _formatDuration() {
    if (_remaining == Duration.zero) {
      return 'Now';
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      final seconds = _remaining.inSeconds % 60;
      return '${minutes}m ${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getUrgencyColor();
    final text = _formatDuration();

    final effectiveStyle = (widget.style ?? const TextStyle()).copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(Icons.timer, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          widget.prefix != null ? '${widget.prefix} $text' : text,
          style: effectiveStyle,
        ),
      ],
    );
  }
}

/// A simple inline countdown that just returns the formatted string
class CountdownText extends StatefulWidget {
  final DateTime deadline;
  final String prefix;
  final String suffix;

  const CountdownText({
    super.key,
    required this.deadline,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _updateText();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateText());
  }

  @override
  void didUpdateWidget(CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline) {
      _updateText();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateText() {
    final now = DateTime.now();
    var remaining = widget.deadline.difference(now);
    if (remaining.isNegative) remaining = Duration.zero;

    String formatted;
    if (remaining == Duration.zero) {
      formatted = 'Now';
    } else {
      final days = remaining.inDays;
      final hours = remaining.inHours % 24;
      final minutes = remaining.inMinutes % 60;

      if (days > 0) {
        formatted = '${days}d ${hours}h';
      } else if (hours > 0) {
        formatted = '${hours}h ${minutes}m';
      } else {
        formatted = '${minutes}m';
      }
    }

    if (mounted) {
      setState(() {
        _text = '${widget.prefix}$formatted${widget.suffix}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text);
  }
}
