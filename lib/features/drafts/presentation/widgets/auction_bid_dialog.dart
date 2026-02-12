import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import '../../domain/draft_order_entry.dart';
import '../../../players/domain/player.dart';

/// Dialog for placing bids on auction lots.
/// Bid history is now shown on the lot card, so this dialog is simplified.
class AuctionBidDialog extends StatefulWidget {
  final int leagueId;
  final int draftId;
  final AuctionLot lot;
  final Player player;
  final AuctionBudget? myBudget;
  final List<DraftOrderEntry> draftOrder;
  final AuctionSettings settings;
  final Future<String?> Function(int maxBid) onSubmit;
  final int? serverClockOffsetMs;
  /// Total roster spots for max possible bid calculation
  final int? totalRosterSpots;

  const AuctionBidDialog({
    super.key,
    required this.leagueId,
    required this.draftId,
    required this.lot,
    required this.player,
    this.myBudget,
    required this.draftOrder,
    required this.settings,
    required this.onSubmit,
    this.serverClockOffsetMs,
    this.totalRosterSpots,
  });

  /// Shows the auction bid dialog.
  static Future<void> show(
    BuildContext context, {
    required int leagueId,
    required int draftId,
    required AuctionLot lot,
    required Player player,
    AuctionBudget? myBudget,
    required List<DraftOrderEntry> draftOrder,
    required AuctionSettings settings,
    required Future<String?> Function(int maxBid) onSubmit,
    int? serverClockOffsetMs,
    int? totalRosterSpots,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AuctionBidDialog(
        leagueId: leagueId,
        draftId: draftId,
        lot: lot,
        player: player,
        myBudget: myBudget,
        draftOrder: draftOrder,
        settings: settings,
        onSubmit: onSubmit,
        serverClockOffsetMs: serverClockOffsetMs,
        totalRosterSpots: totalRosterSpots,
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
  bool _isSubmitting = false;

  int get _myRosterId => widget.myBudget?.rosterId ?? -1;
  bool get _isCurrentLeader => widget.lot.currentBidderRosterId == _myRosterId;

  int get _minBid {
    if (_isCurrentLeader) {
      // Leader can raise max bid from current position
      return widget.lot.currentBid;
    }
    // Non-leader must beat currentBid + minIncrement
    return widget.lot.currentBid + widget.settings.minIncrement;
  }

  int? get _maxBid {
    if (widget.myBudget == null) return null;
    int available = widget.myBudget!.available;
    // Leader can reuse their current commitment
    if (_isCurrentLeader) {
      available += widget.lot.currentBid;
    }
    return available;
  }

  /// Max possible bid accounting for remaining roster spots needing minimum bids
  int? get _maxPossibleBid {
    if (widget.myBudget == null) return null;
    final totalSpots = widget.totalRosterSpots ?? 15;
    final remainingSpots = totalSpots - widget.myBudget!.wonCount;
    if (remainingSpots <= 1) return _maxBid; // Last spot: can bid everything
    final minBidVal = widget.settings.minBid;
    final reserved = (remainingSpots - 1) * minBidVal;
    int available = widget.myBudget!.available - reserved;
    if (_isCurrentLeader) {
      available += widget.lot.currentBid;
    }
    return available > 0 ? available : 0;
  }

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(text: _minBid.toString());
    _updateTimeRemaining();
    _startTimer();
  }

  String _getUsernameForRoster(int rosterId) {
    final entry = widget.draftOrder
        .where((e) => e.rosterId == rosterId)
        .firstOrNull;
    return entry?.username ?? 'Team $rosterId';
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
    final now = DateTime.now().add(Duration(milliseconds: widget.serverClockOffsetMs ?? 0));
    final remaining = widget.lot.bidDeadline.toUtc().difference(now.toUtc());
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

    if (_isCurrentLeader) {
      // Leader must bid at least minBid (the system setting)
      if (bid < widget.settings.minBid) {
        return 'Bid must be at least \$${widget.settings.minBid}';
      }
      // Max bid should be >= their current commitment to be meaningful
      if (bid < widget.lot.currentBid) {
        return 'Max bid must be at least \$${widget.lot.currentBid} (your current commitment)';
      }
    } else {
      // Non-leader must bid above current price + increment
      if (bid < _minBid) {
        return 'Bid must be at least \$$_minBid';
      }
    }

    if (_maxBid != null && bid > _maxBid!) {
      return 'Bid exceeds your available budget (\$$_maxBid)';
    }

    return null;
  }

  void _onSubmit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final bid = int.parse(_bidController.text);
      final playerName = widget.player.fullName;
      final error = await widget.onSubmit(bid);

      if (!mounted) return;

      if (error != null) {
        // Show error SnackBar and keep dialog open for retry
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        // Capture messenger before popping (context may become invalid)
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Bid placed: max \$$bid on $playerName'),
            backgroundColor: AppTheme.draftSuccess,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                  _getUsernameForRoster(widget.lot.currentBidderRosterId!),
                ),

              const SizedBox(height: 8),

              // Urgent warning banner when < 30 seconds remaining
              if (!isExpired && _timeRemaining.inSeconds < 30)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: AppSpacing.buttonRadius,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.onError,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lot closing soon! Submit your bid now.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Time remaining
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isExpired
                      ? theme.colorScheme.errorContainer
                      : _timeRemaining.inSeconds < 30
                          ? theme.colorScheme.errorContainer
                          : _timeRemaining.inMinutes < 5
                              ? theme.colorScheme.errorContainer.withAlpha(128)
                              : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.buttonRadius,
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
                            : _timeRemaining.inSeconds < 30
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
                if (_maxPossibleBid != null)
                  _buildInfoRow(
                    'Max Possible Bid',
                    '\$$_maxPossibleBid',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Bid input with proxy bidding explanation
              Row(
                children: [
                  Text(
                    'Your Max Bid',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message:
                        'Set your maximum bid. The system will automatically '
                        'bid the minimum needed to keep you winning, up to your max. '
                        'You only pay what\'s needed to beat other bidders.',
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 5),
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bidController,
                decoration: InputDecoration(
                  hintText: 'Enter your maximum bid',
                  prefixText: '\$ ',
                  helperText: _isCurrentLeader
                      ? 'You are leading. Raise your max bid to protect your position.'
                      : 'Minimum bid: \$$_minBid${_maxBid != null ? ' | Max: \$$_maxBid' : ''}',
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isExpired || _isSubmitting ? null : _onSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Place Bid'),
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
