import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/trade_block_item.dart';

final tradeBlockRepositoryProvider = Provider<TradeBlockRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TradeBlockRepository(apiClient);
});

class TradeBlockRepository {
  final ApiClient _apiClient;

  TradeBlockRepository(this._apiClient);

  Future<List<TradeBlockItem>> getItems(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/trade-block');
    final items =
        (response['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return items.map((json) => TradeBlockItem.fromJson(json)).toList();
  }

  Future<TradeBlockItem> addItem(
    int leagueId, {
    required int playerId,
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/trade-block',
      body: {
        'player_id': playerId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return TradeBlockItem.fromJson(response);
  }

  Future<void> removeItem(int leagueId, int playerId) async {
    await _apiClient.delete('/leagues/$leagueId/trade-block/$playerId');
  }
}
