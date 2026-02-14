import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';

/// Repository for commissioner admin tool operations.
///
/// Calls the `/leagues/:leagueId/commissioner-tools/` endpoints.
class CommissionerToolsRepository {
  final ApiClient _apiClient;

  CommissionerToolsRepository(this._apiClient);

  String _basePath(int leagueId) =>
      '/leagues/$leagueId/commissioner-tools';

  // ============================================================
  // Draft Admin
  // ============================================================

  /// Adjust chess clock time for a roster in a draft.
  Future<Map<String, dynamic>> adjustChessClock(
    int leagueId,
    int draftId,
    int rosterId,
    int deltaSeconds, {
    String? reason,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{'delta_seconds': deltaSeconds};
    if (reason != null) body['reason'] = reason;

    final result = await _apiClient.patch(
      '${_basePath(leagueId)}/drafts/$draftId/chess-clocks/$rosterId',
      body: body,
      idempotencyKey: idempotencyKey,
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Force autopick for the current pick in a draft.
  Future<void> forceAutopick(
    int leagueId,
    int draftId, {
    String? idempotencyKey,
  }) async {
    await _apiClient.post(
      '${_basePath(leagueId)}/drafts/$draftId/force-autopick',
      idempotencyKey: idempotencyKey,
    );
  }

  /// Undo the last pick in a draft.
  Future<void> undoLastPick(
    int leagueId,
    int draftId, {
    String? idempotencyKey,
  }) async {
    await _apiClient.post(
      '${_basePath(leagueId)}/drafts/$draftId/undo-last-pick',
      idempotencyKey: idempotencyKey,
    );
  }

  // ============================================================
  // Waiver Admin
  // ============================================================

  /// Reset waiver priority to default roster order.
  Future<void> resetWaiverPriority(
    int leagueId, {
    String? idempotencyKey,
  }) async {
    await _apiClient.post(
      '${_basePath(leagueId)}/waivers/reset-priority',
      idempotencyKey: idempotencyKey,
    );
  }

  /// Set a specific waiver priority for a roster.
  Future<void> setWaiverPriority(
    int leagueId,
    int rosterId,
    int priority, {
    String? idempotencyKey,
  }) async {
    await _apiClient.patch(
      '${_basePath(leagueId)}/waivers/priority/$rosterId',
      body: {'priority': priority},
      idempotencyKey: idempotencyKey,
    );
  }

  /// Set FAAB budget for a roster.
  Future<void> setFaabBudget(
    int leagueId,
    int rosterId,
    num setTo, {
    String? idempotencyKey,
  }) async {
    await _apiClient.patch(
      '${_basePath(leagueId)}/waivers/faab/$rosterId',
      body: {'set_to': setTo},
      idempotencyKey: idempotencyKey,
    );
  }

  // ============================================================
  // Trade Admin
  // ============================================================

  /// Commissioner cancel a trade.
  Future<void> adminCancelTrade(
    int leagueId,
    int tradeId, {
    String? reason,
    String? idempotencyKey,
  }) async {
    final body = <String, dynamic>{};
    if (reason != null) body['reason'] = reason;

    await _apiClient.post(
      '${_basePath(leagueId)}/trades/$tradeId/cancel',
      body: body.isNotEmpty ? body : null,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Lock or unlock trading for the league.
  Future<void> updateTradingLocked(
    int leagueId,
    bool tradingLocked, {
    String? idempotencyKey,
  }) async {
    await _apiClient.patch(
      '${_basePath(leagueId)}/settings',
      body: {'trading_locked': tradingLocked},
      idempotencyKey: idempotencyKey,
    );
  }

  // ============================================================
  // Dues Admin
  // ============================================================

  /// Export dues as CSV string.
  ///
  /// Uses direct HTTP because the endpoint returns text/csv, not JSON.
  Future<String> exportDuesCsv(int leagueId) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: AppConfig.accessTokenKey);

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}${_basePath(leagueId)}/dues/export.csv',
    );

    final response = await http
        .get(url, headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'text/csv',
        })
        .timeout(ApiClient.requestTimeout);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body;
    }

    // Try to parse error from JSON body
    try {
      final body = jsonDecode(response.body);
      throw HttpException(body['message'] ?? 'Failed to export CSV');
    } catch (e) {
      if (e is HttpException) rethrow;
      throw HttpException('Failed to export CSV (${response.statusCode})');
    }
  }
}

/// Provider for CommissionerToolsRepository
final commissionerToolsRepositoryProvider =
    Provider<CommissionerToolsRepository>((ref) {
  return CommissionerToolsRepository(ref.watch(apiClientProvider));
});
