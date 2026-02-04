import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../leagues/domain/league.dart';
import '../domain/auction_budget.dart';
import '../domain/auction_lot.dart';
import '../domain/auction_state.dart';
import '../domain/bid_history_entry.dart';
import '../domain/draft_order_entry.dart';

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DraftRepository(apiClient);
});

class DraftRepository {
  final ApiClient _apiClient;

  DraftRepository(this._apiClient);

  Future<Draft> getDraft(int leagueId, int draftId) async {
    final response = await _apiClient.get('/leagues/$leagueId/drafts/$draftId');
    return Draft.fromJson(response);
  }

  Future<Draft> startDraft(int leagueId, int draftId) async {
    final response =
        await _apiClient.post('/leagues/$leagueId/drafts/$draftId/start');
    return Draft.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getDraftPicks(
      int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/picks');
    final picks = (response as List?) ?? [];
    // Safe cast: filter out any non-Map elements to prevent runtime crashes
    return picks.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> getDraftOrder(
      int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/order');
    final order = (response as List?) ?? [];
    // Safe cast: filter out any non-Map elements to prevent runtime crashes
    return order.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> makePick(
      int leagueId, int draftId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/pick',
      body: {'player_id': playerId},
    );
    final pickData = response as Map<String, dynamic>?;
    if (pickData == null) throw Exception('Invalid response: missing pick data');
    return pickData;
  }

  Future<List<DraftOrderEntry>> randomizeDraftOrder(int leagueId, int draftId) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts/$draftId/randomize');
    final order = (response as List?) ?? [];
    return order
        .map((json) => DraftOrderEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DraftOrderEntry>> confirmDraftOrder(int leagueId, int draftId) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts/$draftId/order/confirm');
    final order = (response as List?) ?? [];
    return order
        .map((json) => DraftOrderEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Queue methods
  Future<List<Map<String, dynamic>>> getQueue(int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/queue');
    final queue = (response as List?) ?? [];
    // Safe cast: filter out any non-Map elements to prevent runtime crashes
    return queue.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> addToQueue(
      int leagueId, int draftId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'player_id': playerId},
    );
    final queueData = response as Map<String, dynamic>?;
    if (queueData == null) throw Exception('Invalid response: missing queue data');
    return queueData;
  }

  Future<void> removeFromQueue(int leagueId, int draftId, int playerId) async {
    await _apiClient.delete('/leagues/$leagueId/drafts/$draftId/queue/$playerId');
  }

  Future<List<Map<String, dynamic>>> reorderQueue(
      int leagueId, int draftId, List<int> playerIds) async {
    final response = await _apiClient.put(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'player_ids': playerIds},
    );
    final reordered = (response as List?) ?? [];
    // Safe cast: filter out any non-Map elements to prevent runtime crashes
    return reordered.whereType<Map<String, dynamic>>().toList();
  }

  // Auction methods
  Future<List<AuctionLot>> getAuctionLots(int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/auction/lots');
    final lots = (response['lots'] as List?) ?? [];
    return lots
        .map((json) => AuctionLot.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuctionBudget>> getAuctionBudgets(int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/auction/budgets');
    final budgets = (response['budgets'] as List?) ?? [];
    return budgets
        .map((json) => AuctionBudget.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AuctionLot> nominate(int leagueId, int draftId, int playerId) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {'action': 'nominate', 'playerId': playerId},
    );
    final lotData = response['data']?['lot'] ?? response['lot'];
    if (lotData == null) {
      throw Exception('Nominate response missing lot data');
    }
    return AuctionLot.fromJson(lotData as Map<String, dynamic>);
  }

  Future<AuctionLot> setMaxBid(
      int leagueId, int draftId, int lotId, int maxBid) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {'action': 'set_max_bid', 'lotId': lotId, 'maxBid': maxBid},
    );
    final lotData = response['data']?['lot'] ?? response['lot'];
    if (lotData == null) {
      throw Exception('SetMaxBid response missing lot data');
    }
    return AuctionLot.fromJson(lotData as Map<String, dynamic>);
  }

  /// Get bid history for a specific auction lot
  Future<List<BidHistoryEntry>> getBidHistory(
      int leagueId, int draftId, int lotId) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/drafts/$draftId/auction/lots/$lotId/history',
    );
    final historyData = (response['history'] as List?) ?? [];
    return historyData
        .map((json) => BidHistoryEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get the current auction state (for both slow and fast auctions)
  Future<AuctionState> getAuctionState(int leagueId, int draftId) async {
    final response =
        await _apiClient.get('/leagues/$leagueId/drafts/$draftId/auction/state');
    final stateData = response as Map<String, dynamic>?;
    if (stateData == null) throw Exception('Invalid response: missing auction state');
    return AuctionState.fromJson(stateData);
  }

  /// Toggle autodraft for the current user
  Future<Map<String, dynamic>> toggleAutodraft(
      int leagueId, int draftId, bool enabled) async {
    final response = await _apiClient.patch(
      '/leagues/$leagueId/drafts/$draftId/autodraft',
      body: {'enabled': enabled},
    );
    return response as Map<String, dynamic>;
  }

  /// Update draft settings (commissioner only)
  Future<Draft> updateDraftSettings(
    int leagueId,
    int draftId, {
    String? draftType,
    int? rounds,
    int? pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
    List<String>? playerPool,
    DateTime? scheduledStart,
    bool clearScheduledStart = false,
  }) async {
    final body = <String, dynamic>{};
    if (draftType != null) body['draft_type'] = draftType;
    if (rounds != null) body['rounds'] = rounds;
    if (pickTimeSeconds != null) body['pick_time_seconds'] = pickTimeSeconds;
    if (auctionSettings != null) body['auction_settings'] = auctionSettings;
    if (playerPool != null) body['player_pool'] = playerPool;
    if (clearScheduledStart) {
      body['scheduled_start'] = null;
    } else if (scheduledStart != null) {
      body['scheduled_start'] = scheduledStart.toUtc().toIso8601String();
    }

    final response = await _apiClient.patch(
      '/leagues/$leagueId/drafts/$draftId/settings',
      body: body,
    );
    return Draft.fromJson(response as Map<String, dynamic>);
  }
}
