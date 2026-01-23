import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../../players/domain/player.dart';

/// Dialog for placing bids on auction lots.
class AuctionBidDialog extends StatefulWidget {
  final AuctionLot lot;
  final Player player;
  final AuctionBudget? myBudget;
  final void Function(int maxBid) onSubmit;

  const AuctionBidDialog({
    super.key,
    required this.lot,
    required this.player,
    this.myBudget,
    required this.onSubmit,
  });

  /// Shows the auction bid dialog.
  static Future<void> show(
    BuildContext context, {
    required AuctionLot lot,
    required Player player,
    AuctionBudget? myBudget,
    required void Function(int maxBid) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AuctionBidDialog(
        lot: lot,
        player: player,
        myBudget: myBudget,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<AuctionBidDialog> createState() => _AuctionBidDialogState();
}

class _AuctionBidDialogState extends State<AuctionBidDialog> {
  late final TextEditingController _bidController;
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  int get _minBid => widget.lot.currentBid + 1;
  int? get _maxBid => widget.myBudget?.available;

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(text: _minBid.toString());
    _updateTimeRemaining();
    _startTimer();
  }

  @override
  void dispose() {
    _bidController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final remaining = widget.lot.bidDeadline.difference(now);
    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  String? _validateBid(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a bid amount';
    }

    final bid = int.tryParse(value);
    if (bid == null) {
      return 'Please enter a valid number';
    }

    if (bid < _minBid) {
      return 'Bid must be at least \$$_minBid';
    }

    if (_maxBid != null && bid > _maxBid!) {
      return 'Bid exceeds your available budget (\$$_maxBid)';
    }

    return null;
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final bid = int.parse(_bidController.text);
      Navigator.pop(context);
      widget.onSubmit(bid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = _timeRemaining == Duration.zero;

    return AlertDialog(
      title: const Text('Place Bid'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player info
              _buildInfoRow(
                'Player',
                widget.player.fullName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildInfoRow('Position', widget.player.primaryPosition),
              if (widget.player.team != null)
                _buildInfoRow('Team', widget.player.team!),

              const Divider(height: 24),

              // Current bid info
              _buildInfoRow(
                'Current Bid',
                '\$${widget.lot.currentBid}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (widget.lot.currentBidderRosterId != null)
                _buildInfoRow(
                  'Leading Bidder',
                  'Roster #${widget.lot.currentBidderRosterId}',
                ),
              _buildInfoRow('Bid Count', '${widget.lot.bidCount}'),

              const SizedBox(height: 8),

              // Time remaining
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isExpired
                      ? theme.colorScheme.errorContainer
                      : _timeRemaining.inMinutes < 5
                          ? theme.colorScheme.errorContainer.withAlpha(128)
                          : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time Remaining',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      isExpired ? 'Expired' : _formatDuration(_timeRemaining),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isExpired
                            ? theme.colorScheme.error
                            : _timeRemaining.inMinutes < 5
                                ? theme.colorScheme.error
                                : null,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Budget info
              if (widget.myBudget != null) ...[
                _buildInfoRow(
                  'Your Available Budget',
                  '\$${widget.myBudget!.available}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildInfoRow(
                  'Total Budget',
                  '\$${widget.myBudget!.totalBudget}',
                ),
                _buildInfoRow(
                  'Already Spent',
                  '\$${widget.myBudget!.spent}',
                ),
                _buildInfoRow(
                  'Leading Commitments',
                  '\$${widget.myBudget!.leadingCommitment}',
                ),
                const SizedBox(height: 16),
              ],

              // Bid input
              TextFormField(
                controller: _bidController,
                decoration: InputDecoration(
                  labelText: 'Your Max Bid',
                  hintText: 'Enter your maximum bid',
                  prefixText: '\$ ',
                  helperText: 'Minimum bid: \$$_minBid'
                      '${_maxBid != null ? ' | Max: \$$_maxBid' : ''}',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: _validateBid,
                enabled: !isExpired,
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isExpired ? null : _onSubmit,
          child: const Text('Place Bid'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: style ?? Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
