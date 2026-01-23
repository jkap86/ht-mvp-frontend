class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Forbidden']) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Not found']) : super(message, 404);
}

class ConflictException extends ApiException {
  ConflictException([String message = 'Conflict']) : super(message, 409);
}

class ValidationException extends ApiException {
  ValidationException([String message = 'Validation error']) : super(message, 400);
}

class ServerException extends ApiException {
  ServerException([String message = 'Server error']) : super(message, 500);
}

class NetworkException extends ApiException {
  NetworkException([super.message = 'Network error']);
}
