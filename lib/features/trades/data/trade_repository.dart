import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/trade.dart';

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TradeRepository(apiClient);
});

/// Repository for trade-related API calls
class TradeRepository {
  final ApiClient _apiClient;

  TradeRepository(this._apiClient);

  /// Get all trades for a league
  Future<List<Trade>> getTrades(
    int leagueId, {
    List<String>? statuses,
    int limit = 50,
    int offset = 0,
  }) async {
    String endpoint = '/leagues/$leagueId/trades?limit=$limit&offset=$offset';
    if (statuses != null && statuses.isNotEmpty) {
      endpoint += '&status=${statuses.join(',')}';
    }
    final response = await _apiClient.get(endpoint);
    final tradesList =
        (response['trades'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return tradesList.map((json) => Trade.fromJson(json)).toList();
  }

  /// Get a single trade by ID
  Future<Trade> getTrade(int leagueId, int tradeId) async {
    final response = await _apiClient.get('/leagues/$leagueId/trades/$tradeId');
    return Trade.fromJson(response);
  }

  /// Propose a new trade
  Future<Trade> proposeTrade({
    required int leagueId,
    required int recipientRosterId,
    required List<int> offeringPlayerIds,
    required List<int> requestingPlayerIds,
    String? message,
    bool notifyDm = true,
    String leagueChatMode = 'summary',
    List<int>? offeringPickAssetIds,
    List<int>? requestingPickAssetIds,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trades',
      body: {
        'recipient_roster_id': recipientRosterId,
        'offering_player_ids': offeringPlayerIds,
        'requesting_player_ids': requestingPlayerIds,
        if (message != null && message.isNotEmpty) 'message': message,
        'notify_dm': notifyDm,
        'league_chat_mode': leagueChatMode,
        if (offeringPickAssetIds != null && offeringPickAssetIds.isNotEmpty)
          'offering_pick_asset_ids': offeringPickAssetIds,
        if (requestingPickAssetIds != null && requestingPickAssetIds.isNotEmpty)
          'requesting_pick_asset_ids': requestingPickAssetIds,
      },
      idempotencyKey: idempotencyKey,
    );
    return Trade.fromJson(response);
  }

  /// Accept a trade
  Future<Trade> acceptTrade(int leagueId, int tradeId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trades/$tradeId/accept',
      idempotencyKey: idempotencyKey,
    );
    return Trade.fromJson(response);
  }

  /// Reject a trade
  Future<Trade> rejectTrade(int leagueId, int tradeId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trades/$tradeId/reject',
      idempotencyKey: idempotencyKey,
    );
    return Trade.fromJson(response);
  }

  /// Cancel a trade (proposer only)
  Future<Trade> cancelTrade(int leagueId, int tradeId, {String? idempotencyKey}) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trades/$tradeId/cancel',
      idempotencyKey: idempotencyKey,
    );
    return Trade.fromJson(response);
  }

  /// Counter a trade with a new offer
  Future<Trade> counterTrade({
    required int leagueId,
    required int tradeId,
    required List<int> offeringPlayerIds,
    required List<int> requestingPlayerIds,
    String? message,
    bool notifyDm = true,
    String leagueChatMode = 'summary',
    List<int>? offeringPickAssetIds,
    List<int>? requestingPickAssetIds,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trades/$tradeId/counter',
      body: {
        'offering_player_ids': offeringPlayerIds,
        'requesting_player_ids': requestingPlayerIds,
        if (message != null && message.isNotEmpty) 'message': message,
        'notify_dm': notifyDm,
        'league_chat_mode': leagueChatMode,
        if (offeringPickAssetIds != null && offeringPickAssetIds.isNotEmpty)
          'offering_pick_asset_ids': offeringPickAssetIds,
        if (requestingPickAssetIds != null && requestingPickAssetIds.isNotEmpty)
          'requesting_pick_asset_ids': requestingPickAssetIds,
      },
      idempotencyKey: idempotencyKey,
    );
    return Trade.fromJson(response);
  }

  /// Vote on a trade during review period
  Future<Map<String, dynamic>> voteTrade(
    int leagueId,
    int tradeId,
    String vote, {
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trades/$tradeId/vote',
      body: {
        'vote': vote, // 'approve' or 'veto'
      },
      idempotencyKey: idempotencyKey,
    );
    final tradeData = response['trade'] as Map<String, dynamic>?;
    if (tradeData == null) {
      throw Exception('Invalid response: missing trade data');
    }
    final voteCountMap =
        (response['vote_count'] as Map<String, dynamic>?) ?? {};
    return {
      'trade': Trade.fromJson(tradeData),
      'vote_count': {
        'approve': voteCountMap['approve'] as int? ?? 0,
        'veto': voteCountMap['veto'] as int? ?? 0,
      },
    };
  }
}
