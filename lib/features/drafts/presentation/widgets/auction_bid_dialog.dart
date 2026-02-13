import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import '../../domain/draft_order_entry.dart';
import '../../../players/domain/player.dart';
import '../providers/draft_room_provider.dart';

/// Dialog for placing bids on auction lots.
/// Bid history is now shown on the lot card, so this dialog is simplified.
class AuctionBidDialog extends ConsumerStatefulWidget {
  final int leagueId;
  final int draftId;
  final int lotId;
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
    required this.lotId,
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
    required int lotId,
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
        lotId: lotId,
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
  ConsumerState<AuctionBidDialog> createState() => _AuctionBidDialogState();
}

class _AuctionBidDialogState extends ConsumerState<AuctionBidDialog> {
  late final TextEditingController _bidController;
  final _formKey = GlobalKey<FormState>();
  Timer? _timer;
  final ValueNotifier<Duration> _timeRemaining = ValueNotifier(Duration.zero);
  bool _isSubmitting = false;

  int get _myRosterId => widget.myBudget?.rosterId ?? -1;

  bool _isCurrentLeader(AuctionLot lot) => lot.currentBidderRosterId == _myRosterId;

  int _getMinBid(AuctionLot lot) {
    if (_isCurrentLeader(lot)) {
      // Leader can raise max bid from current position
      return lot.currentBid;
    }
    // Non-leader must beat currentBid + minIncrement
    return lot.currentBid + widget.settings.minIncrement;
  }

  int? _getMaxBid(AuctionLot lot) {
    if (widget.myBudget == null) return null;
    int available = widget.myBudget!.available;
    // Leader can reuse their current commitment
    if (_isCurrentLeader(lot)) {
      available += lot.currentBid;
    }
    return available;
  }

  /// Max possible bid accounting for remaining roster spots needing minimum bids
  int? _getMaxPossibleBid(AuctionLot lot) {
    if (widget.myBudget == null) return null;
    final totalSpots = widget.totalRosterSpots ?? 15;
    final remainingSpots = totalSpots - widget.myBudget!.wonCount;
    if (remainingSpots <= 1) return _getMaxBid(lot); // Last spot: can bid everything
    final minBidVal = widget.settings.minBid;
    final reserved = (remainingSpots - 1) * minBidVal;
    int available = widget.myBudget!.available - reserved;
    if (_isCurrentLeader(lot)) {
      available += lot.currentBid;
    }
    return available > 0 ? available : 0;
  }

  AuctionLot? _getCurrentLot() {
    final providerKey = (leagueId: widget.leagueId, draftId: widget.draftId);
    return ref.read(draftRoomProvider(providerKey))
        .activeLots.where((l) => l.id == widget.lotId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    final initialLot = _getCurrentLot();
    _bidController = TextEditingController(
      text: initialLot != null ? _getMinBid(initialLot).toString() : '0',
    );
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
    _timeRemaining.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    final currentLot = _getCurrentLot();

    if (currentLot == null) {
      _timeRemaining.value = Duration.zero;
      return;
    }

    final now = DateTime.now().add(Duration(milliseconds: widget.serverClockOffsetMs ?? 0));
    final remaining = currentLot.bidDeadline.toUtc().difference(now.toUtc());
    _timeRemaining.value = remaining.isNegative ? Duration.zero : remaining;
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
    final currentLot = _getCurrentLot();

    if (currentLot == null) {
      return 'This lot has ended';
    }

    if (value == null || value.isEmpty) {
      return 'Please enter a bid amount';
    }

    final bid = int.tryParse(value);
    if (bid == null) {
      return 'Please enter a valid number';
    }

    final isLeader = _isCurrentLeader(currentLot);
    final minBid = _getMinBid(currentLot);
    final maxBid = _getMaxBid(currentLot);

    if (isLeader) {
      // Leader must bid at least minBid (the system setting)
      if (bid < widget.settings.minBid) {
        return 'Bid must be at least \$${widget.settings.minBid}';
      }
      // Max bid should be >= their current commitment to be meaningful
      if (bid < currentLot.currentBid) {
        return 'Max bid must be at least \$${currentLot.currentBid} (your current commitment)';
      }
    } else {
      // Non-leader must bid above current price + increment
      if (bid < minBid) {
        return 'Bid must be at least \$$minBid';
      }
    }

    if (maxBid != null && bid > maxBid) {
      return 'Bid exceeds your available budget (\$$maxBid)';
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
    final providerKey = (leagueId: widget.leagueId, draftId: widget.draftId);

    // Watch for lot updates in real-time
    final currentLot = ref.watch(
      draftRoomProvider(providerKey).select((s) =>
        s.activeLots.where((l) => l.id == widget.lotId).firstOrNull
      ),
    );

    // If lot is gone (ended), close dialog
    if (currentLot == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final lot = currentLot;
    final isCurrentLeader = _isCurrentLeader(lot);
    final minBid = _getMinBid(lot);
    final maxBid = _getMaxBid(lot);
    final maxPossibleBid = _getMaxPossibleBid(lot);

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
                '\$${lot.currentBid}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (lot.currentBidderRosterId != null)
                _buildInfoRow(
                  'Leading Bidder',
                  _getUsernameForRoster(lot.currentBidderRosterId!),
                ),

              const SizedBox(height: 8),

              // Timer-dependent section: urgent warning + time remaining display
              // Only this subtree rebuilds on timer tick
              ValueListenableBuilder<Duration>(
                valueListenable: _timeRemaining,
                builder: (context, timeRemaining, _) {
                  final isExpired = timeRemaining == Duration.zero;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Urgent warning banner when < 30 seconds remaining
                      if (!isExpired && timeRemaining.inSeconds < 30)
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
                              : timeRemaining.inSeconds < 30
                                  ? theme.colorScheme.errorContainer
                                  : timeRemaining.inMinutes < 5
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
                              isExpired ? 'Expired' : _formatDuration(timeRemaining),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isExpired
                                    ? theme.colorScheme.error
                                    : timeRemaining.inSeconds < 30
                                        ? theme.colorScheme.error
                                        : timeRemaining.inMinutes < 5
                                            ? theme.colorScheme.error
                                            : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                if (maxPossibleBid != null)
                  _buildInfoRow(
                    'Max Possible Bid',
                    '\$$maxPossibleBid',
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
                  helperText: isCurrentLeader
                      ? 'You are leading. Raise your max bid to protect your position.'
                      : 'Minimum bid: \$$minBid${maxBid != null ? ' | Max: \$$maxBid' : ''}',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: _validateBid,
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
        // Bid button depends on timer for expired state
        ValueListenableBuilder<Duration>(
          valueListenable: _timeRemaining,
          builder: (context, timeRemaining, _) {
            final isExpired = timeRemaining == Duration.zero;
            return ElevatedButton(
              onPressed: isExpired || _isSubmitting ? null : _onSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Place Bid'),
            );
          },
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
