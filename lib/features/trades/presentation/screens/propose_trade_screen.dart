import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../../data/trade_repository.dart';
import '../widgets/player_selector_widget.dart' show PlayerSelectorWidget, tradeRosterPlayersProvider;

/// Screen for proposing a new trade to another team
class ProposeTradeScreen extends ConsumerStatefulWidget {
  final int leagueId;

  const ProposeTradeScreen({super.key, required this.leagueId});

  @override
  ConsumerState<ProposeTradeScreen> createState() => _ProposeTradeScreenState();
}

class _ProposeTradeScreenState extends ConsumerState<ProposeTradeScreen> {
  int? _selectedRecipientRosterId;
  final List<int> _offeringPlayerIds = [];
  final List<int> _requestingPlayerIds = [];
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueState = ref.watch(leagueDetailProvider(widget.leagueId));

    if (leagueState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Propose Trade')),
        body: const AppLoadingView(message: 'Loading league data...'),
      );
    }

    final myRosterId = leagueState.league?.userRosterId;
    final otherMembers =
        leagueState.members.where((m) => m.id != myRosterId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose Trade'),
        actions: [
          TextButton(
            onPressed: _canSubmit() ? _handleSubmit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 1: Select Trade Partner
            Text('Trade With', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedRecipientRosterId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select a team',
              ),
              items: otherMembers
                  .map((member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(member.teamName ?? member.username),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecipientRosterId = value;
                  _requestingPlayerIds.clear();
                });
              },
            ),
            const SizedBox(height: 24),

            // Step 2: Select players you're offering
            if (myRosterId != null) ...[
              Text('You Give', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              PlayerSelectorWidget(
                leagueId: widget.leagueId,
                rosterId: myRosterId,
                selectedPlayerIds: _offeringPlayerIds,
                onSelectionChanged: (ids) => setState(() {
                  _offeringPlayerIds
                    ..clear()
                    ..addAll(ids);
                }),
              ),
              const SizedBox(height: 24),
            ],

            // Step 3: Select players you want
            if (_selectedRecipientRosterId != null) ...[
              Text('You Get', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              PlayerSelectorWidget(
                leagueId: widget.leagueId,
                rosterId: _selectedRecipientRosterId!,
                selectedPlayerIds: _requestingPlayerIds,
                onSelectionChanged: (ids) => setState(() {
                  _requestingPlayerIds
                    ..clear()
                    ..addAll(ids);
                }),
              ),
              const SizedBox(height: 24),
            ],

            // Step 4: Optional message
            Text('Message (Optional)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add a message...',
              ),
              maxLines: 3,
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    return !_isSubmitting &&
        _selectedRecipientRosterId != null &&
        _offeringPlayerIds.isNotEmpty &&
        _requestingPlayerIds.isNotEmpty;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit()) return;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final tradeRepo = ref.read(tradeRepositoryProvider);
      await tradeRepo.proposeTrade(
        leagueId: widget.leagueId,
        recipientRosterId: _selectedRecipientRosterId!,
        offeringPlayerIds: _offeringPlayerIds,
        requestingPlayerIds: _requestingPlayerIds,
        message: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
      );

      if (mounted) {
        // Get messenger before popping to ensure SnackBar displays on parent screen
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Trade proposed!'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<bool> _showConfirmationDialog() async {
    final leagueState = ref.read(leagueDetailProvider(widget.leagueId));
    final myRosterId = leagueState.league?.userRosterId;
    final recipientMember = leagueState.members.firstWhere(
      (m) => m.id == _selectedRecipientRosterId,
    );
    final recipientName = recipientMember.teamName ?? recipientMember.username;

    // Get player names from the providers
    final myPlayersAsync = myRosterId != null
        ? ref.read(tradeRosterPlayersProvider((leagueId: widget.leagueId, rosterId: myRosterId)))
        : null;
    final theirPlayersAsync = ref.read(tradeRosterPlayersProvider((
      leagueId: widget.leagueId,
      rosterId: _selectedRecipientRosterId!,
    )));

    final myPlayers = myPlayersAsync?.valueOrNull ?? [];
    final theirPlayers = theirPlayersAsync.valueOrNull ?? [];

    final offeringNames = myPlayers
        .where((p) => _offeringPlayerIds.contains(p.playerId))
        .map((p) => p.fullName ?? 'Unknown')
        .toList();
    final requestingNames = theirPlayers
        .where((p) => _requestingPlayerIds.contains(p.playerId))
        .map((p) => p.fullName ?? 'Unknown')
        .toList();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Trade Proposal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trade with $recipientName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTradeSummarySection(
                'You Give',
                offeringNames,
                Colors.red.shade100,
                Icons.arrow_upward,
              ),
              const SizedBox(height: 8),
              _buildTradeSummarySection(
                'You Get',
                requestingNames,
                Colors.green.shade100,
                Icons.arrow_downward,
              ),
              if (_messageController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Message:', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  _messageController.text,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Once sent, you can cancel this trade from the trades screen if it\'s still pending.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: const Text('Send Trade'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildTradeSummarySection(
    String label,
    List<String> playerNames,
    Color backgroundColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '${playerNames.length} player${playerNames.length != 1 ? 's' : ''}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          if (playerNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...playerNames.map((name) => Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(
                '• $name',
                style: const TextStyle(fontSize: 13),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
