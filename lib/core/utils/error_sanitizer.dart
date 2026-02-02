import '../api/api_exceptions.dart';

/// Sanitizes error messages for safe display to users.
/// Strips technical details and provides user-friendly messages.
class ErrorSanitizer {
  ErrorSanitizer._();

  /// Converts any error to a user-friendly message string.
  /// Hides technical details that could expose internal implementation.
  static String sanitize(Object error) {
    // Handle our typed API exceptions - these already have user-safe messages
    if (error is ApiException) {
      return _sanitizeApiException(error);
    }

    // Handle string errors
    if (error is String) {
      return _sanitizeString(error);
    }

    // For all other exception types, return a generic message
    // to avoid leaking implementation details
    return 'An unexpected error occurred. Please try again.';
  }

  /// Sanitizes API exceptions
  static String _sanitizeApiException(ApiException error) {
    // Network errors
    if (error is NetworkException) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    // Server errors - don't expose internal details
    if (error is ServerException) {
      return 'Something went wrong on our end. Please try again later.';
    }

    // Auth errors
    if (error is UnauthorizedException) {
      return 'Your session has expired. Please sign in again.';
    }

    if (error is ForbiddenException) {
      return "You don't have permission to perform this action.";
    }

    // Not found - could be user error or stale data
    if (error is NotFoundException) {
      return "The requested item could not be found. It may have been removed.";
    }

    // Conflict - typically means duplicate or concurrent modification
    if (error is ConflictException) {
      // Preserve the message as it's usually user-relevant
      return error.message;
    }

    // Validation errors - these should have user-friendly messages from the server
    if (error is ValidationException) {
      return error.message;
    }

    // Default API exception - use the message if it looks safe
    return _sanitizeString(error.message);
  }

  /// Sanitizes a raw string error message
  static String _sanitizeString(String message) {
    final lower = message.toLowerCase();

    // Check for patterns that indicate internal/technical errors
    if (_containsTechnicalDetails(lower)) {
      return 'An error occurred. Please try again.';
    }

    // Check for HTTP-related errors
    if (lower.contains('socket') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('host lookup') ||
        lower.contains('dns')) {
      return 'Unable to connect to the server. Please check your internet connection.';
    }

    // Check for timeout errors
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'The request took too long. Please try again.';
    }

    // If the message looks reasonably safe, return it
    // But cap the length to avoid showing huge error dumps
    if (message.length > 200) {
      return 'An error occurred. Please try again.';
    }

    return message;
  }

  /// Checks if a message contains technical implementation details
  static bool _containsTechnicalDetails(String lower) {
    const technicalPatterns = [
      // Database errors
      'sql', 'postgres', 'mysql', 'sqlite', 'database', 'query',
      'constraint', 'foreign key', 'unique violation', 'relation',
      'column', 'table', 'schema',
      // Stack traces and code references
      'exception', 'error at', 'at line', 'stack trace', 'stacktrace',
      'at /src/', 'at ./src/', '.ts:', '.js:', '.dart:',
      // Internal paths
      '/node_modules/', '/backend/', '/src/modules/',
      // Memory/system errors
      'heap', 'memory', 'buffer', 'overflow', 'segmentation',
      // Node/runtime errors
      'cannot read property', 'undefined is not', 'null pointer',
      'type error', 'reference error', 'syntaxerror',
      // Generic code errors
      'unhandled', 'unexpected token', 'module not found',
    ];

    for (final pattern in technicalPatterns) {
      if (lower.contains(pattern)) {
        return true;
      }
    }

    return false;
  }
}

/// Extension method for easy error sanitization
extension ErrorSanitizerExtension on Object {
  /// Returns a sanitized, user-friendly error message
  String toUserMessage() => ErrorSanitizer.sanitize(this);
}
