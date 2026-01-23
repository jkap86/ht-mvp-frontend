import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../domain/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<AuthResult> register(String username, String email, String password) async {
    final response = await _apiClient.post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
    }, auth: false);

    // Null safety checks
    final userData = response['user'];
    if (userData == null) {
      throw ApiException('Invalid response: missing user data', 500);
    }

    final user = User.fromJson(userData);
    final accessToken = response['token'] as String?;
    final refreshToken = response['refreshToken'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw ApiException('Invalid response: missing tokens', 500);
    }

    await _apiClient.setTokens(accessToken, refreshToken);

    return AuthResult(user: user, accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<AuthResult> login(String username, String password) async {
    final response = await _apiClient.post('/auth/login', body: {
      'username': username,
      'password': password,
    }, auth: false);

    // Null safety checks
    final userData = response['user'];
    if (userData == null) {
      throw ApiException('Invalid response: missing user data', 500);
    }

    final user = User.fromJson(userData);
    final accessToken = response['token'] as String?;
    final refreshToken = response['refreshToken'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw ApiException('Invalid response: missing tokens', 500);
    }

    await _apiClient.setTokens(accessToken, refreshToken);

    return AuthResult(user: user, accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<User> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    final userData = response['user'];
    if (userData == null) {
      throw ApiException('Invalid response: missing user data', 500);
    }
    return User.fromJson(userData);
  }

  /// Logout by clearing tokens locally.
  /// Note: Backend doesn't have a logout endpoint yet (stateless JWT).
  /// Future: Add token revocation when needed.
  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  /// Attempts to refresh tokens using the stored refresh token.
  /// Uses raw HTTP to avoid triggering the retry logic in ApiClient.
  /// Returns true if successful, false otherwise.
  Future<bool> refreshTokens() async {
    final storage = const FlutterSecureStorage();
    try {
      final refreshToken = await storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['token'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;

        if (newAccessToken != null && newRefreshToken != null) {
          await _apiClient.setTokens(newAccessToken, newRefreshToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

class AuthResult {
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}
