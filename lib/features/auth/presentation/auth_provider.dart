import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/socket/socket_service.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool sessionExpired;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.sessionExpired = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool? sessionExpired,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SocketService _socketService;
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._authRepository, this._socketService, this._apiClient) : super(AuthState()) {
    _checkAuthStatus();
  }

  /// Sanitizes error messages to prevent leaking sensitive information.
  /// Maps technical/internal errors to user-friendly messages.
  String _sanitizeAuthError(Object error) {
    final message = error.toString().toLowerCase();

    // Registration errors
    if (message.contains('already exists') || message.contains('already registered')) {
      return 'An account with this email or username already exists';
    }
    if (message.contains('email') && message.contains('invalid')) {
      return 'Please enter a valid email address';
    }

    // Login errors
    if (message.contains('invalid credentials') ||
        message.contains('incorrect password') ||
        message.contains('user not found')) {
      return 'Invalid username or password';
    }

    // Network errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Unable to connect to server. Please check your connection.';
    }

    // Generic fallback - don't expose raw error details
    return 'An error occurred. Please try again.';
  }

  /// Sets up the token refresh callbacks on ApiClient
  void _setupTokenRefreshCallback() {
    _apiClient.onTokenRefresh = () => _authRepository.refreshTokens();
    // Reconnect socket with fresh token after refresh succeeds
    _apiClient.onTokenRefreshed = () => _socketService.reconnect();
    // Handle session expiry when refresh fails
    _apiClient.onUnauthorized = _handleSessionExpired;
  }

  /// Clears the token refresh callbacks
  void _clearTokenRefreshCallback() {
    _apiClient.onTokenRefresh = null;
    _apiClient.onTokenRefreshed = null;
    _apiClient.onUnauthorized = null;
  }

  /// Handles session expiry when token refresh fails.
  /// Clears auth state so the router redirects to login.
  void _handleSessionExpired() {
    _clearTokenRefreshCallback();
    _socketService.disconnect();
    _authRepository.logout();
    state = AuthState(sessionExpired: true);
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: AppConfig.accessTokenKey);
      if (token != null) {
        _setupTokenRefreshCallback();
        final user = await _authRepository.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false);
        await _socketService.connect();
      } else {
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (e) {
      _clearTokenRefreshCallback();
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.register(username, email, password);
      _setupTokenRefreshCallback();
      state = state.copyWith(user: result.user, isLoading: false);
      await _socketService.connect();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeAuthError(e));
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.login(username, password);
      _setupTokenRefreshCallback();
      state = state.copyWith(user: result.user, isLoading: false);
      await _socketService.connect();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _sanitizeAuthError(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      _clearTokenRefreshCallback();
      _socketService.disconnect();
      await _authRepository.logout();
    } finally {
      state = AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _clearTokenRefreshCallback();
    super.dispose();
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(authRepository, socketService, apiClient);
});
