import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../providers/draft_room_provider.dart';
import '../providers/draft_queue_provider.dart';
import '../../domain/auction_lot.dart';
import 'auction_drawer_content.dart';
import 'drawer_drag_handle.dart';
import 'fast_auction_panel.dart';
import 'snake_linear_drawer_content.dart';

/// Unified bottom drawer for the draft room.
/// Adapts content based on draft type:
/// - Snake/Linear: Search + Players + Queue
/// - Auction: Active lots + Search + Players for nomination
class DraftBottomDrawer extends ConsumerStatefulWidget {
  final DraftRoomKey providerKey;
  final DraftQueueKey queueKey;
  final int leagueId;
  final int draftId;
  final bool isAuction;
  final Future<void> Function(int playerId) onMakePick;
  final Future<void> Function(int playerId) onAddToQueue;
  final Future<void> Function(int playerId)? onNominate;
  final Future<void> Function(int lotId, int maxBid)? onSetMaxBid;
  final Future<void> Function(int pickAssetId)? onMakePickAssetSelection;
  final Future<void> Function(int pickAssetId)? onAddPickAssetToQueue;
  final DraggableScrollableController? sheetController;
  final bool isPickSubmitting;
  final bool isQueueSubmitting;
  final bool isPickAssetQueueSubmitting;

  const DraftBottomDrawer({
    super.key,
    required this.providerKey,
    required this.queueKey,
    required this.leagueId,
    required this.draftId,
    required this.isAuction,
    required this.onMakePick,
    required this.onAddToQueue,
    this.onNominate,
    this.onSetMaxBid,
    this.onMakePickAssetSelection,
    this.onAddPickAssetToQueue,
    this.sheetController,
    this.isPickSubmitting = false,
    this.isQueueSubmitting = false,
    this.isPickAssetQueueSubmitting = false,
  });

  @override
  ConsumerState<DraftBottomDrawer> createState() => _DraftBottomDrawerState();
}

class _DraftBottomDrawerState extends ConsumerState<DraftBottomDrawer> {
  String _searchQuery = '';
  String? _selectedPosition;
  DraggableScrollableController? _ownedController;

  DraggableScrollableController get _sheetController =>
      widget.sheetController ?? (_ownedController ??= DraggableScrollableController());

  static const double _collapsedSize = 0.22; // Increased to fit queue
  static const double _expandedSize = 0.70;

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    final currentSize = _sheetController.size;
    final targetSize = currentSize < 0.35 ? _expandedSize : _collapsedSize;
    _sheetController.animateTo(
      targetSize,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showBidDialog(BuildContext context, AuctionLot lot) {
    final controller = TextEditingController(text: '${lot.currentBid + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Place Bid'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Max Bid',
            hintText: 'Min: \$${lot.currentBid + 1}',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final bid = int.tryParse(controller.text);
              if (bid != null && bid > lot.currentBid) {
                widget.onSetMaxBid?.call(lot.id, bid);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Bid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get draftedPlayerIds to pass to queue widget
    final draftedPlayerIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPlayerIds),
    );
    // Get draftedPickAssetIds to pass to queue widget
    final draftedPickAssetIds = ref.watch(
      draftRoomProvider(widget.providerKey).select((s) => s.draftedPickAssetIds),
    );

    // For fast auction, we need the full state
    final draftState = ref.watch(draftRoomProvider(widget.providerKey));
    final isFastAuction = draftState.isFastAuction;

    return SizedBox.expand(
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: _collapsedSize,
        minChildSize: _collapsedSize,
        maxChildSize: _expandedSize,
        snap: true,
        snapSizes: const [_collapsedSize, 0.45, _expandedSize],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle (tap to toggle) - stays outside scrollable
                DrawerDragHandle(onTap: _toggleDrawer),
                // ALL content inside one scrollable for proper drag gestures
                Expanded(
                  child: widget.isAuction
                      ? (isFastAuction
                          ? FastAuctionPanel(
                              state: draftState,
                              onBidTap: (lot) => _showBidDialog(context, lot),
                              onNominateTap: () {
                                // Expand drawer to show player search
                                _sheetController.animateTo(
                                  _expandedSize,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : AuctionDrawerContent(
                              providerKey: widget.providerKey,
                              scrollController: scrollController,
                              searchQuery: _searchQuery,
                              selectedPosition: _selectedPosition,
                              onSearchChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              onPositionChanged: (pos) =>
                                  setState(() => _selectedPosition = pos),
                              onNominate: widget.onNominate,
                              onSetMaxBid: widget.onSetMaxBid,
                            ))
                      : SnakeLinearDrawerContent(
                          providerKey: widget.providerKey,
                          queueKey: widget.queueKey,
                          leagueId: widget.leagueId,
                          draftId: widget.draftId,
                          draftedPlayerIds: draftedPlayerIds,
                          draftedPickAssetIds: draftedPickAssetIds,
                          scrollController: scrollController,
                          searchQuery: _searchQuery,
                          selectedPosition: _selectedPosition,
                          onSearchChanged: (value) =>
                              setState(() => _searchQuery = value),
                          onPositionChanged: (pos) =>
                              setState(() => _selectedPosition = pos),
                          onMakePick: widget.onMakePick,
                          onAddToQueue: widget.onAddToQueue,
                          onMakePickAssetSelection: widget.onMakePickAssetSelection,
                          onAddPickAssetToQueue: widget.onAddPickAssetToQueue,
                          isPickSubmitting: widget.isPickSubmitting,
                          isQueueSubmitting: widget.isQueueSubmitting,
                          isPickAssetQueueSubmitting: widget.isPickAssetQueueSubmitting,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
