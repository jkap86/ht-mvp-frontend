import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../../core/widgets/states/app_error_view.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../../data/trade_repository.dart';
import '../../domain/trade.dart';
import '../widgets/player_selector_widget.dart';

/// Provider to fetch the original trade for counter
final originalTradeProvider =
    FutureProvider.family<Trade, ({int leagueId, int tradeId})>(
  (ref, params) async {
    final repo = ref.watch(tradeRepositoryProvider);
    return repo.getTrade(params.leagueId, params.tradeId);
  },
);

/// Screen for countering an existing trade
class CounterTradeScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final int originalTradeId;

  const CounterTradeScreen({
    super.key,
    required this.leagueId,
    required this.originalTradeId,
  });

  @override
  ConsumerState<CounterTradeScreen> createState() => _CounterTradeScreenState();
}

class _CounterTradeScreenState extends ConsumerState<CounterTradeScreen> {
  final List<int> _offeringPlayerIds = [];
  final List<int> _requestingPlayerIds = [];
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  int? _initializedForTradeId;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _initializeFromOriginalTrade(Trade originalTrade, int myRosterId) {
    // Only initialize once per trade - if trade ID changes, re-initialize
    if (_initializedForTradeId == originalTrade.id) return;
    _initializedForTradeId = originalTrade.id;

    // Clear any existing selections when re-initializing
    _offeringPlayerIds.clear();
    _requestingPlayerIds.clear();

    // Pre-fill with inverted players from original trade
    // What they were requesting becomes what we offer
    // What they were offering becomes what we request
    // NOTE: Only process player items - draft picks are not supported in counter trades yet
    for (final item in originalTrade.items) {
      // Skip draft pick items - only process player trades
      if (!item.isPlayer) continue;

      // Validate playerId is valid (> 0) before adding
      if (item.playerId <= 0) continue;

      if (item.toRosterId == myRosterId) {
        // They were giving this player to us, so we request it
        _requestingPlayerIds.add(item.playerId);
      } else if (item.fromRosterId == myRosterId) {
        // We were giving this player to them, so we offer it
        _offeringPlayerIds.add(item.playerId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leagueState = ref.watch(leagueDetailProvider(widget.leagueId));
    final originalTradeAsync = ref.watch(originalTradeProvider(
      (leagueId: widget.leagueId, tradeId: widget.originalTradeId),
    ));

    if (leagueState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Counter Trade')),
        body: const AppLoadingView(message: 'Loading league data...'),
      );
    }

    return originalTradeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Counter Trade')),
        body: const AppLoadingView(message: 'Loading trade...'),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Counter Trade')),
        body: AppErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(originalTradeProvider(
            (leagueId: widget.leagueId, tradeId: widget.originalTradeId),
          )),
        ),
      ),
      data: (originalTrade) =>
          _buildContent(context, leagueState, originalTrade),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LeagueDetailState leagueState,
    Trade originalTrade,
  ) {
    final myRosterId = leagueState.league?.userRosterId;

    // Initialize player selections from original trade
    if (myRosterId != null) {
      _initializeFromOriginalTrade(originalTrade, myRosterId);
    }

    // The other party's roster ID (the original proposer)
    final otherRosterId = originalTrade.proposerRosterId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Trade'),
        actions: [
          TextButton(
            onPressed: _canSubmit() ? _handleSubmit : null,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send Counter'),
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
                // Original trade info
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Countering trade from ${originalTrade.proposerTeamName}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (originalTrade.message != null &&
                        originalTrade.message!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Original message: "${originalTrade.message}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Players you're offering
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

            // Players you want
            Text('You Get', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            PlayerSelectorWidget(
              leagueId: widget.leagueId,
              rosterId: otherRosterId,
              selectedPlayerIds: _requestingPlayerIds,
              onSelectionChanged: (ids) => setState(() {
                _requestingPlayerIds
                  ..clear()
                  ..addAll(ids);
              }),
            ),
            const SizedBox(height: 24),

            // Optional message
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
        (_offeringPlayerIds.isNotEmpty || _requestingPlayerIds.isNotEmpty);
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit()) return;

    setState(() => _isSubmitting = true);

    try {
      final tradeRepo = ref.read(tradeRepositoryProvider);
      await tradeRepo.counterTrade(
        leagueId: widget.leagueId,
        tradeId: widget.originalTradeId,
        offeringPlayerIds: _offeringPlayerIds,
        requestingPlayerIds: _requestingPlayerIds,
        message: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Counter offer sent!')),
        );
        // Pop back to trade detail, then pop again to trades list
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
