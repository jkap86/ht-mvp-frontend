import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../providers/trade_block_provider.dart';

class AddToTradeBlockSheet extends ConsumerStatefulWidget {
  final int leagueId;

  const AddToTradeBlockSheet({super.key, required this.leagueId});

  @override
  ConsumerState<AddToTradeBlockSheet> createState() =>
      _AddToTradeBlockSheetState();
}

class _AddToTradeBlockSheetState extends ConsumerState<AddToTradeBlockSheet> {
  final _noteController = TextEditingController();
  int? _selectedPlayerId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leagueState = ref.watch(leagueDetailProvider(widget.leagueId));
    final tradeBlockState = ref.watch(tradeBlockProvider(widget.leagueId));
    final userRosterId = leagueState.league?.userRosterId;

    // Get roster players not already on trade block
    final onBlockIds = tradeBlockState.items
        .where((i) => i.rosterId == userRosterId)
        .map((i) => i.playerId)
        .toSet();
    final available = leagueState.rosterPlayers
        .where((p) => !onBlockIds.contains(p.playerId))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Add to Trade Block',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              // Note field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    hintText: 'Note (e.g., "Looking for RB or picks")',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLength: 200,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 4),
              // Player list
              Expanded(
                child: available.isEmpty
                    ? Center(
                        child: Text(
                          'All your players are already on the trade block',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: available.length,
                        itemBuilder: (context, index) {
                          final player = available[index];
                          final isSelected =
                              _selectedPlayerId == player.playerId;
                          return ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                player.position ?? '',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            title: Text(player.fullName ?? 'Unknown'),
                            subtitle: Text(
                              '${player.position ?? ''} - ${player.team ?? 'FA'}',
                            ),
                            selected: isSelected,
                            selectedTileColor:
                                theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                            onTap: () {
                              setState(() {
                                _selectedPlayerId = isSelected
                                    ? null
                                    : player.playerId;
                              });
                            },
                          );
                        },
                      ),
              ),
              // Confirm button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        _selectedPlayerId != null && !_isSubmitting
                            ? _submit
                            : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add to Trade Block'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_selectedPlayerId == null) return;
    setState(() => _isSubmitting = true);

    final note = _noteController.text.trim();
    final success = await ref
        .read(tradeBlockProvider(widget.leagueId).notifier)
        .addItem(_selectedPlayerId!, note: note.isEmpty ? null : note);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    }
  }
}
