import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/semantic_colors.dart';
import '../../../rosters/domain/roster_player.dart';
import '../../domain/faab_budget.dart';

/// Dialog for submitting a waiver claim
class WaiverClaimDialog extends ConsumerStatefulWidget {
  final int leagueId;
  final int rosterId;
  final String playerName;
  final int playerId;
  final String? playerPosition;
  final String? playerTeam;
  final List<RosterPlayer> rosterPlayers;
  final FaabBudget? faabBudget;
  final bool isFaabLeague;
  final int maxRosterSize;
  final Future<void> Function({
    required int playerId,
    int? dropPlayerId,
    int bidAmount,
  }) onSubmit;

  const WaiverClaimDialog({
    super.key,
    required this.leagueId,
    required this.rosterId,
    required this.playerName,
    required this.playerId,
    this.playerPosition,
    this.playerTeam,
    required this.rosterPlayers,
    this.faabBudget,
    required this.isFaabLeague,
    required this.maxRosterSize,
    required this.onSubmit,
  });

  @override
  ConsumerState<WaiverClaimDialog> createState() => _WaiverClaimDialogState();
}

class _WaiverClaimDialogState extends ConsumerState<WaiverClaimDialog> {
  final _formKey = GlobalKey<FormState>();
  final _bidController = TextEditingController(text: '0');
  int? _selectedDropPlayerId;
  bool _isSubmitting = false;
  late bool _needsDropPlayer;

  @override
  void initState() {
    super.initState();
    // Check if roster is full and requires a drop
    _needsDropPlayer = widget.rosterPlayers.length >= widget.maxRosterSize;
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  int get _maxBid => widget.faabBudget?.remainingBudget ?? 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Waiver Claim'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Player being claimed
              _buildPlayerInfo(),
              const SizedBox(height: 16),

              // FAAB Bid (if FAAB league)
              if (widget.isFaabLeague) ...[
                _buildBidInput(),
                const SizedBox(height: 16),
              ],

              // Drop player selection (optional)
              _buildDropPlayerSection(),
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
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Claim'),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Row(
        children: [
          if (widget.playerPosition != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getPositionColor(widget.playerPosition!),
                borderRadius: AppSpacing.badgeRadius,
              ),
              child: Text(
                widget.playerPosition!,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (widget.playerTeam != null)
                  Text(
                    widget.playerTeam!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FAAB Bid',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Budget: \$$_maxBid',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bidController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            prefixText: '\$ ',
            border: OutlineInputBorder(),
            hintText: 'Enter bid amount',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a bid amount';
            }
            final bid = int.tryParse(value);
            if (bid == null || bid < 0) {
              return 'Please enter a valid amount';
            }
            if (bid > _maxBid) {
              return 'Bid exceeds available budget (\$$_maxBid)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Drop Player',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              _needsDropPlayer ? '(Required)' : '(Optional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _needsDropPlayer
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedDropPlayerId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a player to drop',
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('None'),
            ),
            ...widget.rosterPlayers.map((player) => DropdownMenuItem<int>(
                  value: player.playerId,
                  child: Text(
                    '${player.position ?? '?'} ${player.fullName ?? 'Unknown'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDropPlayerId = value;
            });
          },
          validator: _needsDropPlayer
              ? (value) {
                  if (value == null) {
                    return 'You must select a player to drop (roster is full)';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bidAmount = widget.isFaabLeague
          ? int.tryParse(_bidController.text) ?? 0
          : 0;

      await widget.onSubmit(
        playerId: widget.playerId,
        dropPlayerId: _selectedDropPlayerId,
        bidAmount: bidAmount,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

}

/// Show the waiver claim dialog
Future<bool?> showWaiverClaimDialog({
  required BuildContext context,
  required int leagueId,
  required int rosterId,
  required String playerName,
  required int playerId,
  String? playerPosition,
  String? playerTeam,
  required List<RosterPlayer> rosterPlayers,
  FaabBudget? faabBudget,
  required bool isFaabLeague,
  required int maxRosterSize,
  required Future<void> Function({
    required int playerId,
    int? dropPlayerId,
    int bidAmount,
  }) onSubmit,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => WaiverClaimDialog(
      leagueId: leagueId,
      rosterId: rosterId,
      playerName: playerName,
      playerId: playerId,
      playerPosition: playerPosition,
      playerTeam: playerTeam,
      rosterPlayers: rosterPlayers,
      faabBudget: faabBudget,
      isFaabLeague: isFaabLeague,
      maxRosterSize: maxRosterSize,
      onSubmit: onSubmit,
    ),
  );
}
