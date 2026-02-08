import 'dart:async';

import 'package:flutter/material.dart';

/// Mixin that provides countdown timer functionality for widgets displaying time-based deadlines.
/// Handles UTC time conversion and provides urgency level calculation.
/// Supports server clock offset correction for accurate countdowns on devices with clock drift.
mixin CountdownMixin<T extends StatefulWidget> on State<T> {
  Timer? _countdownTimer;
  Duration timeRemaining = Duration.zero;
  int? _serverClockOffsetMs;

  /// Start a countdown timer that updates every [interval].
  /// The [deadline] should be the target time (will be converted to UTC internally).
  /// Optionally provide [serverClockOffsetMs] to correct for client clock drift.
  void startCountdown(DateTime deadline, {Duration interval = const Duration(seconds: 1), int? serverClockOffsetMs}) {
    _serverClockOffsetMs = serverClockOffsetMs;
    updateTimeRemaining(deadline, serverClockOffsetMs: serverClockOffsetMs);
    _countdownTimer = Timer.periodic(interval, (_) => updateTimeRemaining(deadline, serverClockOffsetMs: _serverClockOffsetMs));
  }

  /// Stop the countdown timer.
  void stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Update the server clock offset for more accurate countdowns.
  void updateServerClockOffset(int? offsetMs) {
    _serverClockOffsetMs = offsetMs;
  }

  /// Get the current time adjusted for server clock offset.
  /// If no offset is available, returns device time.
  DateTime getServerNow({int? serverClockOffsetMs}) {
    final offset = serverClockOffsetMs ?? _serverClockOffsetMs;
    if (offset == null) return DateTime.now();
    return DateTime.now().add(Duration(milliseconds: offset));
  }

  /// Manually update the time remaining based on the deadline.
  /// Uses server clock offset if available for accurate countdown.
  void updateTimeRemaining(DateTime deadline, {int? serverClockOffsetMs}) {
    final now = getServerNow(serverClockOffsetMs: serverClockOffsetMs).toUtc();
    final utcDeadline = deadline.toUtc();
    if (mounted) {
      setState(() {
        final diff = utcDeadline.difference(now);
        timeRemaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  /// Get the urgency level based on time remaining.
  /// - 0: Expired
  /// - 1: Critical (<10 seconds)
  /// - 2: Urgent (<30 seconds)
  /// - 3: Warning (<5 minutes)
  /// - 4: Normal
  int getUrgencyLevel() {
    if (timeRemaining == Duration.zero) return 0;
    if (timeRemaining.inSeconds < 10) return 1;
    if (timeRemaining.inSeconds < 30) return 2;
    if (timeRemaining.inMinutes < 5) return 3;
    return 4;
  }

  /// Get urgency level for slow auctions with longer time windows.
  /// - 0: Expired
  /// - 1: Critical (<30 minutes)
  /// - 2: Soon (<2 hours)
  /// - 3: Normal
  int getSlowAuctionUrgencyLevel() {
    if (timeRemaining == Duration.zero) return 0;
    if (timeRemaining.inMinutes < 30) return 1;
    if (timeRemaining.inHours < 2) return 2;
    return 3;
  }

  /// Format the remaining time for display.
  /// For fast auctions (short durations): "1:30" or "0:05"
  String formatFastCountdown() {
    if (timeRemaining.inMinutes > 0) {
      return '${timeRemaining.inMinutes}:${(timeRemaining.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
    } else {
      return '0:${timeRemaining.inSeconds.toString().padLeft(2, '0')}';
    }
  }

  /// Format the remaining time for slow auctions (longer durations).
  /// Examples: "2d 5h", "5h 30m", "45m"
  String formatSlowCountdown() {
    if (timeRemaining == Duration.zero) return 'Ended';
    if (timeRemaining.inDays > 0) {
      return '${timeRemaining.inDays}d ${timeRemaining.inHours.remainder(24)}h';
    }
    if (timeRemaining.inHours > 0) {
      return '${timeRemaining.inHours}h ${timeRemaining.inMinutes.remainder(60)}m';
    }
    return '${timeRemaining.inMinutes}m';
  }

  /// Format a timestamp as "X ago" string.
  String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now().toUtc();
    final utcDateTime = dateTime.toUtc();
    final diff = now.difference(utcDateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
