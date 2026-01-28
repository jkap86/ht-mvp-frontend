import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/draft_pick_asset.dart';

final draftPickAssetRepositoryProvider = Provider<DraftPickAssetRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DraftPickAssetRepository(apiClient);
});

class DraftPickAssetRepository {
  final ApiClient _apiClient;

  DraftPickAssetRepository(this._apiClient);

  /// Get all draft pick assets for a league (all seasons)
  Future<List<DraftPickAsset>> getLeaguePickAssets(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/pick-assets');
    final assets = (response as List?) ?? [];
    return assets
        .map((json) => DraftPickAsset.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get draft pick assets for a specific season in a league
  Future<List<DraftPickAsset>> getSeasonPickAssets(int leagueId, int season) async {
    final response = await _apiClient.get('/leagues/$leagueId/pick-assets/$season');
    final assets = (response as List?) ?? [];
    return assets
        .map((json) => DraftPickAsset.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get draft pick assets owned by a specific roster
  Future<List<DraftPickAsset>> getRosterPickAssets(int rosterId) async {
    final response = await _apiClient.get('/rosters/$rosterId/pick-assets');
    final assets = (response as List?) ?? [];
    return assets
        .map((json) => DraftPickAsset.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
