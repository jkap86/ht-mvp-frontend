import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/services/snack_bar_service.dart';
import '../../../core/socket/socket_service.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';
import '../../notifications/data/notifications_repository.dart';

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
  final SnackBarService _snackBarService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Guard against concurrent session-expired calls from multiple 401 responses
  bool _isHandlingSessionExpiry = false;

  AuthNotifier(this._authRepository, this._socketService, this._apiClient, this._snackBarService) : super(AuthState()) {
    _checkAuthStatus();
  }

  /// Sanitizes error messages to prevent leaking sensitive information.
  /// Maps technical/internal errors to user-friendly messages.
  String _sanitizeAuthError(Object error) {
    // Handle typed API exceptions directly for precise error mapping
    if (error is UnauthorizedException) {
      return 'Invalid username or password';
    }
    if (error is ConflictException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('username')) {
        return 'That username is already taken';
      }
      if (msg.contains('email')) {
        return 'An account with that email already exists';
      }
      return 'An account with these details already exists';
    }
    if (error is ValidationException) {
      // Validation errors from the backend are already user-friendly
      return error.message;
    }
    if (error is NetworkException) {
      return 'Unable to connect to server. Please check your connection.';
    }
    if (error is ServerException) {
      return 'Something went wrong. Please try again later.';
    }

    // Fallback: check error message string for known patterns
    final message = error.toString().toLowerCase();

    // Registration errors
    if (message.contains('already exists') ||
        message.contains('already registered') ||
        message.contains('already taken') ||
        message.contains('already in use')) {
      return 'An account with these details already exists';
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
  /// Guarded against reentrancy — multiple concurrent 401s will only
  /// trigger one logout cycle.
  void _handleSessionExpired() {
    if (_isHandlingSessionExpiry) return;
    _isHandlingSessionExpiry = true;

    final userId = state.user?.id;
    _clearTokenRefreshCallback();
    _socketService.disconnect();
    if (userId != null) {
      NotificationsRepository.clearForUser(userId);
    }

    // Clear tokens and update state. We fire-and-forget the async token
    // clearing — the state change below immediately triggers the router
    // redirect to /login, and the token deletion will complete in the
    // background. This is safe because _clearTokenRefreshCallback() above
    // already removed the ApiClient callbacks, so no new authenticated
    // requests will be attempted with the stale token.
    _authRepository.logout();

    state = AuthState(sessionExpired: true);
    _isHandlingSessionExpiry = false;

    // Show a snackbar for immediate user feedback (visible during navigation)
    _snackBarService.showWarning('Session expired. Please sign in again.');
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
    final userId = state.user?.id;
    state = state.copyWith(isLoading: true);
    try {
      _clearTokenRefreshCallback();
      _socketService.disconnect();
      if (userId != null) {
        await NotificationsRepository.clearForUser(userId);
      }
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
  final snackBarService = ref.watch(snackBarServiceProvider);
  return AuthNotifier(authRepository, socketService, apiClient, snackBarService);
});
