import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/waiver_claim.dart';
import '../domain/waiver_priority.dart';
import '../domain/faab_budget.dart';

final waiverRepositoryProvider = Provider<WaiverRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WaiverRepository(apiClient);
});

/// Repository for waiver-related API calls
class WaiverRepository {
  final ApiClient _apiClient;

  WaiverRepository(this._apiClient);

  /// Submit a waiver claim
  Future<WaiverClaim> submitClaim({
    required int leagueId,
    required int playerId,
    int? dropPlayerId,
    int bidAmount = 0,
  }) async {
    final response = await _apiClient.post(
      '/leagues/$leagueId/waivers/claims',
      body: {
        'player_id': playerId,
        if (dropPlayerId != null) 'drop_player_id': dropPlayerId,
        'bid_amount': bidAmount,
      },
    );
    return WaiverClaim.fromJson(response);
  }

  /// Get user's waiver claims
  Future<List<WaiverClaim>> getClaims(
    int leagueId, {
    String? status,
    int? rosterId,
    int? week,
    int limit = 50,
    int offset = 0,
  }) async {
    String endpoint = '/leagues/$leagueId/waivers/claims?limit=$limit&offset=$offset';
    if (status != null) {
      endpoint += '&status=$status';
    }
    if (rosterId != null) {
      endpoint += '&roster_id=$rosterId';
    }
    if (week != null) {
      endpoint += '&week=$week';
    }
    final response = await _apiClient.get(endpoint);
    final claimsList =
        (response['claims'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return claimsList.map((json) => WaiverClaim.fromJson(json)).toList();
  }

  /// Update a waiver claim (bid amount or drop player)
  Future<WaiverClaim> updateClaim(
    int leagueId,
    int claimId, {
    int? dropPlayerId,
    int? bidAmount,
  }) async {
    final response = await _apiClient.put(
      '/leagues/$leagueId/waivers/claims/$claimId',
      body: {
        if (dropPlayerId != null) 'drop_player_id': dropPlayerId,
        if (bidAmount != null) 'bid_amount': bidAmount,
      },
    );
    return WaiverClaim.fromJson(response);
  }

  /// Cancel a waiver claim
  Future<void> cancelClaim(int leagueId, int claimId) async {
    await _apiClient.delete('/leagues/$leagueId/waivers/claims/$claimId');
  }

  /// Reorder waiver claims
  /// Takes a list of claim IDs in the desired order
  Future<List<WaiverClaim>> reorderClaims(
    int leagueId,
    List<int> claimIds,
  ) async {
    final response = await _apiClient.patch(
      '/leagues/$leagueId/waivers/claims/reorder',
      body: {'claim_ids': claimIds},
    );
    final claimsList =
        (response['claims'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return claimsList.map((json) => WaiverClaim.fromJson(json)).toList();
  }

  /// Get waiver priority order
  Future<List<WaiverPriority>> getPriority(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/waivers/priority');
    final prioritiesList =
        (response['priorities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return prioritiesList.map((json) => WaiverPriority.fromJson(json)).toList();
  }

  /// Get FAAB budgets
  Future<List<FaabBudget>> getFaabBudgets(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/waivers/faab');
    final budgetsList =
        (response['budgets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return budgetsList.map((json) => FaabBudget.fromJson(json)).toList();
  }

  /// Get players on waiver wire
  Future<List<Map<String, dynamic>>> getWaiverWire(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/waivers/wire');
    final playersList =
        (response['players'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return playersList;
  }

  /// Initialize waivers for a league (commissioner only)
  Future<void> initializeWaivers(int leagueId, {int? faabBudget}) async {
    await _apiClient.post(
      '/leagues/$leagueId/waivers/initialize',
      body: {
        if (faabBudget != null) 'faab_budget': faabBudget,
      },
    );
  }

  /// Manually process waivers (commissioner only)
  Future<Map<String, dynamic>> processWaivers(int leagueId) async {
    final response = await _apiClient.post('/leagues/$leagueId/waivers/process');
    return {
      'processed': response['processed'] as int? ?? 0,
      'successful': response['successful'] as int? ?? 0,
    };
  }
}
