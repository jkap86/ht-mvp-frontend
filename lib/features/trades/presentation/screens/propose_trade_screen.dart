import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/states/app_loading_view.dart';
import '../../../leagues/presentation/providers/league_detail_provider.dart';
import '../../data/trade_repository.dart';
import '../widgets/player_selector_widget.dart' show PlayerSelectorWidget, tradeRosterPlayersProvider;
import '../widgets/draft_pick_selector_widget.dart';

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
  Set<int> _offeringPickAssetIds = {};
  Set<int> _requestingPickAssetIds = {};
  bool _isSubmitting = false;
  bool _notifyDm = true;
  String _leagueChatMode = 'summary';
  bool _leagueChatModeInitialized = false;

  void _initializeLeagueChatMode(LeagueDetailState leagueState) {
    if (_leagueChatModeInitialized) return;
    _leagueChatModeInitialized = true;

    final leagueSettings = leagueState.league?.leagueSettings;
    final max = (leagueSettings?['tradeProposalLeagueChatMax'] as String?) ?? 'details';
    final defaultMode = (leagueSettings?['tradeProposalLeagueChatDefault'] as String?) ?? 'summary';

    // Clamp default to max
    _leagueChatMode = _clampMode(defaultMode, max);
  }

  String _clampMode(String mode, String max) {
    const order = ['none', 'summary', 'details'];
    final modeIdx = order.indexOf(mode);
    final maxIdx = order.indexOf(max);
    if (modeIdx < 0 || maxIdx < 0) return 'summary';
    return order[modeIdx.clamp(0, maxIdx)];
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

    // Initialize league chat mode from league settings (once)
    _initializeLeagueChatMode(leagueState);

    final myRosterId = leagueState.league?.userRosterId;
    final otherMembers =
        leagueState.members.where((m) => m.rosterId != myRosterId).toList();

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
          constraints: const BoxConstraints(maxWidth: 900),
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
                        value: member.rosterId,
                        child: Text(member.teamName ?? member.username),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecipientRosterId = value;
                  _requestingPlayerIds.clear();
                  _requestingPickAssetIds = {};
                });
              },
            ),
            const SizedBox(height: 24),

            // Step 2: Side-by-side roster selection
            if (myRosterId != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // You Give section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const SizedBox(height: 16),
                        DraftPickSelectorWidget(
                          rosterId: myRosterId,
                          selectedPickAssetIds: _offeringPickAssetIds,
                          onSelectionChanged: (ids) => setState(() {
                            _offeringPickAssetIds = ids;
                          }),
                          title: 'You Give',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // You Get section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You Get', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_selectedRecipientRosterId != null) ...[
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
                          const SizedBox(height: 16),
                          DraftPickSelectorWidget(
                            rosterId: _selectedRecipientRosterId!,
                            selectedPickAssetIds: _requestingPickAssetIds,
                            onSelectionChanged: (ids) => setState(() {
                              _requestingPickAssetIds = ids;
                            }),
                            title: 'You Get',
                          ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Center(
                              child: Text(
                                'Select a trade partner',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

            // Notification Options
            const SizedBox(height: 24),
            Text('Notification Options', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Send DM'),
                    subtitle: const Text('Send trade details directly to recipient'),
                    value: _notifyDm,
                    onChanged: (value) => setState(() => _notifyDm = value),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('League Chat Notification'),
                    subtitle: Text(_getLeagueChatModeDescription(_leagueChatMode)),
                    trailing: DropdownButton<String>(
                      value: _leagueChatMode,
                      underline: const SizedBox(),
                      items: _buildLeagueChatModeItems(),
                      onChanged: (value) {
                        if (value != null) setState(() => _leagueChatMode = value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  String _getLeagueChatModeDescription(String mode) {
    switch (mode) {
      case 'none':
        return 'No notification in league chat';
      case 'summary':
        return 'Post summary to league chat';
      case 'details':
        return 'Post full details to league chat';
      default:
        return '';
    }
  }

  List<DropdownMenuItem<String>> _buildLeagueChatModeItems() {
    final leagueState = ref.read(leagueDetailProvider(widget.leagueId));
    final leagueSettings = leagueState.league?.leagueSettings;
    final max = (leagueSettings?['tradeProposalLeagueChatMax'] as String?) ?? 'details';

    final items = <DropdownMenuItem<String>>[];
    items.add(const DropdownMenuItem(value: 'none', child: Text('None')));

    if (max == 'summary' || max == 'details') {
      items.add(const DropdownMenuItem(value: 'summary', child: Text('Summary')));
    }

    if (max == 'details') {
      items.add(const DropdownMenuItem(value: 'details', child: Text('Full Details')));
    }

    return items;
  }

  bool _canSubmit() {
    final hasAssetsToOffer = _offeringPlayerIds.isNotEmpty || _offeringPickAssetIds.isNotEmpty;
    final hasAssetsToRequest = _requestingPlayerIds.isNotEmpty || _requestingPickAssetIds.isNotEmpty;
    return !_isSubmitting &&
        _selectedRecipientRosterId != null &&
        hasAssetsToOffer &&
        hasAssetsToRequest;
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
        notifyDm: _notifyDm,
        leagueChatMode: _leagueChatMode,
        offeringPickAssetIds: _offeringPickAssetIds.toList(),
        requestingPickAssetIds: _requestingPickAssetIds.toList(),
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
        final errorMsg = e.toString().toLowerCase();
        String displayMessage;
        if (errorMsg.contains('pending trade') ||
            errorMsg.contains('already in another trade')) {
          displayMessage =
              'One or more selected players are already in another pending trade. Remove them and try again.';
        } else {
          displayMessage = 'Error: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(displayMessage)),
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

    // Use firstWhereOrNull pattern to prevent crash if member not found
    final recipientMember = leagueState.members
        .where((m) => m.rosterId == _selectedRecipientRosterId)
        .firstOrNull;
    if (recipientMember == null) {
      // Member not found - show error and cancel
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Recipient not found')),
        );
      }
      return false;
    }
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

    // Get pick names from the providers
    final myPicksAsync = myRosterId != null
        ? ref.read(tradeRosterPicksProvider(myRosterId))
        : null;
    final theirPicksAsync = ref.read(tradeRosterPicksProvider(_selectedRecipientRosterId!));

    final myPicks = myPicksAsync?.valueOrNull ?? [];
    final theirPicks = theirPicksAsync.valueOrNull ?? [];

    final offeringPlayerNames = myPlayers
        .where((p) => _offeringPlayerIds.contains(p.playerId))
        .map((p) => p.fullName ?? 'Unknown')
        .toList();
    final requestingPlayerNames = theirPlayers
        .where((p) => _requestingPlayerIds.contains(p.playerId))
        .map((p) => p.fullName ?? 'Unknown')
        .toList();

    final offeringPickNames = myPicks
        .where((p) => _offeringPickAssetIds.contains(p.id))
        .map((p) => p.displayName)
        .toList();
    final requestingPickNames = theirPicks
        .where((p) => _requestingPickAssetIds.contains(p.id))
        .map((p) => p.displayName)
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
                offeringPlayerNames,
                offeringPickNames,
                Colors.red.shade100,
                Icons.arrow_upward,
              ),
              const SizedBox(height: 8),
              _buildTradeSummarySection(
                'You Get',
                requestingPlayerNames,
                requestingPickNames,
                Colors.green.shade100,
                Icons.arrow_downward,
              ),
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
    List<String> pickNames,
    Color backgroundColor,
    IconData icon,
  ) {
    final totalAssets = playerNames.length + pickNames.length;
    final assetLabel = _buildAssetCountLabel(playerNames.length, pickNames.length);

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
                assetLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          if (totalAssets > 0) ...[
            const SizedBox(height: 8),
            if (playerNames.isNotEmpty) ...[
              ...playerNames.map((name) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(
                  '• $name',
                  style: const TextStyle(fontSize: 13),
                ),
              )),
            ],
            if (pickNames.isNotEmpty) ...[
              ...pickNames.map((name) => Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    const Icon(Icons.sports_football, size: 12),
                    const SizedBox(width: 4),
                    Text(name, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }

  String _buildAssetCountLabel(int playerCount, int pickCount) {
    final parts = <String>[];
    if (playerCount > 0) {
      parts.add('$playerCount player${playerCount != 1 ? 's' : ''}');
    }
    if (pickCount > 0) {
      parts.add('$pickCount pick${pickCount != 1 ? 's' : ''}');
    }
    return parts.isEmpty ? 'No assets' : parts.join(' + ');
  }
}
