import 'package:dio/dio.dart';

import '../../../../core/api/api_exceptions.dart';
import '../domain/auction_budget.dart';
import '../domain/auction_lot.dart';

class DraftAuctionApiClient {
  final Dio _dio;

  DraftAuctionApiClient(this._dio);

  /// GET /api/leagues/:leagueId/drafts/:draftId/auction/lots
  Future<List<AuctionLot>> getActiveLots(int leagueId, int draftId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/leagues/$leagueId/drafts/$draftId/auction/lots',
      );
      final lots = response.data?['lots'] as List<dynamic>? ?? [];
      return lots
          .map((json) => AuctionLot.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/leagues/:leagueId/drafts/:draftId/auction/lots/:lotId
  Future<AuctionLot> getLot(int leagueId, int draftId, int lotId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/leagues/$leagueId/drafts/$draftId/auction/lots/$lotId',
      );
      return AuctionLot.fromJson(response.data!);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// GET /api/leagues/:leagueId/drafts/:draftId/auction/budgets
  Future<List<AuctionBudget>> getBudgets(int leagueId, int draftId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/leagues/$leagueId/drafts/$draftId/auction/budgets',
      );
      final budgets = response.data?['budgets'] as List<dynamic>? ?? [];
      return budgets
          .map((json) => AuctionBudget.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/leagues/:leagueId/drafts/:draftId/actions
  /// with body { action: 'nominate', player_id }
  Future<AuctionLot> nominate(int leagueId, int draftId, int playerId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/leagues/$leagueId/drafts/$draftId/actions',
        data: {
          'action': 'nominate',
          'player_id': playerId,
        },
      );
      final lot = response.data!['lot'] as Map<String, dynamic>;
      return AuctionLot.fromJson(lot);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST /api/leagues/:leagueId/drafts/:draftId/actions
  /// with body { action: 'set_max_bid', lot_id, max_bid }
  Future<AuctionLot> setMaxBid(
    int leagueId,
    int draftId,
    int lotId,
    int maxBid,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/leagues/$leagueId/drafts/$draftId/actions',
        data: {
          'action': 'set_max_bid',
          'lot_id': lotId,
          'max_bid': maxBid,
        },
      );
      final lot = response.data!['lot'] as Map<String, dynamic>;
      return AuctionLot.fromJson(lot);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Converts DioException to the appropriate ApiException
  ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Failed to connect to server');
    }

    final response = e.response;
    if (response == null) {
      return NetworkException('Failed to connect to server');
    }

    final data = response.data;
    final errorField = data is Map ? data['error'] : null;
    final message = (errorField is Map)
        ? errorField['message'] ?? 'An error occurred'
        : errorField ?? (data is Map ? data['message'] : null) ?? 'An error occurred';

    switch (response.statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      default:
        return ServerException(message);
    }
  }
}
