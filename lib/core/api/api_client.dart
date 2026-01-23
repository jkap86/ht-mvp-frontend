import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import 'api_exceptions.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  final String baseUrl = AppConfig.apiBaseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

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

  Future<Map<String, String>> _getHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await _getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool auth = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(auth: auth),
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } on UnauthorizedException {
      // Attempt token refresh and retry once
      if (auth && await _attemptTokenRefresh()) {
        final response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(auth: auth),
        ).timeout(requestTimeout);
        return _handleResponse(response);
      }
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Failed to connect to server');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool auth = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } on UnauthorizedException {
      if (auth && await _attemptTokenRefresh()) {
        final response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(auth: auth),
          body: body != null ? jsonEncode(body) : null,
        ).timeout(requestTimeout);
        return _handleResponse(response);
      }
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Failed to connect to server');
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, bool auth = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } on UnauthorizedException {
      if (auth && await _attemptTokenRefresh()) {
        final response = await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(auth: auth),
          body: body != null ? jsonEncode(body) : null,
        ).timeout(requestTimeout);
        return _handleResponse(response);
      }
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Failed to connect to server');
    }
  }

  Future<dynamic> delete(String endpoint, {bool auth = true}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(auth: auth),
      ).timeout(requestTimeout);
      return _handleResponse(response);
    } on UnauthorizedException {
      if (auth && await _attemptTokenRefresh()) {
        final response = await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(auth: auth),
        ).timeout(requestTimeout);
        return _handleResponse(response);
      }
      rethrow;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException('Failed to connect to server');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Handle both old format {error: "msg"} and new format {error: {code, message}}
    final errorField = body?['error'];
    final message = (errorField is Map)
        ? errorField['message'] ?? 'An error occurred'
        : errorField ?? body?['message'] ?? 'An error occurred';

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 409:
        throw ConflictException(message);
      default:
        throw ServerException(message);
    }
  }
}
