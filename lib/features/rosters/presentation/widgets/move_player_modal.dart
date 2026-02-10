import 'package:flutter/material.dart';

import '../../domain/roster_lineup.dart';
import '../../domain/roster_player.dart';
import '../../../../core/widgets/position_badge.dart';

/// A modal for swapping a starter with an eligible bench player
class SwapPlayerModal extends StatelessWidget {
  /// The current player in the slot (null if empty)
  final RosterPlayer? currentPlayer;

  /// The slot being edited
  final LineupSlot slot;

  /// Eligible players from the bench that can fill this slot
  final List<RosterPlayer> eligiblePlayers;

  /// Callback when a player is selected to move into the slot
  final void Function(RosterPlayer player) onSelectPlayer;

  /// Callback when moving current player to bench
  final VoidCallback? onMoveToBench;

  const SwapPlayerModal({
    super.key,
    this.currentPlayer,
    required this.slot,
    required this.eligiblePlayers,
    required this.onSelectPlayer,
    this.onMoveToBench,
  });

  /// Shows the swap player modal as a bottom sheet
  static void show({
    required BuildContext context,
    required LineupSlot slot,
    RosterPlayer? currentPlayer,
    required List<RosterPlayer> eligiblePlayers,
    required void Function(RosterPlayer player) onSelectPlayer,
    VoidCallback? onMoveToBench,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SwapPlayerModal._buildContent(
          context: context,
          scrollController: scrollController,
          slot: slot,
          currentPlayer: currentPlayer,
          eligiblePlayers: eligiblePlayers,
          onSelectPlayer: onSelectPlayer,
          onMoveToBench: onMoveToBench,
        ),
      ),
    );
  }

  static Widget _buildContent({
    required BuildContext context,
    required ScrollController scrollController,
    required LineupSlot slot,
    RosterPlayer? currentPlayer,
    required List<RosterPlayer> eligiblePlayers,
    required void Function(RosterPlayer player) onSelectPlayer,
    VoidCallback? onMoveToBench,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  currentPlayer != null
                      ? 'Replace ${currentPlayer.fullName ?? 'Player'}'
                      : 'Select ${slot.displayName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (currentPlayer != null && onMoveToBench != null)
          ListTile(
            leading: Icon(Icons.arrow_downward, color: Theme.of(context).colorScheme.tertiary),
            title: const Text('Move to Bench'),
            onTap: () {
              Navigator.pop(context);
              onMoveToBench();
            },
          ),
        if (currentPlayer != null && onMoveToBench != null)
          const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: eligiblePlayers.length,
            itemBuilder: (context, index) {
              final player = eligiblePlayers[index];
              return ListTile(
                leading: PositionBadge(position: player.position),
                title: Text(player.fullName ?? 'Unknown'),
                subtitle: Text(player.team ?? ''),
                trailing: player.injuryStatus != null
                    ? Chip(
                        label: Text(
                          player.injuryStatus!,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelectPlayer(player);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(
      context: context,
      scrollController: ScrollController(),
      slot: slot,
      currentPlayer: currentPlayer,
      eligiblePlayers: eligiblePlayers,
      onSelectPlayer: onSelectPlayer,
      onMoveToBench: onMoveToBench,
    );
  }
}

/// A modal for moving a bench player to a starter slot
class MoveToSlotModal extends StatelessWidget {
  /// The player being moved
  final RosterPlayer player;

  /// Available slots the player can move to
  final List<LineupSlot> availableSlots;

  /// Callback when a slot is selected
  final void Function(LineupSlot slot) onSelectSlot;

  const MoveToSlotModal({
    super.key,
    required this.player,
    required this.availableSlots,
    required this.onSelectSlot,
  });

  /// Shows the move to slot modal as a bottom sheet
  static void show({
    required BuildContext context,
    required RosterPlayer player,
    required List<LineupSlot> availableSlots,
    required void Function(LineupSlot slot) onSelectSlot,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: MoveToSlotModal._buildContent(
          context: context,
          player: player,
          availableSlots: availableSlots,
          onSelectSlot: onSelectSlot,
        ),
      ),
    );
  }

  static Widget _buildContent({
    required BuildContext context,
    required RosterPlayer player,
    required List<LineupSlot> availableSlots,
    required void Function(LineupSlot slot) onSelectSlot,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Move ${player.fullName ?? 'Player'} to:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...availableSlots.map(
          (slot) => ListTile(
            leading: PositionBadge(position: slot.code),
            title: Text(slot.displayName),
            onTap: () {
              Navigator.pop(context);
              onSelectSlot(slot);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(
      context: context,
      player: player,
      availableSlots: availableSlots,
      onSelectSlot: onSelectSlot,
    );
  }
}

/// Helper class with static methods for showing player move modals
class MovePlayerModal {
  MovePlayerModal._();

  /// Shows a modal for swapping a starter slot with a bench player
  static void showSwapModal({
    required BuildContext context,
    required LineupSlot slot,
    RosterPlayer? currentPlayer,
    required List<RosterPlayer> eligiblePlayers,
    required void Function(RosterPlayer player) onSelectPlayer,
    VoidCallback? onMoveToBench,
  }) {
    SwapPlayerModal.show(
      context: context,
      slot: slot,
      currentPlayer: currentPlayer,
      eligiblePlayers: eligiblePlayers,
      onSelectPlayer: onSelectPlayer,
      onMoveToBench: onMoveToBench,
    );
  }

  /// Shows a modal for moving a bench player to a starter slot
  static void showMoveToSlotModal({
    required BuildContext context,
    required RosterPlayer player,
    required List<LineupSlot> availableSlots,
    required void Function(LineupSlot slot) onSelectSlot,
  }) {
    MoveToSlotModal.show(
      context: context,
      player: player,
      availableSlots: availableSlots,
      onSelectSlot: onSelectSlot,
    );
  }
}
