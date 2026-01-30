import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/api/api_client.dart';
import '../../data/draft_repository.dart';
import '../../domain/auction_budget.dart';
import '../../domain/auction_lot.dart';
import '../../domain/auction_settings.dart';
import '../../domain/bid_history_entry.dart';
import '../../domain/draft_order_entry.dart';
import '../../../players/domain/player.dart';

/// Dialog for placing bids on auction lots.
class AuctionBidDialog extends StatefulWidget {
  final int leagueId;
  final int draftId;
  final AuctionLot lot;
  final Player player;
  final AuctionBudget? myBudget;
  final List<DraftOrderEntry> draftOrder;
  final AuctionSettings settings;
  final DraftRepository? draftRepository;
  final void Function(int maxBid) onSubmit;

  const AuctionBidDialog({
    super.key,
    required this.leagueId,
    required this.draftId,
    required this.lot,
    required this.player,
    this.myBudget,
    required this.draftOrder,
    required this.settings,
    this.draftRepository,
    required this.onSubmit,
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
    DraftRepository? draftRepository,
    required void Function(int maxBid) onSubmit,
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
        draftRepository: draftRepository,
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
  List<BidHistoryEntry>? _bidHistory;
  bool _isLoadingHistory = true;

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

  @override
  void initState() {
    super.initState();
    _bidController = TextEditingController(text: _minBid.toString());
    _updateTimeRemaining();
    _startTimer();
    _loadBidHistory();
  }

  Future<void> _loadBidHistory() async {
    try {
      // Use injected repository if provided, otherwise create a new one
      final repo = widget.draftRepository ?? DraftRepository(ApiClient());
      final history = await repo.getBidHistory(
        widget.leagueId,
        widget.draftId,
        widget.lot.id,
      );
      if (mounted) {
        setState(() {
          _bidHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  String _getUsernameForRoster(int rosterId) {
    final entry = widget.draftOrder
        .where((e) => e.rosterId == rosterId)
        .firstOrNull;
    return entry?.username ?? 'Team $rosterId';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Widget _buildBidHistorySection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            'Bid Activity (${widget.lot.bidCount})',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          children: [
            if (_isLoadingHistory)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_bidHistory == null || _bidHistory!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No bid activity yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._bidHistory!.reversed.map((entry) => _buildHistoryTile(entry, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BidHistoryEntry entry, ThemeData theme) {
    final username = entry.username ?? _getUsernameForRoster(entry.rosterId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            entry.isProxy ? Icons.autorenew : Icons.person,
            size: 16,
            color: entry.isProxy
                ? theme.colorScheme.tertiary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTimeAgo(entry.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${entry.bidAmount}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
                  _getUsernameForRoster(widget.lot.currentBidderRosterId!),
                ),

              // Bid History Section
              const SizedBox(height: 8),
              _buildBidHistorySection(theme),

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
