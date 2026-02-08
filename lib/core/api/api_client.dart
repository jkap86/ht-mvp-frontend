import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_config.dart';
import 'api_exceptions.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  final String baseUrl = AppConfig.apiBaseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Uuid _uuid = const Uuid();

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Maximum number of retry attempts for transient failures
  static const int maxRetries = 3;

  /// Base delay for exponential backoff (in milliseconds)
  static const int baseDelayMs = 500;

  /// Generate a new idempotency key for requests that need safe retries
  String generateIdempotencyKey() => _uuid.v4();

  /// Callback for token refresh. Set this after login to enable automatic
  /// token refresh on 401 responses. Returns true if refresh succeeded.
  Future<bool> Function()? onTokenRefresh;

  /// Callback for socket reconnection after token refresh.
  /// Set this to ensure socket auth stays in sync with new tokens.
  void Function()? onTokenRefreshed;

  /// Shared future for token refresh - allows multiple concurrent requests
  /// to await the same refresh attempt instead of triggering duplicates.
  Future<bool>? _refreshFuture;

  /// Attempts to refresh the token. Returns true if successful.
  /// Multiple concurrent callers will await the same refresh attempt.
  Future<bool> _attemptTokenRefresh() async {
    if (onTokenRefresh == null) return false;

    // If refresh is already in progress, await the existing future
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }

    // Start new refresh and store the future so others can await it
    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh() async {
    final success = await onTokenRefresh!();
    if (success && onTokenRefreshed != null) {
      // Notify that tokens were refreshed (e.g., to reconnect socket)
      onTokenRefreshed!();
    }
    return success;
  }

  Future<String?> _getAccessToken() async {
    return await _storage.read(key: AppConfig.accessTokenKey);
  }

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConfig.accessTokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
  }

  Future<Map<String, String>> _getHeaders({
    bool auth = true,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await _getAccessToken();
      if (kDebugMode) {
        debugPrint('API: Token present: ${token != null}, length: ${token?.length ?? 0}');
      }
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (idempotencyKey != null) {
      headers['x-idempotency-key'] = idempotencyKey;
    }

    return headers;
  }

  /// Checks if an error is a transient failure that should be retried
  bool _isRetryableError(Object error) {
    // Network-related errors
    if (error is SocketException ||
        error is TimeoutException ||
        error is NetworkException) {
      return true;
    }

    // Server errors (5xx) are often transient
    if (error is ServerException) {
      return true;
    }

    return false;
  }

  /// Calculates the delay for exponential backoff with jitter
  Duration _getRetryDelay(int attempt) {
    // Exponential backoff: baseDelay * 2^attempt
    final exponentialDelay = baseDelayMs * (1 << attempt);
    // Add jitter (0-50% of the delay) to prevent thundering herd
    final jitter = (exponentialDelay * 0.5 * (DateTime.now().millisecond / 1000)).toInt();
    return Duration(milliseconds: exponentialDelay + jitter);
  }

  /// Executes an HTTP request with automatic token refresh on 401
  /// and exponential backoff retry for transient failures.
  /// [executeRequest] is a function that performs the actual HTTP call.
  /// [auth] indicates whether to attempt token refresh on 401.
  /// [idempotencyKey] is passed to headers for safe retries on mutating requests.
  Future<dynamic> _executeWithRetry({
    required Future<http.Response> Function(Map<String, String> headers) executeRequest,
    required bool auth,
    String? idempotencyKey,
  }) async {
    Object? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final headers = await _getHeaders(auth: auth, idempotencyKey: idempotencyKey);
        final response = await executeRequest(headers).timeout(requestTimeout);
        return _handleResponse(response);
      } on UnauthorizedException {
        // Attempt token refresh and retry once (not part of exponential backoff)
        if (auth && await _attemptTokenRefresh()) {
          final headers = await _getHeaders(auth: auth, idempotencyKey: idempotencyKey);
          final response = await executeRequest(headers).timeout(requestTimeout);
          return _handleResponse(response);
        }
        rethrow;
      } catch (e) {
        // Convert raw network errors to our exception type
        final error = e is ApiException ? e : NetworkException('Failed to connect to server');
        lastError = error;

        // Check if we should retry
        if (attempt < maxRetries && _isRetryableError(error)) {
          await Future.delayed(_getRetryDelay(attempt));
          continue;
        }

        // No more retries - throw the error
        if (error is ApiException) {
          throw error;
        }
        throw NetworkException('Failed to connect to server');
      }
    }

    // Should not reach here, but throw last error just in case
    throw lastError ?? NetworkException('Failed to connect to server');
  }

  Future<dynamic> get(String endpoint, {bool auth = true}) async {
    return _executeWithRetry(
      auth: auth,
      executeRequest: (headers) => http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ),
    );
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    bool auth = true,
    String? idempotencyKey,
  }) async {
    return _executeWithRetry(
      auth: auth,
      idempotencyKey: idempotencyKey,
      executeRequest: (headers) => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool auth = true}) async {
    return _executeWithRetry(
      auth: auth,
      executeRequest: (headers) => http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> delete(String endpoint, {dynamic body, bool auth = true}) async {
    return _executeWithRetry(
      auth: auth,
      executeRequest: (headers) => http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  Future<dynamic> patch(String endpoint, {dynamic body, bool auth = true}) async {
    return _executeWithRetry(
      auth: auth,
      executeRequest: (headers) => http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Handle both old format {error: "msg"} and new format {error: {code, message}}
    final errorField = body?['error'];
    String message;
    String? errorCode;

    if (errorField is Map) {
      message = errorField['message'] as String? ?? 'An error occurred';
      errorCode = errorField['code'] as String?;
    } else {
      message = errorField as String? ?? body?['message'] as String? ?? 'An error occurred';
      errorCode = null;
    }

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message, errorCode);
      case 401:
        throw UnauthorizedException(message, errorCode);
      case 403:
        throw ForbiddenException(message, errorCode);
      case 404:
        throw NotFoundException(message, errorCode);
      case 409:
        throw ConflictException(message, errorCode);
      default:
        throw ServerException(message, errorCode);
    }
  }
}
