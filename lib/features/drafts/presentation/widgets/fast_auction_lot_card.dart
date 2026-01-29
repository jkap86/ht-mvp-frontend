import 'dart:async';

import 'package:flutter/material.dart';

import '../../../players/domain/player.dart';
import '../../domain/auction_lot.dart';

/// Card widget showing the active lot in fast auction mode.
/// Displays countdown timer, player info, current bid, and bid button.
class FastAuctionLotCard extends StatefulWidget {
  final AuctionLot lot;
  final Player? player;
  final String? leadingBidderName;
  final dynamic myBudget;
  final VoidCallback onBidTap;

  const FastAuctionLotCard({
    super.key,
    required this.lot,
    required this.player,
    required this.leadingBidderName,
    required this.myBudget,
    required this.onBidTap,
  });

  @override
  State<FastAuctionLotCard> createState() => _FastAuctionLotCardState();
}

class _FastAuctionLotCardState extends State<FastAuctionLotCard> {
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
  void didUpdateWidget(FastAuctionLotCard oldWidget) {
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
              _buildTimerDisplay(isExpired, isUrgent),
              const SizedBox(height: 16),

              // Player info row
              _buildPlayerInfoRow(playerName, position, team),
              const SizedBox(height: 16),

              // Bid button
              _buildBidButton(isExpired),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerDisplay(bool isExpired, bool isUrgent) {
    return Container(
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
    );
  }

  Widget _buildPlayerInfoRow(String playerName, String position, String team) {
    return Row(
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
    );
  }

  Widget _buildBidButton(bool isExpired) {
    return SizedBox(
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
    );
  }
}
