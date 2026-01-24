import 'dart:async';

import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import '../../domain/auction_lot.dart';
import '../../domain/draft_order_entry.dart';
import '../providers/draft_room_provider.dart';

/// Panel for fast auction mode showing:
/// - Current nominator indicator
/// - Active lot with countdown timer
/// - Nominate/bid controls
class FastAuctionPanel extends StatelessWidget {
  final DraftRoomState state;
  final void Function(AuctionLot lot) onBidTap;
  final VoidCallback onNominateTap;

  const FastAuctionPanel({
    super.key,
    required this.state,
    required this.onBidTap,
    required this.onNominateTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeLot = state.activeLots.isNotEmpty ? state.activeLots.first : null;
    final nominator = state.currentNominator;
    final isMyNomination = state.isMyNomination;
    final nominationNumber = state.nominationNumber ?? 1;

    // Build a map of players by ID for quick lookup
    final playersMap = {for (var p in state.players) p.id: p};
    final budgetsMap = {for (var b in state.budgets) b.rosterId: b};

    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        border: Border(top: BorderSide(color: Colors.deepPurple[200]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with nominator info
          _buildHeader(context, nominator, isMyNomination, nominationNumber),

          // Active lot or waiting state
          if (activeLot != null)
            _FastAuctionLotCard(
              lot: activeLot,
              player: playersMap[activeLot.playerId],
              leadingBidderName: activeLot.currentBidderRosterId != null
                  ? budgetsMap[activeLot.currentBidderRosterId]?.username
                  : null,
              myBudget: state.myBudget,
              onBidTap: () => onBidTap(activeLot),
            )
          else
            _buildWaitingState(context, isMyNomination),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DraftOrderEntry? nominator,
    bool isMyNomination,
    int nominationNumber,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMyNomination ? Colors.deepPurple[100] : Colors.deepPurple[50],
        border: Border(bottom: BorderSide(color: Colors.deepPurple[200]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.gavel,
            size: 20,
            color: isMyNomination ? Colors.deepPurple : Colors.deepPurple[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyNomination
                      ? 'Your Turn to Nominate'
                      : 'Waiting for ${nominator?.username ?? 'Unknown'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isMyNomination ? Colors.deepPurple : Colors.deepPurple[700],
                  ),
                ),
                Text(
                  'Nomination #$nominationNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple[400],
                  ),
                ),
              ],
            ),
          ),
          if (state.myBudget != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$${state.myBudget!.available}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingState(BuildContext context, bool isMyNomination) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            isMyNomination ? Icons.person_add : Icons.hourglass_empty,
            size: 32,
            color: Colors.deepPurple[300],
          ),
          const SizedBox(height: 8),
          Text(
            isMyNomination
                ? 'Select a player to nominate'
                : 'Waiting for nomination...',
            style: TextStyle(
              color: Colors.deepPurple[400],
              fontSize: 14,
            ),
          ),
          if (isMyNomination) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onNominateTap,
              icon: const Icon(Icons.add),
              label: const Text('Nominate Player'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card showing the active lot in fast auction mode
class _FastAuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player? player;
  final String? leadingBidderName;
  final dynamic myBudget;
  final VoidCallback onBidTap;

  const _FastAuctionLotCard({
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.myBudget,
    required this.onBidTap,
  });

  @override
  State<_FastAuctionLotCard> createState() => _FastAuctionLotCardState();
}

class _FastAuctionLotCardState extends State<_FastAuctionLotCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void didUpdateWidget(_FastAuctionLotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lot.bidDeadline != widget.lot.bidDeadline) {
      _updateRemaining();
    }
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final deadline = widget.lot.bidDeadline;
    setState(() {
      _remaining = deadline.difference(now);
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes > 0) {
      return '${d.inMinutes}:${(d.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
    } else {
      return '0:${d.inSeconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final playerName = player?.fullName ?? 'Unknown Player';
    final position = player?.primaryPosition ?? '';
    final team = player?.team ?? '';

    final isExpired = _remaining == Duration.zero;
    final isUrgent = _remaining.inSeconds < 10 && !isExpired;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Timer - prominent at top
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.grey[300]
                      : isUrgent
                          ? Colors.red[100]
                          : Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 24,
                      color: isExpired
                          ? Colors.grey
                          : isUrgent
                              ? Colors.red
                              : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isExpired ? 'SETTLING...' : _formatDuration(_remaining),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: isExpired
                            ? Colors.grey
                            : isUrgent
                                ? Colors.red
                                : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Player info row
              Row(
                children: [
                  // Player details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$position - $team',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Current bid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${widget.lot.currentBid}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        widget.leadingBidderName ?? 'No bids',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bid button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isExpired ? null : widget.onBidTap,
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Set Max Bid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
