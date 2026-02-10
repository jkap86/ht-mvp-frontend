import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/dues.dart';

final duesRepositoryProvider = Provider<DuesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DuesRepository(apiClient);
});

class DuesRepository {
  final ApiClient _apiClient;

  DuesRepository(this._apiClient);

  /// Get dues overview for a league (config + payments + summary)
  Future<DuesOverview> getDuesOverview(int leagueId) async {
    final response = await _apiClient.get('/leagues/$leagueId/dues');
    return DuesOverview.fromJson(response);
  }

  /// Create or update dues configuration
  Future<LeagueDues> upsertDuesConfig(
    int leagueId, {
    required double buyInAmount,
    Map<String, num>? payoutStructure,
    String? currency,
    String? notes,
    String? idempotencyKey,
  }) async {
    final response = await _apiClient.put('/leagues/$leagueId/dues', body: {
      'buy_in_amount': buyInAmount,
      if (payoutStructure != null) 'payout_structure': payoutStructure,
      if (currency != null) 'currency': currency,
      if (notes != null) 'notes': notes,
    }, idempotencyKey: idempotencyKey);
    return LeagueDues.fromJson(response);
  }

  /// Delete dues configuration
  Future<void> deleteDuesConfig(int leagueId, {String? idempotencyKey}) async {
    await _apiClient.delete('/leagues/$leagueId/dues', idempotencyKey: idempotencyKey);
  }

  /// Mark payment status for a roster
  Future<void> markPaymentStatus(
    int leagueId,
    int rosterId, {
    required bool isPaid,
    String? notes,
    String? idempotencyKey,
  }) async {
    await _apiClient.patch('/leagues/$leagueId/dues/payments/$rosterId', body: {
      'is_paid': isPaid,
      if (notes != null) 'notes': notes,
    }, idempotencyKey: idempotencyKey);
  }
}
