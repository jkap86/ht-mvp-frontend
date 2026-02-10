import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/derby_state.dart';
import '../../domain/draft_order_entry.dart';
import '../providers/draft_room_provider.dart';

/// Widget displaying current turn info and countdown timer during derby phase
class DerbyTurnIndicator extends ConsumerStatefulWidget {
  final DraftRoomKey draftKey;

  const DerbyTurnIndicator({
    super.key,
    required this.draftKey,
  });

  @override
  ConsumerState<DerbyTurnIndicator> createState() => _DerbyTurnIndicatorState();
}

class _DerbyTurnIndicatorState extends ConsumerState<DerbyTurnIndicator> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
      }
    });
    _updateTimeRemaining();
  }

  void _updateTimeRemaining() {
    final state = ref.read(draftRoomProvider(widget.draftKey));
    final deadline = state.derbyState?.slotPickDeadline;
    if (deadline != null) {
      final now = DateTime.now();
      if (deadline.isAfter(now)) {
        _timeRemaining = deadline.difference(now);
      } else {
        _timeRemaining = Duration.zero;
      }
    } else {
      _timeRemaining = Duration.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(draftRoomProvider(widget.draftKey));
    final derbyState = state.derbyState;
    final draftOrder = state.draftOrder;
    final isMyTurn = state.isMyDerbyTurn;

    if (derbyState == null) {
      return const SizedBox.shrink();
    }

    final currentPickerName = _getPickerName(draftOrder, derbyState.currentPickerRosterId);
    final timeoutPolicy = derbyState.timeoutPolicy;

    // Update time remaining when derbyState changes
    _updateTimeRemaining();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMyTurn
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Turn indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMyTurn ? Icons.sports_esports : Icons.hourglass_empty,
                size: 24,
                color: isMyTurn
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                isMyTurn ? 'Your turn to pick!' : 'Waiting for $currentPickerName...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isMyTurn
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Timer
          _buildTimer(context),
          const SizedBox(height: 8),
          // Timeout policy indicator
          _buildTimeoutPolicyChip(context, timeoutPolicy),
        ],
      ),
    );
  }

  Widget _buildTimer(BuildContext context) {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;
    final isLow = _timeRemaining.inSeconds < 30;
    final isVeryLow = _timeRemaining.inSeconds < 10;

    Color timerColor;
    if (isVeryLow) {
      timerColor = Theme.of(context).colorScheme.error;
    } else if (isLow) {
      timerColor = Theme.of(context).colorScheme.tertiary;
    } else {
      timerColor = Theme.of(context).colorScheme.onSurface;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer, size: 20, color: timerColor),
        const SizedBox(width: 4),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: timerColor,
              ),
        ),
      ],
    );
  }

  Widget _buildTimeoutPolicyChip(BuildContext context, DerbyTimeoutPolicy policy) {
    String label;
    IconData icon;

    switch (policy) {
      case DerbyTimeoutPolicy.autoRandomSlot:
        label = 'Auto-assign on timeout';
        icon = Icons.shuffle;
        break;
      case DerbyTimeoutPolicy.pushBackOne:
        label = 'Move back one on timeout';
        icon = Icons.arrow_downward;
        break;
      case DerbyTimeoutPolicy.pushToEnd:
        label = 'Move to end on timeout';
        icon = Icons.last_page;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  String _getPickerName(List<DraftOrderEntry> draftOrder, int? rosterId) {
    if (rosterId == null) return 'Unknown';
    final entry = draftOrder.where((e) => e.rosterId == rosterId).firstOrNull;
    return entry?.username ?? 'Unknown';
  }
}
