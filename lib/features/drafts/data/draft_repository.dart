import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../leagues/domain/league.dart';
import '../domain/auction_budget.dart';
import '../domain/auction_lot.dart';
import '../domain/auction_state.dart';
import '../domain/bid_history_entry.dart';
import '../domain/derby_state.dart';
import '../domain/draft_order_entry.dart';
import '../domain/draft_pick_asset.dart';

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

  Future<Draft> startDraft(int leagueId, int draftId, {String? idempotencyKey}) async {
    final response =
        await _apiClient.post('/leagues/$leagueId/drafts/$draftId/start', idempotencyKey: idempotencyKey);
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
      int leagueId, int draftId, int playerId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/pick',
      body: {'player_id': playerId},
      idempotencyKey: idempotencyKey ?? _apiClient.generateIdempotencyKey(),
    );
    final pickData = response as Map<String, dynamic>?;
    if (pickData == null) throw Exception('Invalid response: missing pick data');
    return pickData;
  }

  Future<List<DraftOrderEntry>> randomizeDraftOrder(int leagueId, int draftId, {String? idempotencyKey}) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts/$draftId/randomize', idempotencyKey: idempotencyKey);
    final order = (response as List?) ?? [];
    return order
        .map((json) => DraftOrderEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DraftOrderEntry>> confirmDraftOrder(int leagueId, int draftId, {String? idempotencyKey}) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts/$draftId/order/confirm', idempotencyKey: idempotencyKey);
    final order = (response as List?) ?? [];
    return order
        .map((json) => DraftOrderEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DraftOrderEntry>> setOrderFromPickOwnership(int leagueId, int draftId, {String? idempotencyKey}) async {
    final response = await _apiClient.post('/leagues/$leagueId/drafts/$draftId/order/from-pick-ownership', idempotencyKey: idempotencyKey);
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
      int leagueId, int draftId, int playerId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'player_id': playerId},
      idempotencyKey: idempotencyKey,
    );
    final queueData = response as Map<String, dynamic>?;
    if (queueData == null) throw Exception('Invalid response: missing queue data');
    return queueData;
  }

  Future<Map<String, dynamic>> addPickAssetToQueue(
      int leagueId, int draftId, int pickAssetId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'pick_asset_id': pickAssetId},
      idempotencyKey: idempotencyKey,
    );
    final queueData = response as Map<String, dynamic>?;
    if (queueData == null) throw Exception('Invalid response: missing queue data');
    return queueData;
  }

  Future<void> removeFromQueue(int leagueId, int draftId, int playerId, {String? idempotencyKey}) async {
    await _apiClient.delete('/leagues/$leagueId/drafts/$draftId/queue/$playerId', idempotencyKey: idempotencyKey);
  }

  Future<void> removePickAssetFromQueue(int leagueId, int draftId, int pickAssetId, {String? idempotencyKey}) async {
    await _apiClient.delete('/leagues/$leagueId/drafts/$draftId/queue/pick-asset/$pickAssetId', idempotencyKey: idempotencyKey);
  }

  Future<List<Map<String, dynamic>>> reorderQueue(
      int leagueId, int draftId, List<int> playerIds, {String? idempotencyKey}) async {
    final response = await _apiClient.put(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'player_ids': playerIds},
      idempotencyKey: idempotencyKey,
    );
    final reordered = (response as List?) ?? [];
    // Safe cast: filter out any non-Map elements to prevent runtime crashes
    return reordered.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> reorderQueueByEntryIds(
      int leagueId, int draftId, List<int> entryIds, {String? idempotencyKey}) async {
    final response = await _apiClient.put(
      '/leagues/$leagueId/drafts/$draftId/queue',
      body: {'queue_entry_ids': entryIds},
      idempotencyKey: idempotencyKey,
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

  Future<AuctionLot> nominate(int leagueId, int draftId, int playerId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {'action': 'nominate', 'playerId': playerId},
      idempotencyKey: idempotencyKey ?? _apiClient.generateIdempotencyKey(),
    );
    final lotData = response['data']?['lot'] ?? response['lot'];
    if (lotData == null) {
      throw Exception('Nominate response missing lot data');
    }
    return AuctionLot.fromJson(lotData as Map<String, dynamic>);
  }

  Future<AuctionLot> setMaxBid(
      int leagueId, int draftId, int lotId, int maxBid, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {'action': 'set_max_bid', 'lotId': lotId, 'maxBid': maxBid},
      idempotencyKey: idempotencyKey ?? _apiClient.generateIdempotencyKey(),
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
      int leagueId, int draftId, bool enabled, {String? idempotencyKey}) async {
    final response = await _apiClient.patch(
      '/leagues/$leagueId/drafts/$draftId/autodraft',
      body: {'enabled': enabled},
      idempotencyKey: idempotencyKey,
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
    bool? includeRookiePicks,
    int? rookiePicksSeason,
    int? rookiePicksRounds,
    bool? overnightPauseEnabled,
    String? overnightPauseStart,
    String? overnightPauseEnd,
    String? timerMode,
    int? chessClockTotalSeconds,
    int? chessClockMinPickSeconds,
    String? idempotencyKey,
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
    if (includeRookiePicks != null) body['include_rookie_picks'] = includeRookiePicks;
    if (rookiePicksSeason != null) body['rookie_picks_season'] = rookiePicksSeason;
    if (rookiePicksRounds != null) body['rookie_picks_rounds'] = rookiePicksRounds;
    if (overnightPauseEnabled != null) body['overnight_pause_enabled'] = overnightPauseEnabled;
    if (overnightPauseStart != null) {
      body['overnight_pause_start'] = overnightPauseStart.isEmpty ? null : overnightPauseStart;
    }
    if (overnightPauseEnd != null) {
      body['overnight_pause_end'] = overnightPauseEnd.isEmpty ? null : overnightPauseEnd;
    }
    if (timerMode != null) body['timer_mode'] = timerMode;
    if (chessClockTotalSeconds != null) body['chess_clock_total_seconds'] = chessClockTotalSeconds;
    if (chessClockMinPickSeconds != null) body['chess_clock_min_pick_seconds'] = chessClockMinPickSeconds;

    final response = await _apiClient.patch(
      '/leagues/$leagueId/drafts/$draftId/settings',
      body: body,
      idempotencyKey: idempotencyKey,
    );
    return Draft.fromJson(response as Map<String, dynamic>);
  }

  /// Get available pick assets for a vet draft with rookie picks enabled
  Future<List<DraftPickAsset>> getAvailablePickAssets(
    int leagueId,
    int draftId,
  ) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/drafts/$draftId/available-pick-assets',
    );
    final assets = (response['pick_assets'] as List?) ?? [];
    return assets
        .map((json) => DraftPickAsset.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Make a pick using a draft pick asset instead of a player
  Future<Map<String, dynamic>> makePickAssetSelection(
    int leagueId,
    int draftId,
    int pickAssetId, {
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {
        'action': 'pick',
        'draftPickAssetId': pickAssetId,
      },
      idempotencyKey: idempotencyKey ?? _apiClient.generateIdempotencyKey(),
    );
    final pickData = response['data']?['pick'] as Map<String, dynamic>?;
    if (pickData == null) throw Exception('Invalid response: missing pick data');
    return pickData;
  }

  // Pause/Resume methods (commissioner only)
  Future<void> pauseDraft(int leagueId, int draftId) async {
    await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {'action': 'pause'},
    );
  }

  Future<void> resumeDraft(int leagueId, int draftId) async {
    await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/actions',
      body: {'action': 'resume'},
    );
  }

  // Derby methods (draft order selection phase)

  /// Get current derby state
  Future<DerbyState> getDerbyState(int leagueId, int draftId) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/drafts/$draftId/derby/state',
    );
    return DerbyState.fromJson(response as Map<String, dynamic>);
  }

  /// Start derby phase (commissioner only)
  Future<DerbyState> startDerby(int leagueId, int draftId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/derby/start',
      idempotencyKey: idempotencyKey,
    );
    return DerbyState.fromJson(response as Map<String, dynamic>);
  }

  /// Pick a slot during derby phase
  Future<void> pickDerbySlot(int leagueId, int draftId, int slotNumber, {String? idempotencyKey}) async {
    await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/derby/pick-slot',
      body: {'slot_number': slotNumber},
      idempotencyKey: idempotencyKey ?? _apiClient.generateIdempotencyKey(),
    );
  }

  // Chess clock methods

  /// Get chess clock remaining times for all rosters in a draft
  Future<Map<int, double>> getChessClocks(int leagueId, int draftId) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/drafts/$draftId/chess-clocks',
    );
    final clocksRaw = (response as Map<String, dynamic>?)?['chess_clocks'];
    if (clocksRaw is! Map) return {};
    final result = <int, double>{};
    for (final entry in clocksRaw.entries) {
      final key = entry.key is int ? entry.key as int : int.tryParse(entry.key.toString());
      final value = entry.value is num ? (entry.value as num).toDouble() : double.tryParse(entry.value.toString());
      if (key != null && value != null) {
        result[key] = value;
      }
    }
    return result;
  }

  // Matchups draft methods

  /// Get available matchup options for the current picker
  Future<List<Map<String, dynamic>>> getAvailableMatchups(
      int leagueId, int draftId) async {
    final response = await _apiClient.get(
      '/leagues/$leagueId/drafts/$draftId/available-matchups',
    );
    final matchups = (response as List?) ?? [];
    return matchups.whereType<Map<String, dynamic>>().toList();
  }

  /// Pick a matchup (week/opponent combination)
  Future<Map<String, dynamic>> pickMatchup(
      int leagueId, int draftId, int week, int opponentRosterId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/drafts/$draftId/pick-matchup',
      body: {
        'week': week,
        'opponent_roster_id': opponentRosterId,
      },
      idempotencyKey: idempotencyKey ?? _apiClient.generateIdempotencyKey(),
    );
    final pickData = response as Map<String, dynamic>?;
    if (pickData == null) throw Exception('Invalid response: missing pick data');
    return pickData;
  }
}
