import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../../data/trade_repository.dart';
import '../widgets/player_selector_widget.dart';

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
      body: SingleChildScrollView(
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
    );
  }

  bool _canSubmit() {
    return !_isSubmitting &&
        _selectedRecipientRosterId != null &&
        (_offeringPlayerIds.isNotEmpty || _requestingPlayerIds.isNotEmpty);
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit()) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade proposed!')),
        );
        context.pop();
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
