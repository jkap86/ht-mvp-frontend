/// Error codes matching backend ErrorCode enum.
/// Used to distinguish between recoverable and terminal errors.
class ErrorCode {
  // Generic errors
  static const unknownError = 'UNKNOWN_ERROR';
  static const validationError = 'VALIDATION_ERROR';
  static const invalidCredentials = 'INVALID_CREDENTIALS';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';
  static const conflict = 'CONFLICT';
  static const databaseError = 'DATABASE_ERROR';
  static const internalError = 'INTERNAL_ERROR';

  // Draft-specific errors (recoverable = can retry or wait)
  static const draftNotFound = 'DRAFT_NOT_FOUND';
  static const draftNotStarted = 'DRAFT_NOT_STARTED';
  static const draftAlreadyCompleted = 'DRAFT_ALREADY_COMPLETED';
  static const draftPaused = 'DRAFT_PAUSED';
  static const notYourTurn = 'NOT_YOUR_TURN';
  static const playerAlreadyDrafted = 'PLAYER_ALREADY_DRAFTED';
  static const pickAlreadyMade = 'PICK_ALREADY_MADE';
  static const invalidPick = 'INVALID_PICK';

  // Auction-specific errors
  static const auctionLotNotFound = 'AUCTION_LOT_NOT_FOUND';
  static const auctionLotExpired = 'AUCTION_LOT_EXPIRED';
  static const auctionBidTooLow = 'AUCTION_BID_TOO_LOW';
  static const auctionInsufficientBudget = 'AUCTION_INSUFFICIENT_BUDGET';
  static const auctionNotYourNomination = 'AUCTION_NOT_YOUR_NOMINATION';
  static const auctionGlobalCapReached = 'AUCTION_GLOBAL_CAP_REACHED';
  static const auctionDailyLimitReached = 'AUCTION_DAILY_LIMIT_REACHED';

  // Trade-specific errors
  static const tradeNotFound = 'TRADE_NOT_FOUND';
  static const tradeAlreadyProcessed = 'TRADE_ALREADY_PROCESSED';
  static const tradeInvalidAssets = 'TRADE_INVALID_ASSETS';

  // Roster-specific errors
  static const rosterFull = 'ROSTER_FULL';
  static const playerNotOnRoster = 'PLAYER_NOT_ON_ROSTER';
  static const playerAlreadyOnRoster = 'PLAYER_ALREADY_ON_ROSTER';

  /// Check if error is recoverable (user can retry or wait for their turn)
  static bool isRecoverable(String? code) {
    return const {
      notYourTurn,
      pickAlreadyMade,
      playerAlreadyDrafted,
      auctionBidTooLow,
      auctionNotYourNomination,
      draftPaused,
    }.contains(code);
  }

  /// Check if error indicates stale state (should refresh)
  static bool requiresRefresh(String? code) {
    return const {
      pickAlreadyMade,
      playerAlreadyDrafted,
      auctionLotExpired,
      draftAlreadyCompleted,
    }.contains(code);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, [this.statusCode, this.errorCode]);

  /// Whether this error is recoverable (user can retry or wait)
  bool get isRecoverable => ErrorCode.isRecoverable(errorCode);

  /// Whether this error indicates stale state requiring a refresh
  bool get requiresRefresh => ErrorCode.requiresRefresh(errorCode);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized', String? errorCode])
      : super(message, 401, errorCode ?? ErrorCode.invalidCredentials);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Forbidden', String? errorCode])
      : super(message, 403, errorCode ?? ErrorCode.forbidden);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Not found', String? errorCode])
      : super(message, 404, errorCode ?? ErrorCode.notFound);
}

class ConflictException extends ApiException {
  ConflictException([String message = 'Conflict', String? errorCode])
      : super(message, 409, errorCode ?? ErrorCode.conflict);
}

class ValidationException extends ApiException {
  ValidationException([String message = 'Validation error', String? errorCode])
      : super(message, 400, errorCode ?? ErrorCode.validationError);
}

class ServerException extends ApiException {
  ServerException([String message = 'Server error', String? errorCode])
      : super(message, 500, errorCode ?? ErrorCode.internalError);
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'Network error']) : super(null, null);
}
